import SwiftUI
import SwiftData

struct LearnView: View {
    @Bindable var profile: UserProfile
    @Query private var completions: [LessonCompletion]
    @Query private var cards: [WordCard]

    private var completed: Set<String> { Set(completions.map(\.lessonID)) }

    var body: some View {
        List {
            Section("المفردات") {
                NavigationLink {
                    VocabSessionView(profile: profile)
                } label: {
                    Label("جلسة مراجعة وكلمات جديدة", systemImage: "rectangle.stack.fill")
                }
                NavigationLink {
                    VocabBrowserView()
                } label: {
                    Label("بنك كلماتي (\(cards.count))", systemImage: "books.vertical.fill")
                }
            }

            Section("القواعد") {
                ForEach(CEFRLevel.allCases) { level in
                    let lessons = ContentStore.shared.lessons.filter { $0.level == level }
                    if !lessons.isEmpty {
                        DisclosureGroup {
                            ForEach(lessons) { lesson in
                                NavigationLink {
                                    GrammarLessonView(lesson: lesson, profile: profile)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(lesson.titleAr)
                                            Text(lesson.title).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if completed.contains(lesson.id) {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                LevelBadge(level: level)
                                Text(level.arabicName)
                                Spacer()
                                Text("\(lessons.filter { completed.contains($0.id) }.count)/\(lessons.count)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("القراءة والاستماع") {
                NavigationLink {
                    DictationView(level: profile.level, profile: profile)
                } label: {
                    Label("تمرين الإملاء (استمع واكتب)", systemImage: "ear.fill")
                }
                ForEach(ContentStore.shared.stories) { story in
                    NavigationLink {
                        StoryView(story: story, profile: profile)
                    } label: {
                        HStack {
                            LevelBadge(level: story.level)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(story.titleAr)
                                Text(story.title).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("المراجعة") {
                NavigationLink {
                    MistakesView(profile: profile)
                } label: {
                    Label("أخطائي الشائعة", systemImage: "exclamationmark.bubble.fill")
                }
            }
        }
        .navigationTitle("تعلّم")
    }
}

private struct SelectedWord: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String?
    let sentence: String
}

struct StoryView: View {
    let story: Story
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var selected: SelectedWord?
    @State private var showTranslationHint = true
    @State private var addedWords: Set<String> = []

    private var glossary: [String: String] {
        Dictionary(uniqueKeysWithValues: story.glossary.map { ($0.key.lowercased(), $0.value) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    LevelBadge(level: story.level)
                    Spacer()
                    Button {
                        SpeechService.shared.speak(story.paragraphs.joined(separator: " "))
                    } label: {
                        Label("اقرأها لي", systemImage: "play.circle.fill")
                    }
                    Button {
                        SpeechService.shared.stop()
                    } label: {
                        Image(systemName: "stop.circle")
                    }
                }
                Text(story.title).font(.largeTitle.bold()).ltr()
                    .frame(maxWidth: .infinity, alignment: .leading)
                if showTranslationHint {
                    Text("اضغط على أي كلمة لسماعها. الكلمات المظلّلة لها ترجمة ويمكنك إضافتها لبطاقاتك.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                ForEach(Array(story.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    paragraphView(paragraph)
                }

                NavigationLink {
                    ExerciseSessionView(title: "أسئلة الفهم", exercises: story.questions,
                                        skill: .reading, topic: story.title, profile: profile)
                } label: {
                    Text("أسئلة الفهم (\(story.questions.count))")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { sel in
            wordSheet(sel)
                .presentationDetents([.height(280)])
                .environment(\.layoutDirection, .rightToLeft)
        }
        .onDisappear { SpeechService.shared.stop() }
    }

    private func paragraphView(_ paragraph: String) -> some View {
        let tokens = paragraph.split(separator: " ").map(String.init)
        return FlowLayout(spacing: 5, lineSpacing: 8) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                let key = TextMatcher.normalize(token)
                let meaning = glossary[key]
                Text(token)
                    .font(.title3)
                    .padding(.horizontal, meaning == nil ? 0 : 3)
                    .background(meaning == nil ? Color.clear : Color.yellow.opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 4))
                    .onTapGesture {
                        SpeechService.shared.speak(key)
                        showTranslationHint = false
                        selected = SelectedWord(word: key, meaning: meaning, sentence: sentence(containing: token, in: paragraph))
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .ltr()
    }

    private func sentence(containing token: String, in paragraph: String) -> String {
        let sentences = paragraph.split(whereSeparator: { ".!?".contains($0) })
        let found = sentences.first { $0.contains(token.trimmingCharacters(in: .punctuationCharacters)) }
        return found.map { $0.trimmingCharacters(in: .whitespaces) + "." } ?? paragraph
    }

    private func wordSheet(_ sel: SelectedWord) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text(sel.word).font(.largeTitle.bold()).ltr()
                SpeakButton(text: sel.word)
                SpeakButton(text: sel.word, slow: true)
            }
            if let meaning = sel.meaning {
                Text(meaning).font(.title2).foregroundStyle(Theme.primary)
                if addedWords.contains(sel.word) {
                    Label("أُضيفت إلى بطاقاتك", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    Button {
                        addCard(sel, meaning: meaning)
                    } label: {
                        Label("أضف إلى بطاقات المراجعة", systemImage: "plus.rectangle.on.rectangle")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            } else {
                Text("اضغط على الكلمات المظلّلة لرؤية معناها.").foregroundStyle(.secondary)
            }
        }
        .padding(24)
    }

    private func addCard(_ sel: SelectedWord, meaning: String) {
        let word = sel.word
        let id = "story-\(word)"
        var descriptor = FetchDescriptor<WordCard>(predicate: #Predicate<WordCard> { $0.word == word || $0.wordID == id })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            addedWords.insert(word)
            return
        }
        context.insert(WordCard(wordID: id, word: word, meaningAr: meaning, example: sel.sentence,
                                exampleAr: "", ipa: "", level: story.level))
        try? context.save()
        addedWords.insert(word)
    }
}
