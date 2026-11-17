import Foundation

struct FeedbackLine: Identifiable, Hashable {
    enum Kind { case error, tip, praise }
    let id = UUID()
    let kind: Kind
    let wrong: String
    let correct: String
    let note: String
}

/// Prompt templates and response parsing for the AI tutor.
enum TutorPrompts {
    static let feedbackMarker = "---FEEDBACK---"

    static func learnerLine(_ profile: UserProfile) -> String {
        "The learner is a native Arabic speaker named \(profile.displayName), level \(profile.level.englishDescription), focusing on \(profile.goal.promptDescription)."
    }

    static func conversationSystem(scenario: Scenario, profile: UserProfile) -> String {
        """
        You are "Talaqa", a warm, encouraging English tutor running a spoken role-play.
        \(learnerLine(profile))

        Scenario: \(scenario.setting)
        Your role: \(scenario.aiRole)

        Reply format:
        1. First, stay in character and reply in natural English the learner can follow, just slightly above their level. Keep it to 1–3 short sentences and end with a question or prompt that keeps the conversation moving.
        2. Then output a line containing exactly \(feedbackMarker)
        3. After that line, review ONLY the learner's most recent message:
           - For each real error (max 3), one line: ❌ <wrong phrase> → ✅ <corrected phrase> | <very short explanation in Arabic>
           - If there were no errors but it could sound more natural, one line: 💡 <more natural version> | <short note in Arabic>
           - If it was already natural and correct, one line: 🌟 ممتاز!
        If the learner's message is the role-play kick-off "(start)", output only 🌟 after the marker.
        Pay special attention to errors typical of Arabic speakers: articles (a/an/the), the verb "to be", present perfect, prepositions, word order of adjectives, and p/b or v/f spelling confusions.
        """
    }

    static func suggestionSystem(scenario: Scenario, profile: UserProfile) -> String {
        """
        You help an English learner in a role-play. \(learnerLine(profile))
        Scenario: \(scenario.setting)
        Write ONE short, natural reply the learner could say next, at their level. Output only the reply sentence, nothing else.
        """
    }

    static func writingSystem(profile: UserProfile) -> String {
        """
        You are an expert English writing coach for Arabic-speaking learners. \(learnerLine(profile))
        Evaluate the learner's text and respond with ONLY a JSON object (no markdown, no code fences) with exactly these keys:
        {"score": <integer 0-100>, "cefr": "<estimated CEFR level of this text>", "feedbackAr": "<2-3 encouraging sentences in Arabic: strengths and the top priority to improve>", "mistakes": [{"wrong": "<exact wrong phrase>", "correct": "<correction>", "explanationAr": "<short Arabic explanation>"}], "corrected": "<the full text with minimal corrections>", "betterVersion": "<a more natural, slightly more advanced rewrite>"}
        List at most 8 mistakes, the most important first.
        """
    }

    struct ParsedReply {
        let reply: String
        let feedback: [FeedbackLine]
    }

    static func parseConversation(_ raw: String) -> ParsedReply {
        let parts = raw.components(separatedBy: feedbackMarker)
        let reply = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? raw
        guard parts.count > 1 else { return ParsedReply(reply: reply, feedback: []) }

        var lines: [FeedbackLine] = []
        for rawLine in parts[1].split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("❌") {
                let body = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                let noteSplit = body.components(separatedBy: "|")
                let pair = noteSplit[0].components(separatedBy: "→")
                let wrong = pair[0].trimmingCharacters(in: .whitespaces)
                let correct = pair.count > 1
                    ? pair[1].replacingOccurrences(of: "✅", with: "").trimmingCharacters(in: .whitespaces)
                    : ""
                let note = noteSplit.count > 1 ? noteSplit[1].trimmingCharacters(in: .whitespaces) : ""
                lines.append(FeedbackLine(kind: .error, wrong: wrong, correct: correct, note: note))
            } else if line.hasPrefix("💡") {
                let body = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                let noteSplit = body.components(separatedBy: "|")
                let note = noteSplit.count > 1 ? noteSplit[1].trimmingCharacters(in: .whitespaces) : ""
                lines.append(FeedbackLine(kind: .tip, wrong: "", correct: noteSplit[0].trimmingCharacters(in: .whitespaces), note: note))
            } else if line.hasPrefix("🌟") {
                lines.append(FeedbackLine(kind: .praise, wrong: "", correct: "", note: String(line.dropFirst()).trimmingCharacters(in: .whitespaces)))
            }
        }
        return ParsedReply(reply: reply, feedback: lines)
    }

    struct WritingReview: Decodable {
        struct Mistake: Decodable, Hashable {
            let wrong: String
            let correct: String
            let explanationAr: String
        }
        let score: Int
        let cefr: String
        let feedbackAr: String
        let mistakes: [Mistake]
        let corrected: String
        let betterVersion: String
    }

    static func parseWriting(_ raw: String) -> WritingReview? {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") else { return nil }
        let json = String(raw[start...end])
        return try? JSONDecoder().decode(WritingReview.self, from: Data(json.utf8))
    }

    static func writingTasks(for profile: UserProfile) -> [String] {
        let base: [String]
        switch profile.goal {
        case .travel:
            base = ["Write an email to a hotel asking about your booking and airport transfer.",
                    "Describe the best trip you have ever taken.",
                    "Write a short review of a restaurant you visited."]
        case .work:
            base = ["Write an email to your manager asking for a day off next week.",
                    "Introduce yourself and your job in a professional way.",
                    "Write a short summary of a project you worked on and its results."]
        case .ielts:
            base = ["Some people think university education should be free. Discuss both views and give your opinion.",
                    "Describe a skill you would like to learn and explain why.",
                    "The chart shows a rise in online shopping. Explain possible reasons for this trend."]
        case .study:
            base = ["Describe your field of study and why you chose it.",
                    "Write a paragraph about the advantages and disadvantages of online learning.",
                    "Summarise an interesting article or book you read recently."]
        case .general:
            base = ["Describe your daily routine.",
                    "Write about your favourite place in your city and why you like it.",
                    "Tell a short story about a funny thing that happened to you."]
        }
        return base
    }
}
