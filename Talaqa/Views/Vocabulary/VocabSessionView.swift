import SwiftUI
import SwiftData

private enum SessionCard: Identifiable {
    case review(WordCard)
    case fresh(VocabItem)

    var id: String {
        switch self {
        case .review(let c): return "r-\(c.wordID)-\(c.reps)"
        case .fresh(let v): return "n-\(v.id)"
        }
    }
    var word: String {
        switch self { case .review(let c): return c.word; case .fresh(let v): return v.word }
    }
    var ipa: String {
        switch self { case .review(let c): return c.ipa; case .fresh(let v): return v.ipa }
    }
    var meaningAr: String {
        switch self { case .review(let c): return c.meaningAr; case .fresh(let v): return v.meaningAr }
    }
    var example: String {
        switch self { case .review(let c): return c.example; case .fresh(let v): return v.example }
    }
    var exampleAr: String {
        switch self { case .review(let c): return c.exampleAr; case .fresh(let v): return v.exampleAr }
    }
    var isNew: Bool {
        if case .fresh = self { return true }
        return false
    }
    /// Production (typing) mode for cards the learner has already seen a few times.
    var isProduction: Bool {
        if case .review(let c) = self {
            return c.reps >= 2 && c.state == .review
                && c.example.range(of: c.word, options: .caseInsensitive) != nil
        }
        return false
    }
}

