import Foundation

struct VocabItem: Codable, Identifiable, Hashable {
    let id: String
    let word: String
    let ipa: String
    let pos: String
    let meaningAr: String
    let example: String
    let exampleAr: String
    let topic: String
    let level: CEFRLevel
}

struct LessonSection: Codable, Hashable {
    let headingAr: String
    let bodyAr: String
    let examples: [String]
}

enum ExerciseKind: String, Codable {
    case multipleChoice, fillBlank, reorder
}

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let kind: ExerciseKind
    let prompt: String
    let promptAr: String?
    let options: [String]?
    /// For fillBlank, alternatives are separated by "|".
    let answer: String
    let explanationAr: String
}

struct GrammarLesson: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let titleAr: String
    let level: CEFRLevel
    let summaryAr: String
    let sections: [LessonSection]
    let arabicTip: String?
    let exercises: [Exercise]
}

struct PlacementQuestion: Codable, Identifiable, Hashable {
    let id: String
    let level: CEFRLevel
    let prompt: String
    let options: [String]
    let answer: Int
}

struct Scenario: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let titleAr: String
    let emoji: String
    let level: CEFRLevel
    let setting: String
    let aiRole: String
    let opening: String
    let goalsAr: [String]
}

struct Story: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let titleAr: String
    let level: CEFRLevel
    let paragraphs: [String]
    let glossary: [String: String]
    let questions: [Exercise]
}

struct ShadowingItem: Codable, Identifiable, Hashable {
    let id: String
    let text: String
    let focus: String
    let focusAr: String
    let tipAr: String
    let level: CEFRLevel
}
