import Foundation
import UserNotifications

enum NotificationService {
    static let dailyID = "talaqa.daily.reminder"

    @discardableResult
    static func requestAndSchedule(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted { schedule(hour: hour, minute: minute) }
        return granted
    }

    static func schedule(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])

        let content = UNMutableNotificationContent()
        content.title = "حان وقت الإنجليزي ✨"
        content.body = "بضع دقائق اليوم تحافظ على سلسلتك 🔥 كلماتك بانتظار المراجعة."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyID])
    }
}
