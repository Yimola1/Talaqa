import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    @Bindable var profile: UserProfile
    @Query(sort: \ActivityLog.date) private var logs: [ActivityLog]
    @Query private var cards: [WordCard]
    @Query private var completions: [LessonCompletion]

    private struct DayXP: Identifiable {
        let date: Date
        let xp: Int
        var id: Date { date }
    }

    private var last7Days: [DayXP] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let xp = logs.filter { cal.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.xp }
            return DayXP(date: day, xp: xp)
        }
    }

    private struct SkillScore: Identifiable {
        let skill: Skill
        let value: Double
        var id: String { skill.rawValue }
    }

    private var skillScores: [SkillScore] {
        Skill.allCases.compactMap { skill in
            let scored = logs.filter { $0.skill == skill && $0.score >= 0 }.suffix(30)
            guard !scored.isEmpty else { return nil }
            return SkillScore(skill: skill, value: scored.reduce(0) { $0 + $1.score } / Double(scored.count) * 100)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    Text(String(profile.displayName.prefix(1)))
                        .font(.largeTitle.bold()).foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Theme.gradient, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName).font(.title2.bold())
                        HStack {
                            LevelBadge(level: profile.level)
                            Text(profile.level.arabicName).foregroundStyle(.secondary)
                        }
                        Label(profile.goal.title, systemImage: profile.goal.icon)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(value: "\(ProgressService.currentStreak(profile))", label: "أيام متتالية", icon: "flame.fill", color: .orange)
                    StatTile(value: "\(profile.longestStreak)", label: "أطول سلسلة", icon: "trophy.fill", color: .yellow)
                    StatTile(value: "\(profile.xp)", label: "مجموع XP", icon: "star.fill", color: Theme.primary)
                    StatTile(value: "\(cards.filter(\.isMastered).count)/\(cards.count)", label: "كلمات متقنة", icon: "brain.head.profile", color: .green)
                    StatTile(value: "\(Set(completions.map(\.lessonID)).count)", label: "دروس مكتملة", icon: "text.book.closed.fill", color: .purple)
                    StatTile(value: "\(cards.filter { $0.due <= Date() }.count)", label: "بانتظار المراجعة", icon: "clock.fill", color: .blue)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("نشاط آخر ٧ أيام").font(.headline)
                    Chart(last7Days) { day in
                        BarMark(x: .value("اليوم", day.date, unit: .day),
                                y: .value("XP", day.xp))
                            .foregroundStyle(Theme.gradient)
                            .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .frame(height: 170)
                }
                .cardStyle()

                if !skillScores.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("مستوى الدقة حسب المهارة").font(.headline)
                        ForEach(skillScores) { s in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label(s.skill.title, systemImage: s.skill.icon).font(.subheadline)
                                    Spacer()
                                    Text("\(Int(s.value))%").font(.subheadline.bold())
                                }
                                ProgressView(value: s.value, total: 100)
                                    .tint(s.value >= 80 ? .green : s.value >= 60 ? .orange : .red)
                            }
                        }
                    }
                    .cardStyle()
                }

                VStack(spacing: 0) {
                    NavigationLink { MistakesView(profile: profile) } label: {
                        row("أخطائي الشائعة", icon: "exclamationmark.bubble.fill", color: .red)
                    }
                    Divider().padding(.leading, 50)
                    NavigationLink { VocabBrowserView() } label: {
                        row("بنك كلماتي", icon: "books.vertical.fill", color: .blue)
                    }
                    Divider().padding(.leading, 50)
                    NavigationLink { SettingsView(profile: profile) } label: {
                        row("الإعدادات", icon: "gearshape.fill", color: .gray)
                    }
                }
                .buttonStyle(.plain)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationTitle("حسابي")
    }

    private func row(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 8))
            Text(title)
            Spacer()
            Image(systemName: "chevron.left").foregroundStyle(.secondary)
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}

