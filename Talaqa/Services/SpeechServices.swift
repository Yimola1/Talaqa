import Foundation
import AVFoundation
import Speech
import Observation

// MARK: - Text to speech

final class SpeechService {
    static let shared = SpeechService()
    private let synth = AVSpeechSynthesizer()

    private func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        if let premium = voices.first(where: { $0.quality == .premium }) { return premium }
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) { return enhanced }
        return AVSpeechSynthesisVoice(language: language)
    }

    func speak(_ text: String, slow: Bool = false) {
        let defaults = UserDefaults.standard
        let accent = defaults.string(forKey: "accent") ?? "en-US"
        let baseRate = (defaults.object(forKey: "speechRate") as? Double) ?? 0.47

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestVoice(for: accent)
        utterance.rate = Float(slow ? baseRate * 0.7 : baseRate)
        utterance.pitchMultiplier = 1.0
        synth.speak(utterance)
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }
}

// MARK: - Speech recognition

@Observable
final class SpeechRecognizer {
    var transcript = ""
    var isRecording = false
    var errorMessage: String?

    @ObservationIgnored var onFinish: ((String) -> Void)?
    @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var finished = true

    static func requestPermissions() async -> Bool {
        let speechOK: Bool = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechOK else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    func toggle() {
        if isRecording { stop() } else { start() }
    }

    func start() {
        guard !isRecording else { return }
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "خدمة التعرّف على الكلام غير متاحة الآن. تأكّد من اتصالك بالإنترنت."
            return
        }
        SpeechService.shared.stop()
        task?.cancel()
        task = nil
        transcript = ""
        errorMessage = nil
        finished = false

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "تعذّر تشغيل الميكروفون: \(error.localizedDescription)"
            finished = true
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            errorMessage = "لا يوجد ميكروفون متاح."
            finished = true
            return
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "تعذّر بدء التسجيل: \(error.localizedDescription)"
            cleanupAudio()
            finished = true
            return
        }
        isRecording = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            DispatchQueue.main.async {
                guard let self else { return }
                if let text { self.transcript = text }
                if isFinal || failed { self.finish() }
            }
        }
    }

    func stop() {
        guard isRecording else { return }
        cleanupAudio()
        request?.endAudio()
        isRecording = false
        // Safety net in case the recogniser never delivers a final result.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.finish()
        }
    }

    private func cleanupAudio() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func finish() {
        if isRecording {
            cleanupAudio()
            request?.endAudio()
            isRecording = false
        }
        guard !finished else { return }
        finished = true
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        onFinish?(transcript)
    }
}
