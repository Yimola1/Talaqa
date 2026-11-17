import Foundation
import SwiftData

/// XP, streaks, activity logs and the personal mistake bank.
enum ProgressService {
    static func record(xp: Int, skill: Skill, score: Double? = nil, detail: String = "",
                       profile: UserProfile, context: ModelContext) {
        profile.xp += xp
        updateStreak(profile)
        context.insert(ActivityLog(skill: skill, xp: xp, score: score ?? -1, detail: detail))
        try? context.save()
    }

    static func updateStreak(_ profile: UserProfile, now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        if let last = profile.lastActiveDay {
            let lastDay = cal.startOfDay(for: last)
            if lastDay == today { return }
            let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            profile.streak = diff == 1 ? profile.streak + 1 : 1
        } else {
            profile.streak = 1
        }
        profile.longestStreak = max(profile.longestStreak, profile.streak)
        profile.lastActiveDay = now
    }

    /// The streak shown to the user: it is broken if the last active day is before yesterday.
    static func currentStreak(_ profile: UserProfile, now: Date = Date()) -> Int {
        guard let last = profile.lastActiveDay else { return 0 }
        let cal = Calendar.current
        let diff = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: now)).day ?? 0
        return diff <= 1 ? profile.streak : 0
    }

    static func recordMistake(skill: Skill, topic: String, wrong: String, correct: String,
                              explanation: String, context: ModelContext) {
        context.insert(MistakeRecord(skill: skill, topic: topic, wrong: wrong,
                                     correct: correct, explanation: explanation))
        try? context.save()
    }
}
