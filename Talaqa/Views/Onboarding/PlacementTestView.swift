import SwiftUI
import SwiftData

struct PlacementTestView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// When opened again from settings we dismiss at the end instead of relying on RootView.
    var isRetake = false

    private enum Stage { case intro, question, result }

    @State private var stage: Stage = .intro
    @State private var engine = PlacementEngine(questions: ContentStore.shared.placement)
    @State private var current: PlacementQuestion?
    @State private var selected: Int?
    @State private var result: CEFRLevel = .a1

    var body: some View {
        VStack {
            switch stage {
            case .intro: intro
            case .question: questionView
            case .result: resultView
            }
        }
        .padding(24)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.pageBackground)
    }

    private var intro: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "target").font(.system(size: 64)).foregroundStyle(Theme.gradient)
            Text("اختبار تحديد المستوى").font(.largeTitle.bold())
            Text("\(engine.total) سؤالاً تتكيّف مع إجاباتك: تصعب إذا أجبت صحيحاً وتسهل إذا أخطأت. يستغرق حوالي ٤ دقائق.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("ابدأ الاختبار") {
                current = engine.nextQuestion()
                stage = current == nil ? .result : .question
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("أنا مبتدئ تماماً، تخطَّ الاختبار") {
                finish(with: .a1)
            }
            .padding(.top, 4)
        }
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProgressView(value: Double(engine.answeredCount), total: Double(max(engine.total, 1)))
                .tint(Theme.primary)
            Text("السؤال \(engine.answeredCount + 1) من \(engine.total)")
                .font(.subheadline).foregroundStyle(.secondary)
            if let q = current {
                Text(q.prompt)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ltr()
                    .padding(.vertical, 8)
                ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                    Button {
                        selected = idx
                    } label: {
                        HStack {
                            Text(option)
                            Spacer()
                            if selected == idx {
                                Image(systemName: "largecircle.fill.circle").foregroundStyle(Theme.primary)
                            }
                        }
                        .padding()
                        .background(selected == idx ? Theme.primary.opacity(0.12) : Theme.cardBackground,
                                    in: RoundedRectangle(cornerRadius: 14))
                        .ltr()
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            Button("التالي") { submit() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selected == nil)
        }
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("🎉").font(.system(size: 70))
            Text("مستواك التقديري").font(.title2).foregroundStyle(.secondary)
            Text(result.rawValue).font(.system(size: 64, weight: .heavy)).foregroundStyle(Theme.gradient)
            Text(result.arabicName).font(.title2.bold())
            Text("سنبني خطتك اليومية على هذا المستوى، وسنعدّلها تلقائياً مع تقدّمك.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("ابدأ التعلّم") { finish(with: result) }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func submit() {
        guard let q = current, let selected else { return }
        engine.record(q, correct: selected == q.answer)
        self.selected = nil
        if let next = engine.nextQuestion() {
            current = next
        } else {
            result = engine.estimatedLevel
            stage = .result
        }
    }

    private func finish(with level: CEFRLevel) {
        profile.level = level
        profile.placementDone = true
        try? context.save()
        if isRetake { dismiss() }
    }
}
