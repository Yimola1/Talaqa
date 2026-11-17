import SwiftUI
import SwiftData

// MARK: - Tutor home

struct TutorHomeView: View {
    @Bindable var profile: UserProfile
    @State private var configured = AIClient.shared.isConfigured
    @Query(filter: #Predicate<MistakeRecord> { !$0.resolved }, sort: \MistakeRecord.date, order: .reverse)
    private var openMistakes: [MistakeRecord]

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !configured {
                    NavigationLink {
                        SettingsView(profile: profile)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill").font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("فعّل المعلّم الذكي").font(.headline)
                                Text("أضف رابط الخادم أو مفتاح Claude API من الإعدادات.").font(.subheadline)
                            }
                            Spacer()
                            Image(systemName: "chevron.left")
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.orange.gradient, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    WritingCoachView(profile: profile)
                } label: {
                    featureRow(icon: "pencil.and.list.clipboard", color: .indigo,
                               title: "مدرّب الكتابة", subtitle: "اكتب نصاً واحصل على تصحيح وتقييم مفصّل")
                }
                .buttonStyle(.plain)

                if !openMistakes.isEmpty {
                    NavigationLink {
                        TutorChatView(scenario: Self.mistakeReview(openMistakes), profile: profile)
                    } label: {
                        featureRow(icon: "arrow.triangle.2.circlepath", color: .red,
                                   title: "راجع أخطائي مع المعلّم",
                                   subtitle: "تمارين موجّهة على \(min(openMistakes.count, 8)) من أخطائك الأخيرة")
                    }
                    .buttonStyle(.plain)
                }

                Text("مواقف للمحادثة").font(.title2.bold()).padding(.top, 6)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ContentStore.shared.scenarios) { s in
                        NavigationLink {
                            TutorChatView(scenario: s, profile: profile)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(s.emoji).font(.largeTitle)
                                Text(s.titleAr).font(.headline).lineLimit(2).multilineTextAlignment(.leading)
                                LevelBadge(level: s.level)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                            .cardStyle(padding: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationTitle("المعلّم الذكي")
        .onAppear { configured = AIClient.shared.isConfigured }
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.left").foregroundStyle(.secondary)
        }
        .cardStyle(padding: 12)
    }

    static func mistakeReview(_ mistakes: [MistakeRecord]) -> Scenario {
        let list = mistakes.prefix(8).map { m in
            "- wrong: \"\(m.wrong)\" → correct: \"\(m.correct)\" (topic: \(m.topic))"
        }.joined(separator: "\n")
        return Scenario(
            id: "mistake-review", title: "Mistake review", titleAr: "مراجعة أخطائي", emoji: "🎯",
            level: .a1,
            setting: "A focused practice session on the learner's recent mistakes:\n\(list)",
            aiRole: "a patient tutor. Work through the mistakes one at a time: briefly explain the rule in simple English, then ask the learner to produce a new sentence that uses the correct form. Move on once they get it right.",
            opening: "Hi! Let's practise a few things you found tricky recently. Ready for the first one?",
            goalsAr: ["فهم سبب كل خطأ", "استخدام الصيغة الصحيحة في جملة جديدة"])
    }
}

// MARK: - Chat

struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
    var feedback: [FeedbackLine] = []
}

