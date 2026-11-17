import Foundation

/// Grades a learner gives a flashcard.
enum Rating: Int, CaseIterable, Identifiable {
    case again = 1, hard = 2, good = 3, easy = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .again: return "لم أتذكّر"
        case .hard: return "صعب"
        case .good: return "جيد"
        case .easy: return "سهل"
        }
    }
}

enum CardState: Int, Codable {
    case new = 0, learning, review, relearning
}

struct SchedulingState {
    var stability: Double
    var difficulty: Double
    var due: Date
    var lastReview: Date?
    var reps: Int
    var lapses: Int
    var state: CardState
}

/// Free Spaced Repetition Scheduler (FSRS-5) with the published default parameters.
/// It models memory stability (S), difficulty (D) and retrievability (R) and picks
/// the next review so recall probability stays near `desiredRetention`.
struct FSRS {
    static let w: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046,
        1.54575, 0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315,
        2.9898, 0.51655, 0.6621
    ]
    static let decay = -0.5
    static let factor = 19.0 / 81.0

    var desiredRetention: Double = 0.9
    var maximumIntervalDays: Double = 3650
    /// Delay before a forgotten card comes back in the same session.
    var relearnDelay: TimeInterval = 10 * 60

    private var w: [Double] { Self.w }

    func retrievability(elapsedDays: Double, stability: Double) -> Double {
        guard stability > 0 else { return 0 }
        return pow(1 + Self.factor * elapsedDays / stability, Self.decay)
    }

    func intervalDays(for stability: Double) -> Double {
        let raw = stability / Self.factor * (pow(desiredRetention, 1 / Self.decay) - 1)
        return min(max(raw.rounded(), 1), maximumIntervalDays)
    }

    private func clampDifficulty(_ d: Double) -> Double { min(max(d, 1), 10) }

    private func initialStability(_ r: Rating) -> Double { max(w[r.rawValue - 1], 0.1) }

    private func initialDifficulty(_ r: Rating) -> Double {
        clampDifficulty(w[4] - exp(w[5] * Double(r.rawValue - 1)) + 1)
    }

    private func nextDifficulty(_ d: Double, _ r: Rating) -> Double {
        let delta = -w[6] * Double(r.rawValue - 3)
        let damped = d + delta * (10 - d) / 9
        let reverted = w[7] * initialDifficulty(.easy) + (1 - w[7]) * damped
        return clampDifficulty(reverted)
    }

    private func recallStability(d: Double, s: Double, r: Double, rating: Rating) -> Double {
        let hardPenalty = rating == .hard ? w[15] : 1
        let easyBonus = rating == .easy ? w[16] : 1
        let growth = exp(w[8]) * (11 - d) * pow(s, -w[9]) * (exp(w[10] * (1 - r)) - 1)
        return s * (growth * hardPenalty * easyBonus + 1)
    }

    private func forgetStability(d: Double, s: Double, r: Double) -> Double {
        let value = w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp(w[14] * (1 - r))
        return min(value, s)
    }

    private func shortTermStability(s: Double, rating: Rating) -> Double {
        s * exp(w[17] * (Double(rating.rawValue) - 3 + w[18]))
    }

    func schedule(_ current: SchedulingState, rating: Rating, now: Date = Date()) -> SchedulingState {
        var next = current
        let elapsed = current.lastReview.map { max(0, now.timeIntervalSince($0) / 86_400) } ?? 0

        if current.state == .new {
            next.stability = initialStability(rating)
            next.difficulty = initialDifficulty(rating)
        } else {
            let r = retrievability(elapsedDays: elapsed, stability: current.stability)
            next.difficulty = nextDifficulty(current.difficulty, rating)
            if elapsed < 1 {
                next.stability = shortTermStability(s: current.stability, rating: rating)
            } else if rating == .again {
                next.stability = forgetStability(d: current.difficulty, s: current.stability, r: r)
            } else {
                next.stability = recallStability(d: current.difficulty, s: current.stability, r: r, rating: rating)
            }
        }
        next.stability = max(next.stability, 0.1)
        next.reps += 1
        next.lastReview = now

        if rating == .again {
            if current.state == .review { next.lapses += 1 }
            next.state = (current.state == .new || current.state == .learning) ? .learning : .relearning
            next.due = now.addingTimeInterval(relearnDelay)
        } else {
            next.state = .review
            next.due = now.addingTimeInterval(intervalDays(for: next.stability) * 86_400)
        }
        return next
    }

    /// Short human-readable interval each button would produce, e.g. "١٠ د" or "٣ أيام".
    func previewLabels(for state: SchedulingState, now: Date = Date()) -> [Rating: String] {
        var out: [Rating: String] = [:]
        for r in Rating.allCases {
            let s = schedule(state, rating: r, now: now)
            out[r] = Self.format(interval: s.due.timeIntervalSince(now))
        }
        return out
    }

    static func format(interval: TimeInterval) -> String {
        let minutes = interval / 60
        if minutes < 60 { return "\(Int(minutes.rounded())) د" }
        let hours = minutes / 60
        if hours < 24 { return "\(Int(hours.rounded())) س" }
        let days = hours / 24
        if days < 30 { return "\(Int(days.rounded())) يوم" }
        let months = days / 30
        if months < 12 { return "\(Int(months.rounded())) شهر" }
        return String(format: "%.1f سنة", days / 365)
    }
}
