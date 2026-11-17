import SwiftUI
import SwiftData

struct GrammarLessonView: View {
    let lesson: GrammarLesson
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        LevelBadge(level: lesson.level)
                        Text(lesson.title).font(.subheadline).foregroundStyle(.secondary).ltr()
                    }
                    Text(lesson.titleAr).font(.largeTitle.bold())
                    Text(lesson.summaryAr).foregroundStyle(.secondary)
                }

                ForEach(Array(lesson.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.headingAr).font(.title3.bold())
                        Text(section.bodyAr)
                        ForEach(section.examples, id: \.self) { ex in
                            HStack {
                                Text(ex).font(.body.italic())
                                Spacer()
                                SpeakButton(text: ex, size: 14)
                            }
                            .padding(10)
                            .background(Theme.pageBackground, in: RoundedRectangle(cornerRadius: 10))
                            .ltr()
                        }
                    }
                    .cardStyle()
                }

                if let tip = lesson.arabicTip {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("انتبه! خطأ شائع عند العرب", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline).foregroundStyle(.orange)
                        Text(tip)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                }

                NavigationLink {
                    ExerciseSessionView(title: lesson.titleAr, exercises: lesson.exercises,
                                        skill: .grammar, topic: lesson.title, profile: profile) { score in
                        context.insert(LessonCompletion(lessonID: lesson.id, score: score))
                        try? context.save()
                    }
                } label: {
                    Text("ابدأ التمارين (\(lesson.exercises.count))")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WordToken: Identifiable, Hashable {
    let id = UUID()
    let text: String
}

struct ExerciseSessionView: View {
    let title: String
    let exercises: [Exercise]
    let skill: Skill
    let topic: String
    @Bindable var profile: UserProfile
    var onFinish: (Double) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var correctCount = 0
    @State private var result: Bool?
    @State private var selected: String?
    @State private var typed = ""
    @State private var built: [WordToken] = []
    @State private var pool: [WordToken] = []
    @State private var finished = false
    @State private var earnedXP = 0

    private var current: Exercise? { index < exercises.count ? exercises[index] : nil }

    var body: some View {
        VStack(spacing: 16) {
            if finished || current == nil {
                summary
            } else if let ex = current {
                ProgressView(value: Double(index), total: Double(exercises.count)).tint(Theme.primary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let promptAr = ex.promptAr, !promptAr.isEmpty {
                            Text(promptAr).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Text(ex.prompt)
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .ltr()
                        exerciseBody(ex)
                        if let ok = result {
                            FeedbackBanner(correct: ok,
                                           title: ok ? "إجابة صحيحة! 🎉" : "الإجابة الصحيحة: \(displayAnswer(ex))",
                                           detail: ex.explanationAr)
                        }
                    }
                }
                if result == nil {
                    Button("تحقّق") { check(ex) }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canCheck(ex))
                } else {
                    Button(index + 1 < exercises.count ? "متابعة" : "عرض النتيجة") { next() }
                        .buttonStyle(PrimaryButtonStyle(color: result == true ? Theme.success : Theme.primary))
                }
            }
        }
        .padding()
        .background(Theme.pageBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prepare() }
    }

    @ViewBuilder
    private func exerciseBody(_ ex: Exercise) -> some View {
        switch ex.kind {
        case .multipleChoice:
            VStack(spacing: 10) {
                ForEach(ex.options ?? [], id: \.self) { option in
                    Button {
                        if result == nil { selected = option }
                    } label: {
                        HStack {
                            Text(option)
                            Spacer()
                            if result != nil && option == ex.answer {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            } else if selected == option {
                                Image(systemName: "largecircle.fill.circle").foregroundStyle(Theme.primary)
                            }
                        }
                        .padding()
                        .background(optionBackground(option, ex), in: RoundedRectangle(cornerRadius: 14))
                        .ltr()
                    }
                    .buttonStyle(.plain)
                }
            }
        case .fillBlank:
            TextField("اكتب إجابتك هنا", text: $typed)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.title3)
                .padding()
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                .ltr()
                .disabled(result != nil)
        case .reorder:
            VStack(alignment: .leading, spacing: 16) {
                FlowLayout {
                    ForEach(built) { token in
                        tokenChip(token, filled: true) {
                            guard result == nil else { return }
                            built.removeAll { $0.id == token.id }
                            pool.append(token)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
                .padding(10)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                FlowLayout {
                    ForEach(pool) { token in
                        tokenChip(token, filled: false) {
                            guard result == nil else { return }
                            pool.removeAll { $0.id == token.id }
                            built.append(token)
                        }
                    }
                }
            }
            .ltr()
        }
    }

    private func tokenChip(_ token: WordToken, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(token.text)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(filled ? Theme.primary.opacity(0.15) : Theme.cardBackground,
                            in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.primary.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }

    private func optionBackground(_ option: String, _ ex: Exercise) -> Color {
        if result != nil {
            if option == ex.answer { return Color.green.opacity(0.18) }
            if option == selected { return Color.red.opacity(0.15) }
        }
        return selected == option ? Theme.primary.opacity(0.12) : Theme.cardBackground
    }

    private func displayAnswer(_ ex: Exercise) -> String {
        ex.answer.components(separatedBy: "|").first ?? ex.answer
    }

    private func canCheck(_ ex: Exercise) -> Bool {
        switch ex.kind {
        case .multipleChoice: return selected != nil
        case .fillBlank: return !typed.trimmingCharacters(in: .whitespaces).isEmpty
        case .reorder: return pool.isEmpty && !built.isEmpty
        }
    }

    private func prepare() {
        guard let ex = current else { return }
        selected = nil
        typed = ""
        result = nil
        if ex.kind == .reorder {
            built = []
            var tokens = ex.answer.split(separator: " ").map { WordToken(text: String($0)) }
            tokens.shuffle()
            pool = tokens
        }
    }

    private func check(_ ex: Exercise) {
        let ok: Bool
        let given: String
        switch ex.kind {
        case .multipleChoice:
            given = selected ?? ""
            ok = given == ex.answer
        case .fillBlank:
            given = typed
            ok = TextMatcher.matchesAnswer(typed, ex.answer)
        case .reorder:
            given = built.map(\.text).joined(separator: " ")
            ok = TextMatcher.normalize(given) == TextMatcher.normalize(ex.answer)
        }
        withAnimation { result = ok }
        if ok {
            correctCount += 1
        } else {
            ProgressService.recordMistake(skill: skill, topic: topic, wrong: given,
                                          correct: displayAnswer(ex), explanation: ex.explanationAr,
                                          context: context)
        }
    }

    private func next() {
        if index + 1 < exercises.count {
            index += 1
            prepare()
        } else {
            let score = Double(correctCount) / Double(max(exercises.count, 1))
            earnedXP = correctCount * 5 + 10
            ProgressService.record(xp: earnedXP, skill: skill, score: score, detail: topic,
                                   profile: profile, context: context)
            onFinish(score)
            withAnimation { finished = true }
        }
    }

    private var summary: some View {
        let pct = Int(Double(correctCount) / Double(max(exercises.count, 1)) * 100)
        return VStack(spacing: 18) {
            Spacer()
            Text(pct >= 80 ? "🏆" : pct >= 50 ? "💪" : "📚").font(.system(size: 70))
            Text(pct >= 80 ? "ممتاز!" : pct >= 50 ? "جيد جداً" : "تحتاج مراجعة").font(.largeTitle.bold())
            HStack(spacing: 12) {
                StatTile(value: "\(correctCount)/\(exercises.count)", label: "صحيحة", icon: "checkmark.circle.fill", color: .green)
                StatTile(value: "\(pct)%", label: "النتيجة", icon: "chart.bar.fill")
                StatTile(value: "+\(earnedXP)", label: "XP", icon: "star.fill", color: .orange)
            }
            if pct < 80 {
                Text("أُضيفت أخطاؤك إلى «أخطائي» لمراجعتها لاحقاً.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button("إنهاء") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
    }
}