struct TutorChatView: View {
    let scenario: Scenario
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @AppStorage("autoSpeak") private var autoSpeak = true

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var sending = false
    @State private var errorText: String?
    @State private var recognizer = SpeechRecognizer()
    @State private var usedVoice = false
    @State private var showGoals = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if showGoals { goalsCard }
                        ForEach(messages) { msg in
                            MessageBubble(message: msg).id(msg.id)
                        }
                        if sending {
                            HStack { ProgressView(); Text("المعلّم يكتب…").foregroundStyle(.secondary) }
                                .padding(.horizontal).id("typing")
                        }
                        if let errorText {
                            Text(errorText).font(.footnote).foregroundStyle(.red).padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
            inputBar
        }
        .background(Theme.pageBackground)
        .navigationTitle("\(scenario.emoji) \(scenario.titleAr)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    autoSpeak.toggle()
                } label: {
                    Image(systemName: autoSpeak ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
            }
        }
        .onAppear {
            if messages.isEmpty {
                messages.append(ChatMessage(role: .assistant, text: scenario.opening))
                if autoSpeak { SpeechService.shared.speak(scenario.opening) }
            }
            recognizer.onFinish = { text in
                if !text.isEmpty { input = text }
            }
        }
        .onChange(of: recognizer.transcript) { _, newValue in
            if recognizer.isRecording { input = newValue }
        }
        .onDisappear {
            recognizer.stop()
            SpeechService.shared.stop()
        }
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("أهداف المحادثة").font(.headline)
                Spacer()
                Button { withAnimation { showGoals = false } } label: { Image(systemName: "xmark") }
                    .foregroundStyle(.secondary)
            }
            ForEach(scenario.goalsAr, id: \.self) { g in
                Label(g, systemImage: "checkmark.circle").font(.subheadline)
            }
            Text("تحدّث بالإنجليزية بالضغط على الميكروفون، أو اكتب. سيصحّح المعلّم أخطاءك تحت كل رسالة.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            if let err = recognizer.errorMessage {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            HStack(spacing: 10) {
                Button {
                    Task { await toggleMic() }
                } label: {
                    Image(systemName: recognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(recognizer.isRecording ? .red : Theme.primary)
                        .symbolEffect(.pulse, isActive: recognizer.isRecording)
                }
                TextField("Type in English…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .ltr()
                Button {
                    Task { await suggest() }
                } label: {
                    Image(systemName: "lightbulb.fill").font(.title3).foregroundStyle(.yellow)
                }
                .disabled(sending)
                .accessibilityLabel("اقترح رداً")
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 34))
                }
                .disabled(sending || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func toggleMic() async {
        if recognizer.isRecording {
            recognizer.stop()
            return
        }
        guard await SpeechRecognizer.requestPermissions() else {
            recognizer.errorMessage = "يرجى السماح بالميكروفون والتعرّف على الكلام من إعدادات الآيفون."
            return
        }
        usedVoice = true
        recognizer.start()
    }

    private func turns() -> [ChatTurn] {
        var result = [ChatTurn(role: "user", content: "(start)")]
        for m in messages {
            result.append(ChatTurn(role: m.role == .user ? "user" : "assistant", content: m.text))
        }
        return result
    }

    private func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !sending else { return }
        if recognizer.isRecording { recognizer.stop() }
        input = ""
        errorText = nil
        messages.append(ChatMessage(role: .user, text: text))
        let userIndex = messages.count - 1
        sending = true
        defer { sending = false }

        do {
            let raw = try await AIClient.shared.send(
                system: TutorPrompts.conversationSystem(scenario: scenario, profile: profile),
                messages: turns())
            let parsed = TutorPrompts.parseConversation(raw)
            messages[userIndex].feedback = parsed.feedback
            messages.append(ChatMessage(role: .assistant, text: parsed.reply))
            if autoSpeak { SpeechService.shared.speak(parsed.reply) }

            let skill: Skill = usedVoice ? .speaking : .writing
            for f in parsed.feedback where f.kind == .error {
                ProgressService.recordMistake(skill: skill, topic: scenario.title, wrong: f.wrong,
                                              correct: f.correct, explanation: f.note, context: context)
            }
            let errors = parsed.feedback.filter { $0.kind == .error }.count
            ProgressService.record(xp: errors == 0 ? 6 : 4, skill: skill,
                                   score: errors == 0 ? 1 : max(0, 1 - Double(errors) * 0.25),
                                   detail: scenario.title, profile: profile, context: context)
            usedVoice = false
        } catch {
            errorText = error.localizedDescription
            messages.remove(at: userIndex)
            input = text
        }
    }

    private func suggest() async {
        sending = true
        defer { sending = false }
        do {
            let s = try await AIClient.shared.send(
                system: TutorPrompts.suggestionSystem(scenario: scenario, profile: profile),
                messages: turns() + [ChatTurn(role: "user", content: "(Suggest my next reply.)")],
                maxTokens: 1000)
            input = s.trimmingCharacters(in: CharacterSet(charactersIn: "\"“” \n"))
        } catch {
            errorText = error.localizedDescription
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    @State private var showFeedback = true

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 6) {
                if message.role == .user { Spacer(minLength: 40) }
                Text(message.text)
                    .padding(12)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .background(message.role == .user ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.cardBackground),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .textSelection(.enabled)
                if message.role == .assistant {
                    SpeakButton(text: message.text, size: 13)
                    Spacer(minLength: 30)
                }
            }
            .ltr()

            if !message.feedback.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(message.feedback) { f in
                        switch f.kind {
                        case .error:
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(f.wrong).strikethrough().foregroundStyle(.red)
                                    Image(systemName: "arrow.right").font(.caption)
                                    Text(f.correct).foregroundStyle(.green).bold()
                                }
                                .ltr()
                                if !f.note.isEmpty { Text(f.note).font(.caption).foregroundStyle(.secondary) }
                            }
                        case .tip:
                            VStack(alignment: .leading, spacing: 2) {
                                Text("💡 \(f.correct)").ltr()
                                if !f.note.isEmpty { Text(f.note).font(.caption).foregroundStyle(.secondary) }
                            }
                        case .praise:
                            Text("🌟 \(f.note.isEmpty ? "ممتاز!" : f.note)").foregroundStyle(.green)
                        }
                    }
                }
                .font(.subheadline)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// MARK: - Writing coach

