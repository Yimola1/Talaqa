import SwiftUI
import SwiftData

struct PronunciationHomeView: View {
    @Bindable var profile: UserProfile
    @State private var customText = ""

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("طريقة المحاكاة (Shadowing)").font(.headline)
                    Text("استمع للجملة، ثم سجّل صوتك وأنت تكررها. ستلوّن الكلمات التي نطقتها بوضوح بالأخضر، والتي تحتاج تدريباً بالأحمر.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("أصوات صعبة على المتحدّثين بالعربية") {
                ForEach(ContentStore.shared.shadowingGroups()) { group in
                    NavigationLink {
                        ShadowingView(items: group.items, profile: profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.focusAr).font(.headline)
                                Text(group.focus).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(group.items.count)").foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("تدرّب على جملتك الخاصة") {
                TextField("Type any English sentence", text: $customText, axis: .vertical)
                    .ltr()
                NavigationLink("ابدأ") {
                    ShadowingView(items: [ShadowingItem(id: "custom", text: customText.trimmingCharacters(in: .whitespacesAndNewlines),
                                                        focus: "Custom", focusAr: "جملة خاصة",
                                                        tipAr: "استمع أولاً ثم كرّر بنفس الإيقاع.", level: profile.level)],
                                  profile: profile)
                }
                .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").count < 2)
            }
        }
        .navigationTitle("النطق")
    }
}

struct ShadowingView: View {
    let items: [ShadowingItem]
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var recognizer = SpeechRecognizer()
    @State private var matches: [WordMatch] = []
    @State private var score: Double?
    @State private var permissionError: String?
    @State private var scores: [Double] = []
    @State private var finished = false

    private var item: ShadowingItem? { index < items.count ? items[index] : nil }

    var body: some View {
        VStack(spacing: 18) {
            if finished || item == nil {
                summary
            } else if let item {
                ProgressView(value: Double(index), total: Double(items.count)).tint(Theme.primary)
                ScrollView {
                    VStack(spacing: 18) {
                        Text(item.focusAr).font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2), in: Capsule())

                        sentenceView(item)

                        HStack(spacing: 16) {
                            Button { SpeechService.shared.speak(item.text) } label: {
                                Label("استمع", systemImage: "play.fill")
                            }
                            .buttonStyle(.bordered)
                            Button { SpeechService.shared.speak(item.text, slow: true) } label: {
                                Label("ببطء", systemImage: "tortoise.fill")
                            }
                            .buttonStyle(.bordered)
                        }

                        Label(item.tipAr, systemImage: "lightbulb")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .cardStyle(padding: 12)

                        if !recognizer.transcript.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ما سمعناه:").font(.caption).foregroundStyle(.secondary)
                                Text(recognizer.transcript).italic().ltr()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .cardStyle(padding: 12)
                        }

                        if let score {
                            scoreView(score)
                        }
                        if let err = permissionError ?? recognizer.errorMessage {
                            Text(err).font(.footnote).foregroundStyle(.red)
                        }
                    }
                }

                recordButton

                if score != nil {
                    Button(index + 1 < items.count ? "الجملة التالية" : "إنهاء") { next() }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.success))
                }
            }
        }
        .padding()
        .background(Theme.pageBackground)
        .navigationTitle("تدريب النطق")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            recognizer.onFinish = { transcript in evaluate(transcript) }
            if let item { SpeechService.shared.speak(item.text) }
        }
        .onDisappear { recognizer.stop() }
    }

    private func sentenceView(_ item: ShadowingItem) -> some View {
        FlowLayout(spacing: 6, lineSpacing: 10) {
            if matches.isEmpty {
                ForEach(Array(item.text.split(separator: " ").enumerated()), id: \.offset) { _, w in
                    Text(String(w)).font(.title2.weight(.semibold))
                }
            } else {
                ForEach(matches) { m in
                    Text(m.word)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(m.matched ? Color.green : Color.red)
                        .onTapGesture { SpeechService.shared.speak(m.word, slow: true) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .ltr()
    }

    private func scoreView(_ score: Double) -> some View {
        let pct = Int(score * 100)
        let message: String
        switch pct {
        case 90...: message = "نطق ممتاز! 🌟"
        case 70..<90: message = "جيد جداً، اضغط على الكلمات الحمراء لسماعها ثم أعد المحاولة."
        default: message = "حاول مرة أخرى ببطء ووضوح. اضغط على الكلمات الحمراء لسماعها."
        }
        return HStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: score, lineWidth: 8, color: pct >= 90 ? .green : pct >= 70 ? .orange : .red)
                Text("\(pct)%").font(.headline)
            }
            .frame(width: 64, height: 64)
            Text(message).font(.subheadline)
            Spacer()
        }
        .cardStyle()
    }

    private var recordButton: some View {
        Button {
            Task { await toggle() }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: recognizer.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(recognizer.isRecording ? Color.red.gradient : Theme.primary.gradient, in: Circle())
                    .symbolEffect(.pulse, isActive: recognizer.isRecording)
                Text(recognizer.isRecording ? "اضغط للإيقاف" : (score == nil ? "اضغط وسجّل" : "أعد المحاولة"))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func toggle() async {
        if recognizer.isRecording {
            recognizer.stop()
            return
        }
        guard await SpeechRecognizer.requestPermissions() else {
            permissionError = "يرجى السماح بالميكروفون والتعرّف على الكلام من إعدادات الآيفون."
            return
        }
        permissionError = nil
        matches = []
        score = nil
        recognizer.start()
    }

    private func evaluate(_ transcript: String) {
        guard let item, !transcript.isEmpty else { return }
        let result = TextMatcher.compare(target: item.text, spoken: transcript)
        withAnimation {
            matches = result.matches
            score = result.score
        }
        scores.append(result.score)
        let xp = result.score >= 0.9 ? 10 : result.score >= 0.7 ? 6 : 2
        ProgressService.record(xp: xp, skill: .speaking, score: result.score, detail: item.focus,
                               profile: profile, context: context)
        if result.score < 0.7 {
            let missed = result.matches.filter { !$0.matched }.map(\.word).joined(separator: " ")
            ProgressService.recordMistake(skill: .speaking, topic: item.focusAr, wrong: missed,
                                          correct: item.text, explanation: item.tipAr, context: context)
        }
    }

    private func next() {
        if index + 1 < items.count {
            index += 1
            matches = []
            score = nil
            recognizer.transcript = ""
            SpeechService.shared.speak(items[index].text)
        } else {
            withAnimation { finished = true }
        }
    }

    private var summary: some View {
        let best = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        return VStack(spacing: 18) {
            Spacer()
            Text("🎤").font(.system(size: 70))
            Text("انتهى التدريب").font(.largeTitle.bold())
            StatTile(value: "\(Int(best * 100))%", label: "متوسط الوضوح", icon: "waveform", color: .orange)
                .frame(maxWidth: 200)
            Text("التكرار اليومي القصير أفضل من تدريب طويل متقطّع.")
                .foregroundStyle(.secondary)
            Spacer()
            Button("تم") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
    }
}