struct MistakesView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort: \MistakeRecord.date, order: .reverse) private var mistakes: [MistakeRecord]
    @State private var showResolved = false

    private var visible: [MistakeRecord] { mistakes.filter { showResolved || !$0.resolved } }

    var body: some View {
        List {
            Section {
                Toggle("إظهار الأخطاء المحلولة", isOn: $showResolved)
                if mistakes.contains(where: { !$0.resolved }) {
                    NavigationLink {
                        TutorChatView(scenario: TutorHomeView.mistakeReview(mistakes.filter { !$0.resolved }), profile: profile)
                    } label: {
                        Label("راجعها مع المعلّم الذكي", systemImage: "sparkles")
                    }
                }
            }
            if visible.isEmpty {
                ContentUnavailableView("لا توجد أخطاء", systemImage: "checkmark.seal",
                                       description: Text("كل خطأ ترتكبه في التمارين أو المحادثات يُحفظ هنا لتراجعه."))
            }
            ForEach(visible) { m in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(m.skill.title, systemImage: m.skill.icon).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(m.topic).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    if !m.wrong.isEmpty {
                        Text(m.wrong).strikethrough().foregroundStyle(.red).ltr()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(m.correct).foregroundStyle(.green).bold().ltr()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !m.explanation.isEmpty {
                        Text(m.explanation).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .opacity(m.resolved ? 0.5 : 1)
                .swipeActions {
                    Button(m.resolved ? "إعادة" : "فهمته") {
                        m.resolved.toggle()
                        try? context.save()
                    }
                    .tint(m.resolved ? .orange : .green)
                    Button("حذف", role: .destructive) {
                        context.delete(m)
                        try? context.save()
                    }
                }
            }
        }
        .navigationTitle("أخطائي")
    }
}

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    @AppStorage("accent") private var accent = "en-US"
    @AppStorage("speechRate") private var speechRate = 0.47
    @AppStorage("autoSpeak") private var autoSpeak = true
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("aiProxyURL") private var proxyURL = ""
    @AppStorage("aiAppToken") private var appToken = ""
    @AppStorage("aiModel") private var aiModel = AIClient.defaultModel

    @State private var apiKeyInput = ""
    @State private var hasKey = AIClient.shared.apiKey != nil
    @State private var confirmReset = false
    @State private var showPlacement = false
    @State private var testResult: String?
    @State private var testing = false

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()) ?? Date()
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderHour = c.hour ?? 20
            reminderMinute = c.minute ?? 0
            if reminderEnabled { NotificationService.schedule(hour: reminderHour, minute: reminderMinute) }
        }
    }

    var body: some View {
        Form {
            Section("الملف الشخصي") {
                TextField("الاسم", text: $profile.name)
                Picker("الهدف", selection: Binding(get: { profile.goal }, set: { profile.goal = $0 })) {
                    ForEach(LearningGoal.allCases) { Text($0.title).tag($0) }
                }
                Picker("المستوى", selection: Binding(get: { profile.level }, set: { profile.level = $0 })) {
                    ForEach(CEFRLevel.allCases) { Text("\($0.rawValue) • \($0.arabicName)").tag($0) }
                }
                Button("أعد اختبار تحديد المستوى") { showPlacement = true }
                Picker("الوقت اليومي", selection: $profile.dailyMinutes) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) دقيقة").tag($0) }
                }
            }

            Section("الصوت") {
                Picker("اللهجة", selection: $accent) {
                    Text("أمريكية 🇺🇸").tag("en-US")
                    Text("بريطانية 🇬🇧").tag("en-GB")
                    Text("أسترالية 🇦🇺").tag("en-AU")
                }
                VStack(alignment: .leading) {
                    Text("سرعة النطق")
                    Slider(value: $speechRate, in: 0.3...0.6) {
                        Text("سرعة النطق")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise")
                    } maximumValueLabel: {
                        Image(systemName: "hare")
                    }
                }
                Button("جرّب الصوت") { SpeechService.shared.speak("Hello! Let's practise English together.") }
                Toggle("قراءة ردود المعلّم تلقائياً", isOn: $autoSpeak)
            }

            Section("التذكير اليومي") {
                Toggle("تفعيل التذكير", isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) { _, on in
                        if on {
                            Task { await NotificationService.requestAndSchedule(hour: reminderHour, minute: reminderMinute) }
                        } else {
                            NotificationService.cancel()
                        }
                    }
                if reminderEnabled {
                    DatePicker("الوقت", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
            }

            Section {
                Picker("النموذج", selection: $aiModel) {
                    ForEach(AIClient.models) { Text($0.title).tag($0.id) }
                }
                TextField("رابط الخادم الوسيط (https://…)", text: $proxyURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .ltr()
                if !proxyURL.isEmpty {
                    SecureField("رمز التطبيق (اختياري)", text: $appToken).ltr()
                }
                if hasKey {
                    HStack {
                        Label("مفتاح API محفوظ في Keychain", systemImage: "checkmark.shield.fill").foregroundStyle(.green)
                        Spacer()
                        Button("حذف", role: .destructive) {
                            Keychain.delete(AIClient.keychainKey)
                            hasKey = false
                        }
                    }
                } else {
                    SecureField("أو مفتاح Claude API الشخصي (sk-ant-…)", text: $apiKeyInput).ltr()
                    Button("حفظ المفتاح") {
                        Keychain.save(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines), for: AIClient.keychainKey)
                        apiKeyInput = ""
                        hasKey = AIClient.shared.apiKey != nil
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).count < 10)
                }
                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text("اختبار الاتصال")
                        if testing { Spacer(); ProgressView() }
                    }
                }
                .disabled(testing)
                if let testResult {
                    Text(testResult).font(.footnote)
                }
            } header: {
                Text("المعلّم الذكي")
            } footer: {
                Text("للاستخدام الشخصي يكفي مفتاحك (يُحفظ في Keychain على جهازك فقط). عند نشر التطبيق لآخرين استخدم الخادم الوسيط حتى لا يُكشف المفتاح.")
            }

            Section {
                Button("مسح كل التقدّم", role: .destructive) { confirmReset = true }
            }

            Section {
                HStack {
                    Text("الإصدار")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("الإعدادات")
        .confirmationDialog("سيتم حذف كل الكلمات والسجلات والأخطاء. هل أنت متأكد؟",
                            isPresented: $confirmReset, titleVisibility: .visible) {
            Button("مسح", role: .destructive, action: resetAll)
        }
        .sheet(isPresented: $showPlacement) {
            PlacementTestView(profile: profile, isRetake: true)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func testConnection() async {
        testing = true
        defer { testing = false }
        do {
            let reply = try await AIClient.shared.send(
                system: "Reply with a short friendly greeting in English (max 8 words).",
                messages: [ChatTurn(role: "user", content: "Hi")], maxTokens: 1000)
            testResult = "✅ يعمل: \(reply)"
        } catch {
            testResult = "❌ \(error.localizedDescription)"
        }
    }

    private func resetAll() {
        try? context.delete(model: WordCard.self)
        try? context.delete(model: ActivityLog.self)
        try? context.delete(model: MistakeRecord.self)
        try? context.delete(model: LessonCompletion.self)
        profile.xp = 0
        profile.streak = 0
        profile.longestStreak = 0
        profile.lastActiveDay = nil
        try? context.save()
    }
}