struct VocabSessionView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [SessionCard] = []
    @State private var index = 0
    @State private var loaded = false
    @State private var revealed = false
    @State private var typed = ""
    @State private var typedCorrect: Bool?
    @State private var reviewed = 0
    @State private var remembered = 0
    @State private var finished = false
    @State private var earnedXP = 0

    private let fsrs = FSRS()

    var body: some View {
        Group {
            if !loaded {
                ProgressView()
            } else if finished || queue.isEmpty {
                summary
            } else {
                cardView(queue[index])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.pageBackground)
        .navigationTitle("المفردات")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    // MARK: Loading

    private func load() {
        guard !loaded else { return }
        let now = Date()
        var due = FetchDescriptor<WordCard>(predicate: #Predicate<WordCard> { $0.due <= now },
                                            sortBy: [SortDescriptor(\.due)])
        due.fetchLimit = 60
        let dueCards = (try? context.fetch(due)) ?? []

        let allCards = (try? context.fetch(FetchDescriptor<WordCard>())) ?? []
        let known = Set(allCards.map(\.wordID))
        let learnedToday = allCards.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        let newCount = max(0, DailyPlanner.newWordsTarget(minutes: profile.dailyMinutes) - learnedToday)

        let level = profile.level
        let candidates = ContentStore.shared.vocabulary
            .filter { $0.level <= level && !known.contains($0.id) }
            .sorted { a, b in
                if (a.level == level) != (b.level == level) { return a.level == level }
                return a.level < b.level
            }
        var fresh = Array(candidates.prefix(newCount))
        if fresh.isEmpty && dueCards.isEmpty {
            // Everything at this level is learned: allow a preview of the next level.
            fresh = Array(ContentStore.shared.vocabulary.filter { $0.level == level.next && !known.contains($0.id) }.prefix(newCount))
        }

        // Interleave new words between reviews.
        var items: [SessionCard] = dueCards.map { .review($0) }
        for (i, v) in fresh.enumerated() {
            let pos = min(items.count, i * 3 + 1)
            items.insert(.fresh(v), at: pos)
        }
        queue = items
        loaded = true
    }

    // MARK: Card

    @ViewBuilder
    private func cardView(_ item: SessionCard) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(max(queue.count, 1)))
                .tint(Theme.primary)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 18) {
                    if item.isProduction {
                        productionCard(item)
                    } else {
                        recognitionCard(item)
                    }
                }
                .padding()
            }

            bottomControls(item)
                .padding()
        }
        .id(item.id)
        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
    }

    private func recognitionCard(_ item: SessionCard) -> some View {
        VStack(spacing: 14) {
            if item.isNew {
                Text("كلمة جديدة ✨").font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.25), in: Capsule())
            }
            Text(item.word).font(.system(size: 40, weight: .bold)).ltr()
            if !item.ipa.isEmpty {
                Text(item.ipa).font(.title3).foregroundStyle(.secondary).ltr()
            }
            HStack {
                SpeakButton(text: item.word)
                SpeakButton(text: item.word, slow: true)
            }
            if revealed || item.isNew {
                Divider()
                Text(item.meaningAr).font(.title2.bold()).foregroundStyle(Theme.primary)
                exampleBlock(item)
            } else {
                Text("حاول أن تتذكّر المعنى قبل الكشف 🤔")
                    .foregroundStyle(.secondary).padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardStyle()
        .onAppear { SpeechService.shared.speak(item.word) }
    }

    private func exampleBlock(_ item: SessionCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(item.example).font(.body.italic())
                Spacer()
                SpeakButton(text: item.example, size: 15)
            }
            .ltr()
            if !item.exampleAr.isEmpty {
                Text(item.exampleAr).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Theme.pageBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func productionCard(_ item: SessionCard) -> some View {
        let blanked = item.example.replacingOccurrences(of: item.word, with: "_____", options: .caseInsensitive)
        return VStack(spacing: 16) {
            Text("اكتب الكلمة الإنجليزية ✍️").font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Theme.primary.opacity(0.15), in: Capsule())
            Text(item.meaningAr).font(.title.bold())
            Text(blanked).font(.body.italic()).multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading).ltr()
            if !item.exampleAr.isEmpty {
                Text(item.exampleAr).font(.subheadline).foregroundStyle(.secondary)
            }
            TextField("type the word…", text: $typed)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.title3)
                .padding()
                .background(Theme.pageBackground, in: RoundedRectangle(cornerRadius: 12))
                .ltr()
                .disabled(typedCorrect != nil)
                .onSubmit(checkTyped)
            if let ok = typedCorrect {
                FeedbackBanner(correct: ok, title: ok ? "صحيح! 👏" : "الإجابة: \(item.word)",
                               detail: ok ? "" : "سنعيد هذه الكلمة بعد قليل.")
                    .onAppear { SpeechService.shared.speak(item.word) }
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    @ViewBuilder
    private func bottomControls(_ item: SessionCard) -> some View {
        if item.isProduction {
            if let ok = typedCorrect {
                Button("التالي") { rate(ok ? .good : .again) }
                    .buttonStyle(PrimaryButtonStyle(color: ok ? Theme.success : Theme.primary))
            } else {
                Button("تحقّق", action: checkTyped)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } else if revealed || item.isNew {
            ratingButtons(item)
        } else {
            Button("اكشف المعنى") { withAnimation { revealed = true } }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func ratingButtons(_ item: SessionCard) -> some View {
        let state: SchedulingState
        switch item {
        case .review(let c): state = c.schedulingState
        case .fresh: state = SchedulingState(stability: 0, difficulty: 0, due: Date(), lastReview: nil, reps: 0, lapses: 0, state: .new)
        }
        let labels = fsrs.previewLabels(for: state)
        let colors: [Rating: Color] = [.again: .red, .hard: .orange, .good: .green, .easy: .blue]
        return HStack(spacing: 8) {
            ForEach(Rating.allCases) { r in
                Button { rate(r) } label: {
                    VStack(spacing: 2) {
                        Text(r.title).font(.subheadline.bold())
                        Text(labels[r] ?? "").font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background((colors[r] ?? .gray).gradient, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Actions

    private func checkTyped() {
        guard typedCorrect == nil, index < queue.count else { return }
        let item = queue[index]
        let ok = TextMatcher.matchesAnswer(typed, item.word)
        typedCorrect = ok
        if !ok {
            ProgressService.recordMistake(skill: .vocabulary, topic: "مفردات", wrong: typed,
                                          correct: item.word, explanation: item.meaningAr, context: context)
        }
    }

    private func rate(_ rating: Rating) {
        guard index < queue.count else { return }
        let item = queue[index]
        let card: WordCard
        switch item {
        case .review(let c):
            card = c
        case .fresh(let v):
            card = WordCard(item: v)
            context.insert(card)
        }
        card.schedulingState = fsrs.schedule(card.schedulingState, rating: rating)
        try? context.save()

        reviewed += 1
        if rating == .again {
            if queue.count < 120 { queue.append(.review(card)) }
        } else {
            remembered += 1
        }
        advance()
    }

    private func advance() {
        revealed = false
        typed = ""
        typedCorrect = nil
        if index + 1 < queue.count {
            withAnimation { index += 1 }
        } else {
            complete()
        }
    }

    private func complete() {
        let xp = reviewed * 2 + remembered
        earnedXP = xp
        if reviewed > 0 {
            ProgressService.record(xp: xp, skill: .vocabulary,
                                   score: Double(remembered) / Double(reviewed),
                                   detail: "\(reviewed) بطاقة", profile: profile, context: context)
        }
        withAnimation { finished = true }
    }

    // MARK: Summary

    private var summary: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(reviewed == 0 ? "🌿" : "🎉").font(.system(size: 70))
            if reviewed == 0 {
                Text("لا توجد بطاقات الآن").font(.title.bold())
                Text("راجعت كل شيء! عُد لاحقاً، فالتكرار المتباعد يعيد الكلمات في الوقت المثالي قبل أن تنساها.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
            } else {
                Text("أحسنت!").font(.largeTitle.bold())
                HStack(spacing: 12) {
                    StatTile(value: "\(reviewed)", label: "بطاقة", icon: "rectangle.stack.fill")
                    StatTile(value: "\(Int(Double(remembered) / Double(max(reviewed, 1)) * 100))%", label: "تذكّرت", icon: "brain.head.profile", color: .green)
                    StatTile(value: "+\(earnedXP)", label: "XP", icon: "star.fill", color: .orange)
                }
            }
            Spacer()
            Button("تم") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}
