import SwiftUI
import SwiftData

/// Listening practice: hear a sentence, type what you heard, get word-by-word feedback.
struct DictationView: View {
    let level: CEFRLevel
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var sentences: [String] = []
    @State private var index = 0
    @State private var typed = ""
    @State private var matches: [WordMatch] = []
    @State private var score: Double?
    @State private var plays = 0
    @State private var scores: [Double] = []
    @State private var finished = false
    @FocusState private var focused: Bool

    static func sentences(for level: CEFRLevel, count: Int = 6) -> [String] {
        let store = ContentStore.shared
        let fromVocab = store.vocabulary.filter { $0.level <= level }.map(\.example)
        let fromShadowing = store.shadowing.filter { $0.level <= level }.map(\.text)
        let pool = Array(Set(fromVocab + fromShadowing)).filter { $0.split(separator: " ").count >= 4 }
        return Array(pool.shuffled().prefix(count))
    }

    private var current: String? { index < sentences.count ? sentences[index] : nil }

    var body: some View {
        VStack(spacing: 16) {
            if sentences.isEmpty {
                ProgressView()
            } else if finished || current == nil {
                summary
            } else if let sentence = current {
                ProgressView(value: Double(index), total: Double(sentences.count)).tint(Theme.primary)
                ScrollView {
                    VStack(spacing: 18) {
                        Text("استمع واكتب ما تسمعه بالضبط").font(.headline)
                        HStack(spacing: 14) {
                            Button {
                                plays += 1
                                SpeechService.shared.speak(sentence)
                            } label: {
                                Label("استمع", systemImage: "play.circle.fill").font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            Button {
                                plays += 1
                                SpeechService.shared.speak(sentence, slow: true)
                            } label: {
                                Label("ببطء", systemImage: "tortoise.fill").font(.title3)
                            }
                            .buttonStyle(.bordered)
                        }
                        Text("مرات الاستماع: \(plays)").font(.caption).foregroundStyle(.secondary)

                        TextField("Type what you hear…", text: $typed, axis: .vertical)
                            .lineLimit(2...5)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .padding()
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                            .focused($focused)
                            .disabled(score != nil)
                            .ltr()

                        if let score {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("الجملة الصحيحة:").font(.caption).foregroundStyle(.secondary)
                                FlowLayout(spacing: 6, lineSpacing: 8) {
                                    ForEach(matches) { m in
                                        Text(m.word)
                                            .underline(!m.matched)
                                            .font(.title3.weight(.semibold))
                                            .foregroundStyle(m.matched ? Color.green : Color.red)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .ltr()
                                Text(score >= 0.9 ? "ممتاز! أذنك تتحسّن 👂" :
                                        score >= 0.6 ? "جيد! الكلمات الحمراء هي التي فاتتك." :
                                        "استمع مرة أخرى ببطء وركّز على الكلمات الحمراء.")
                                    .font(.subheadline)
                            }
                            .cardStyle()
                        }
                    }
                }
                if score == nil {
                    Button("تحقّق") { check(sentence) }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Button(index + 1 < sentences.count ? "التالي" : "النتيجة") { next() }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.success))
                }
            }
        }
        .padding()
        .background(Theme.pageBackground)
        .navigationTitle("الإملاء والاستماع")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if sentences.isEmpty { sentences = Self.sentences(for: level) }
            if let s = current, plays == 0 {
                plays = 1
                SpeechService.shared.speak(s)
            }
        }
        .onDisappear { SpeechService.shared.stop() }
    }

    private func check(_ sentence: String) {
        focused = false
        let result = TextMatcher.compare(target: sentence, spoken: typed)
        withAnimation {
            matches = result.matches
            score = result.score
        }
        scores.append(result.score)
        if result.score < 0.6 {
            let missed = result.matches.filter { !$0.matched }.map(\.word).joined(separator: " ")
            ProgressService.recordMistake(skill: .listening, topic: "إملاء", wrong: typed,
                                          correct: sentence, explanation: "كلمات فاتتك: \(missed)",
                                          context: context)
        }
    }

    private func next() {
        if index + 1 < sentences.count {
            index += 1
            typed = ""
            matches = []
            score = nil
            plays = 1
            SpeechService.shared.speak(sentences[index])
        } else {
            let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
            ProgressService.record(xp: 5 + Int(avg * Double(sentences.count) * 3), skill: .listening,
                                   score: avg, detail: "إملاء", profile: profile, context: context)
            withAnimation { finished = true }
        }
    }

    private var summary: some View {
        let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        return VStack(spacing: 18) {
            Spacer()
            Text("👂").font(.system(size: 70))
            Text("انتهى تمرين الاستماع").font(.largeTitle.bold())
            StatTile(value: "\(Int(avg * 100))%", label: "دقة الفهم", icon: "ear.fill", color: .teal)
                .frame(maxWidth: 200)
            Spacer()
            Button("تم") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
    }
}
