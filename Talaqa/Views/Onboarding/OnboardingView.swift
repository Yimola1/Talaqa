import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()

    private let minuteOptions = [5, 10, 15, 20, 30]

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: 5)
                .tint(Theme.primary)
                .padding()

            ScrollView {
                VStack(spacing: 24) {
                    switch step {
                    case 0: welcome
                    case 1: nameStep
                    case 2: goalStep
                    case 3: minutesStep
                    default: reminderStep
                    }
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                if step > 0 {
                    Button("رجوع") { withAnimation { step -= 1 } }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
                Button(step == 4 ? "لنبدأ!" : "التالي") { next() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .background(Theme.pageBackground)
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 70))
                .foregroundStyle(Theme.gradient)
                .padding(.top, 40)
            Text("أهلاً بك في طلاقة")
                .font(.largeTitle.bold())
            Text("تعلّم الإنجليزية بذكاء: تكرار متباعد يثبّت الكلمات في ذاكرتك، معلّم ذكي تتحدث معه، وتقييم فوري لنطقك.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 14) {
                feature("brain.head.profile", "خطة يومية مخصّصة لمستواك وأهدافك")
                feature("bubble.left.and.bubble.right.fill", "محادثات واقعية مع معلّم ذكي يصحّح أخطاءك")
                feature("waveform", "تدريب على النطق مع تقييم كلمة بكلمة")
                feature("chart.line.uptrend.xyaxis", "تتبّع تقدّمك وأخطائك الشائعة")
            }
            .cardStyle()
        }
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.primary).frame(width: 28)
            Text(text)
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ما اسمك؟").font(.title.bold())
            Text("سيستخدمه المعلّم الذكي في محادثاتكما.").foregroundStyle(.secondary)
            TextField("اسمك", text: $profile.name)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .submitLabel(.next)
                .onSubmit { next() }
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ما هدفك الأساسي؟").font(.title.bold())
            ForEach(LearningGoal.allCases) { goal in
                Button {
                    profile.goal = goal
                } label: {
                    HStack {
                        Image(systemName: goal.icon).frame(width: 30)
                        Text(goal.title)
                        Spacer()
                        if profile.goal == goal {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.primary)
                        }
                    }
                    .padding()
                    .background(profile.goal == goal ? Theme.primary.opacity(0.12) : Theme.cardBackground,
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var minutesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("كم دقيقة يومياً؟").font(.title.bold())
            Text("الاستمرارية أهم من المدة. حتى ٥ دقائق يومياً تصنع فرقاً كبيراً.")
                .foregroundStyle(.secondary)
            ForEach(minuteOptions, id: \.self) { m in
                Button {
                    profile.dailyMinutes = m
                } label: {
                    HStack {
                        Text("\(m) دقيقة")
                        Spacer()
                        Text(label(for: m)).foregroundStyle(.secondary).font(.subheadline)
                        if profile.dailyMinutes == m {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.primary)
                        }
                    }
                    .padding()
                    .background(profile.dailyMinutes == m ? Theme.primary.opacity(0.12) : Theme.cardBackground,
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func label(for minutes: Int) -> String {
        switch minutes {
        case 5: return "خفيف"
        case 10: return "منتظم"
        case 15: return "جاد"
        case 20: return "مكثّف"
        default: return "بطل"
        }
    }

    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("تذكير يومي").font(.title.bold())
            Text("متى تحب أن نذكّرك؟ يمكنك تغييره لاحقاً من الإعدادات.")
                .foregroundStyle(.secondary)
            DatePicker("الوقت", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
    }

    private func next() {
        if step < 4 {
            withAnimation { step += 1 }
            return
        }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = comps.hour ?? 20, minute = comps.minute ?? 0
        UserDefaults.standard.set(true, forKey: "reminderEnabled")
        UserDefaults.standard.set(hour, forKey: "reminderHour")
        UserDefaults.standard.set(minute, forKey: "reminderMinute")
        Task { await NotificationService.requestAndSchedule(hour: hour, minute: minute) }
        profile.onboardingDone = true
        try? context.save()
    }
}
