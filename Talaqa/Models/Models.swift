import Foundation
import SwiftData

// MARK: - Enums

enum CEFRLevel: String, Codable, CaseIterable, Identifiable, Comparable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1", c2 = "C2"

    var id: String { rawValue }
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    init(index: Int) {
        let all = Self.allCases
        self = all[min(max(index, 0), all.count - 1)]
    }

    static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool { lhs.index < rhs.index }

    var next: CEFRLevel { CEFRLevel(index: index + 1) }

    var arabicName: String {
        switch self {
        case .a1: return "مبتدئ"
        case .a2: return "أساسي"
        case .b1: return "متوسط"
        case .b2: return "فوق المتوسط"
        case .c1: return "متقدّم"
        case .c2: return "متمكّن"
        }
    }

    var englishDescription: String {
        switch self {
        case .a1: return "A1 (beginner)"
        case .a2: return "A2 (elementary)"
        case .b1: return "B1 (intermediate)"
        case .b2: return "B2 (upper-intermediate)"
        case .c1: return "C1 (advanced)"
        case .c2: return "C2 (proficient)"
        }
    }
}

enum LearningGoal: String, Codable, CaseIterable, Identifiable {
    case general, travel, work, ielts, study

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "تحسين لغتي عموماً"
        case .travel: return "السفر والسياحة"
        case .work: return "العمل والوظيفة"
        case .ielts: return "التحضير لـ IELTS / TOEFL"
        case .study: return "الدراسة والجامعة"
        }
    }

    var icon: String {
        switch self {
        case .general: return "globe"
        case .travel: return "airplane"
        case .work: return "briefcase.fill"
        case .ielts: return "graduationcap.fill"
        case .study: return "books.vertical.fill"
        }
    }

    var promptDescription: String {
        switch self {
        case .general: return "general everyday English"
        case .travel: return "English for travel"
        case .work: return "professional / workplace English"
        case .ielts: return "IELTS / TOEFL exam preparation"
        case .study: return "academic English for university"
        }
    }
}

enum Skill: String, Codable, CaseIterable, Identifiable {
    case vocabulary, grammar, speaking, listening, reading, writing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vocabulary: return "المفردات"
        case .grammar: return "القواعد"
        case .speaking: return "التحدث"
        case .listening: return "الاستماع"
        case .reading: return "القراءة"
        case .writing: return "الكتابة"
        }
    }

    var icon: String {
        switch self {
        case .vocabulary: return "rectangle.stack.fill"
        case .grammar: return "text.book.closed.fill"
        case .speaking: return "mic.fill"
        case .listening: return "ear.fill"
        case .reading: return "book.pages.fill"
        case .writing: return "pencil.line"
        }
    }
}

// MARK: - Persistent models

@Model
final class UserProfile {
    var name: String = ""
    var levelRaw: String = CEFRLevel.a1.rawValue
    var goalRaw: String = LearningGoal.general.rawValue
    var dailyMinutes: Int = 10
    var xp: Int = 0
    var streak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDay: Date? = nil
    var onboardingDone: Bool = false
    var placementDone: Bool = false
    var createdAt: Date = Date()

    init() {}

    var level: CEFRLevel {
        get { CEFRLevel(rawValue: levelRaw) ?? .a1 }
        set { levelRaw = newValue.rawValue }
    }

    var goal: LearningGoal {
        get { LearningGoal(rawValue: goalRaw) ?? .general }
        set { goalRaw = newValue.rawValue }
    }

    /// Daily XP target derived from the chosen study time.
    var dailyXPGoal: Int { max(30, dailyMinutes * 10) }

    var displayName: String { name.isEmpty ? "صديقي" : name }
}

@Model
final class WordCard {
    @Attribute(.unique) var wordID: String
    var word: String
    var meaningAr: String
    var example: String
    var exampleAr: String
    var ipa: String
    var levelRaw: String

    // FSRS scheduling state
    var stability: Double = 0
    var difficulty: Double = 0
    var due: Date = Date()
    var lastReview: Date? = nil
    var reps: Int = 0
    var lapses: Int = 0
    var stateRaw: Int = 0
    var createdAt: Date = Date()

    init(wordID: String, word: String, meaningAr: String, example: String,
         exampleAr: String, ipa: String, level: CEFRLevel) {
        self.wordID = wordID
        self.word = word
        self.meaningAr = meaningAr
        self.example = example
        self.exampleAr = exampleAr
        self.ipa = ipa
        self.levelRaw = level.rawValue
    }

    convenience init(item: VocabItem) {
        self.init(wordID: item.id, word: item.word, meaningAr: item.meaningAr,
                  example: item.example, exampleAr: item.exampleAr,
                  ipa: item.ipa, level: item.level)
    }

    var state: CardState { CardState(rawValue: stateRaw) ?? .new }

    var schedulingState: SchedulingState {
        get {
            SchedulingState(stability: stability, difficulty: difficulty, due: due,
                            lastReview: lastReview, reps: reps, lapses: lapses,
                            state: CardState(rawValue: stateRaw) ?? .new)
        }
        set {
            stability = newValue.stability
            difficulty = newValue.difficulty
            due = newValue.due
            lastReview = newValue.lastReview
            reps = newValue.reps
            lapses = newValue.lapses
            stateRaw = newValue.state.rawValue
        }
    }

    /// A card is "mastered" once its memory stability exceeds three weeks.
    var isMastered: Bool { stability >= 21 }
}

@Model
final class ActivityLog {
    var date: Date = Date()
    var skillRaw: String = Skill.vocabulary.rawValue
    var xp: Int = 0
    /// 0...1, or -1 when no score applies.
    var score: Double = -1
    var detail: String = ""

    init(skill: Skill, xp: Int, score: Double, detail: String) {
        self.skillRaw = skill.rawValue
        self.xp = xp
        self.score = score
        self.detail = detail
    }

    var skill: Skill { Skill(rawValue: skillRaw) ?? .vocabulary }
}

@Model
final class MistakeRecord {
    var date: Date = Date()
    var skillRaw: String = Skill.grammar.rawValue
    var topic: String = ""
    var wrong: String = ""
    var correct: String = ""
    var explanation: String = ""
    var resolved: Bool = false

    init(skill: Skill, topic: String, wrong: String, correct: String, explanation: String) {
        self.skillRaw = skill.rawValue
        self.topic = topic
        self.wrong = wrong
        self.correct = correct
        self.explanation = explanation
    }

    var skill: Skill { Skill(rawValue: skillRaw) ?? .grammar }
}

@Model
final class LessonCompletion {
    var lessonID: String = ""
    var score: Double = 0
    var date: Date = Date()

    init(lessonID: String, score: Double) {
        self.lessonID = lessonID
        self.score = score
    }
}