struct WritingCoachView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    @State private var taskIndex = 0
    @State private var text = ""
    @State private var loading = false
    @State private var review: TutorPrompts.WritingReview?
    @State private var errorText: String?

    private var tasks: [String] { TutorPrompts.writingTasks(for: profile) }
    private var wordCount: Int { text.split { $0.isWhitespace || $0.isNewline }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("المهمة").font(.headline)
                        Spacer()
                        Button("مهمة أخرى") {
                            taskIndex = (taskIndex + 1) % tasks.count
                        }
                        .font(.subheadline)
                    }
                    Text(tasks[taskIndex]).font(.body.weight(.medium)).ltr()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .cardStyle()

                TextEditor(text: $text)
                    .frame(minHeight: 200)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                    .ltr()
                HStack {
                    Text("\(wordCount) كلمة").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }

                Button {
                    Task { await evaluate() }
                } label: {
                    if loading { ProgressView().tint(.white) } else { Text("صحّح وقيّم ✨") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(loading || wordCount < 5)

                if let errorText {
                    Text(errorText).foregroundStyle(.red).font(.footnote)
                }
                if let review { reviewView(review) }
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationTitle("مدرّب الكتابة")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func reviewView(_ r: TutorPrompts.WritingReview) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: Double(r.score) / 100, lineWidth: 8, color: Theme.primary)
                    Text("\(r.score)").font(.title2.bold())
                }
                .frame(width: 70, height: 70)
                VStack(alignment: .leading) {
                    Text("المستوى التقديري: \(r.cefr)").font(.headline)
                    Text(r.feedbackAr).font(.subheadline)
                }
            }
            .cardStyle()

            if !r.mistakes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("الأخطاء").font(.headline)
                    ForEach(r.mistakes, id: \.self) { m in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Text(m.wrong).strikethrough().foregroundStyle(.red)
                                Image(systemName: "arrow.right").font(.caption)
                                Text(m.correct).foregroundStyle(.green).bold()
                            }
                            .ltr()
                            Text(m.explanationAr).font(.caption).foregroundStyle(.secondary)
                        }
                        Divider()
                    }
                }
                .cardStyle()
            }

            textBlock(title: "النص بعد التصحيح", body: r.corrected)
            textBlock(title: "نسخة أكثر طلاقة", body: r.betterVersion)
        }
    }

    private func textBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                SpeakButton(text: body, size: 14)
            }
            Text(body).ltr().frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
        }
        .cardStyle()
    }

    private func evaluate() async {
        loading = true
        errorText = nil
        defer { loading = false }
        do {
            let raw = try await AIClient.shared.send(
                system: TutorPrompts.writingSystem(profile: profile),
                messages: [ChatTurn(role: "user", content: "Task: \(tasks[taskIndex])\n\nMy text:\n\(text)")],
                maxTokens: 8000, effort: "medium")
            guard let r = TutorPrompts.parseWriting(raw) else {
                errorText = "تعذّرت قراءة التقييم، حاول مرة أخرى."
                return
            }
            withAnimation { review = r }
            for m in r.mistakes {
                ProgressService.recordMistake(skill: .writing, topic: "كتابة", wrong: m.wrong,
                                              correct: m.correct, explanation: m.explanationAr, context: context)
            }
            ProgressService.record(xp: 15 + min(wordCount / 10, 15), skill: .writing,
                                   score: Double(r.score) / 100, detail: "مدرّب الكتابة",
                                   profile: profile, context: context)
        } catch {
            errorText = error.localizedDescription
        }
    }
}
