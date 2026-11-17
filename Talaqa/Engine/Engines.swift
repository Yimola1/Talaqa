import Foundation
import SwiftUI

// MARK: - Adaptive placement test

/// A simple computer-adaptive test: a correct answer raises the next question's
/// level, a wrong one lowers it. The estimate comes from where the staircase settles.
struct PlacementEngine {
    let questions: [PlacementQuestion]
    let total: Int
    private(set) var currentLevel: Int = 2
    private(set) var history: [(level: Int, correct: Bool)] = []
    private var used = Set<String>()

    init(questions: [PlacementQuestion], total: Int = 15) {
        self.questions = questions
        self.total = min(total, questions.count)
    }

    var answeredCount: Int { history.count }
    var isFinished: Bool { history.count >= total }

    mutating func nextQuestion() -> PlacementQuestion? {
        guard !isFinished else { return nil }
        for offset in [0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5] {
            let lvl = currentLevel + offset
            guard (0..<CEFRLevel.allCases.count).contains(lvl) else { continue }
            let pool = questions.filter { $0.level.index == lvl && !used.contains($0.id) }
            if let q = pool.randomElement() {
                used.insert(q.id)
                return q
            }
        }
        return nil
    }

    mutating func record(_ question: PlacementQuestion, correct: Bool) {
        history.append((question.level.index, correct))
        let maxIndex = CEFRLevel.allCases.count - 1
        currentLevel = correct ? min(question.level.index + 1, maxIndex) : max(question.level.index - 1, 0)
    }

    var estimatedLevel: CEFRLevel {
        let tail = history.suffix(8)
        guard !tail.isEmpty else { return .a1 }
        let sum = tail.reduce(0.0) { $0 + Double($1.level) + ($1.correct ? 0.5 : -0.5) }
        return CEFRLevel(index: Int((sum / Double(tail.count)).rounded()))
    }
}

// MARK: - Text matching (pronunciation & answers)

struct WordMatch: Identifiable {
    let id: Int
    let word: String
    let matched: Bool
}

enum TextMatcher {
    static func normalize(_ s: String) -> String {
        let lowered = s.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
        let kept = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "'" { return Character(scalar) }
            return " "
        }
        return String(kept).split(separator: " ").joined(separator: " ")
    }

    static func words(_ s: String) -> [String] {
        normalize(s).split(separator: " ").map(String.init)
    }

    /// Accepts any of the "|"-separated alternatives.
    static func matchesAnswer(_ input: String, _ answer: String) -> Bool {
        let given = normalize(input)
        guard !given.isEmpty else { return false }
        return answer.split(separator: "|").contains { normalize(String($0)) == given }
    }

    /// Word-level alignment (longest common subsequence) between the target
    /// sentence and what the speech recogniser heard.
    static func compare(target: String, spoken: String) -> (matches: [WordMatch], score: Double) {
        let display = target.split(separator: " ").map(String.init)
        let t = display.map { normalize($0) }
        let s = words(spoken)
        let n = t.count, m = s.count
        guard n > 0 else { return ([], 0) }

        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        if m > 0 {
            for i in 1...n {
                for j in 1...m {
                    dp[i][j] = t[i - 1] == s[j - 1] ? dp[i - 1][j - 1] + 1 : max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }
        var matched = Array(repeating: false, count: n)
        var i = n, j = m
        while i > 0 && j > 0 {
            if t[i - 1] == s[j - 1] {
                matched[i - 1] = true
                i -= 1; j -= 1
            } else if dp[i - 1][j] >= dp[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        let scorable = t.enumerated().filter { !$0.element.isEmpty }
        let hits = scorable.filter { matched[$0.offset] }.count
        let score = scorable.isEmpty ? 0 : Double(hits) / Double(scorable.count)
        let result = display.enumerated().map { WordMatch(id: $0.offset, word: $0.element, matched: matched[$0.offset] || t[$0.offset].isEmpty) }
        return (result, score)
    }
}

// MARK: - Daily plan

struct PlanTask: Identifiable {
    enum Kind {
        case vocab
        case grammar(GrammarLesson)
        case shadowing([ShadowingItem])
        case conversation(Scenario)
        case reading(Story)
        case dictation(CEFRLevel)
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let done: Bool
}

enum DailyPlanner {
    static func newWordsTarget(minutes: Int) -> Int {
        switch minutes {
        case ..<6: return 5
        case ..<11: return 7
        case ..<16: return 10
        default: return 12
        }
    }

    static func makePlan(profile: UserProfile, dueCount: Int, newLearnedToday: Int,
                         completedLessons: Set<String>, doneSkills: Set<Skill>,
                         content: ContentStore = .shared, now: Date = Date()) -> [PlanTask] {
        var tasks: [PlanTask] = []
        let day = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
        let ceiling = profile.level.next
        let newLeft = max(0, newWordsTarget(minutes: profile.dailyMinutes) - newLearnedToday)

        tasks.append(PlanTask(
            id: "vocab", kind: .vocab, title: "بطاقات المفردات",
            subtitle: "\(dueCount) للمراجعة • \(newLeft) كلمات جديدة",
            icon: "rectangle.stack.fill", color: .blue,
            done: dueCount == 0 && newLeft == 0))

        if let lesson = content.nextLesson(for: profile.level, completed: completedLessons) {
            tasks.append(PlanTask(
                id: "grammar-\(lesson.id)", kind: .grammar(lesson), title: lesson.titleAr,
                subtitle: "درس قواعد • \(lesson.level.rawValue)",
                icon: "text.book.closed.fill", color: .purple,
                done: doneSkills.contains(.grammar)))
        }

        let groups = content.shadowingGroups(upTo: ceiling)
        if !groups.isEmpty {
            let group = groups[day % groups.count]
            tasks.append(PlanTask(
                id: "shadow-\(group.focus)", kind: .shadowing(Array(group.items.prefix(4))),
                title: "تدريب النطق: \(group.focusAr)", subtitle: "اسمع ثم كرّر • تقييم فوري",
                icon: "waveform", color: .orange,
                done: doneSkills.contains(.speaking)))
        }

        let scenarios = content.scenarios.filter { $0.level <= ceiling }
        if !scenarios.isEmpty {
            let s = scenarios[day % scenarios.count]
            tasks.append(PlanTask(
                id: "chat-\(s.id)", kind: .conversation(s),
                title: "محادثة: \(s.titleAr) \(s.emoji)", subtitle: "مع المعلّم الذكي",
                icon: "bubble.left.and.bubble.right.fill", color: .green,
                done: doneSkills.contains(.writing)))
        }

        if profile.dailyMinutes >= 15 || day % 2 == 1 {
            tasks.append(PlanTask(
                id: "dictation", kind: .dictation(profile.level),
                title: "تمرين الإملاء والاستماع", subtitle: "استمع واكتب ما تسمعه",
                icon: "ear.fill", color: .pink,
                done: doneSkills.contains(.listening)))
        }

        if profile.dailyMinutes >= 15 || day % 2 == 0 {
            let stories = content.stories.filter { $0.level <= ceiling }
            if !stories.isEmpty {
                let st = stories[(day / 2) % stories.count]
                tasks.append(PlanTask(
                    id: "read-\(st.id)", kind: .reading(st),
                    title: "قراءة: \(st.titleAr)", subtitle: "قصة قصيرة • \(st.level.rawValue)",
                    icon: "book.pages.fill", color: .teal,
                    done: doneSkills.contains(.reading)))
            }
        }
        return tasks
    }
}
