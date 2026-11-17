import SwiftUI
import SwiftData

struct TodayView: View {
    @Bindable var profile: UserProfile
    @Query(sort: \ActivityLog.date, order: .reverse) private var logs: [ActivityLog]
    @Query private var cards: [WordCard]
    @Query private var completions: [LessonCompletion]

    private var todayLogs: [ActivityLog] {
        logs.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var todayXP: Int { todayLogs.reduce(0) { $0 + $1.xp } }
    private var dueCount: Int {
        let now = Date()
        return cards.filter { $0.due <= now }.count
    }
    private var newToday: Int {
        cards.filter { Calendar.current.isDateInToday($0.createdAt) }.count
    }
    private var plan: [PlanTask] {
        DailyPlanner.makePlan(profile: profile, dueCount: dueCount, newLearnedToday: newToday,
                              completedLessons: Set(completions.map(\.lessonID)),
                              doneSkills: Set(todayLogs.map(\.skill)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                Text("خطة اليوم").font(.title2.bold())
                ForEach(plan) { task in
                    NavigationLink {
                        destination(for: task)
                    } label: {
                        PlanRow(task: task)
                    }
                    .buttonStyle(.plain)
                }
                tipCard
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationTitle("اليوم")
    }

    private var header: some View {
        let streak = ProgressService.currentStreak(profile)
        let progress = Double(todayXP) / Double(profile.dailyXPGoal)
        return HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("مرحباً \(profile.displayName) 👋").font(.title2.bold())
                HStack(spacing: 14) {
                    Label("\(streak) يوم", systemImage: "flame.fill")
                    Label("\(profile.xp) XP", systemImage: "star.fill")
                    Text(profile.level.rawValue).bold()
                }
                .font(.subheadline.weight(.semibold))
                Text(progress >= 1 ? "أحسنت! أكملت هدف اليوم 🎯" : "هدف اليوم: \(profile.dailyXPGoal) XP")
                    .font(.footnote)
                    .opacity(0.9)
            }
            Spacer()
            ZStack {
                ProgressRing(progress: progress)
                VStack(spacing: 0) {
                    Text("\(todayXP)").font(.title3.bold())
                    Text("XP").font(.caption2)
                }
            }
            .frame(width: 78, height: 78)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var tipCard: some View {
        let tips = [
            "الأسلوب الأقوى للحفظ: حاول تذكّر الكلمة قبل قلب البطاقة. الجهد في التذكّر هو ما يثبّتها.",
            "تحدّث بصوت عالٍ حتى لو كنت وحدك. تدريب عضلات النطق لا يقلّ أهمية عن الفهم.",
            "لا تترجم كل كلمة. حاول فهم المعنى العام من السياق أولاً.",
            "أخطاؤك كنز: راجع قسم «أخطائي» أسبوعياً.",
            "انتبه لأداة التعريف: نقول I am a teacher وليس I am teacher."
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            Label("نصيحة اليوم", systemImage: "lightbulb.fill").font(.headline).foregroundStyle(.yellow)
            Text(tips[day % tips.count])
        }
        .cardStyle()
    }

    @ViewBuilder
    private func destination(for task: PlanTask) -> some View {
        switch task.kind {
        case .vocab: VocabSessionView(profile: profile)
        case .grammar(let lesson): GrammarLessonView(lesson: lesson, profile: profile)
        case .shadowing(let items): ShadowingView(items: items, profile: profile)
        case .conversation(let scenario): TutorChatView(scenario: scenario, profile: profile)
        case .reading(let story): StoryView(story: story, profile: profile)
        }
    }
}

struct PlanRow: View {
    let task: PlanTask

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: task.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(task.color.gradient, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.headline).lineLimit(1)
                Text(task.subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: task.done ? "checkmark.circle.fill" : "chevron.left")
                .foregroundStyle(task.done ? Theme.success : .secondary)
                .font(task.done ? .title2 : .body)
        }
        .cardStyle(padding: 12)
    }
}
