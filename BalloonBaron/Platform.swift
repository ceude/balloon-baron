import GameKit
import UIKit
import UserNotifications
import BalloonBaronCore

/// Game Center: sign-in at launch, every postcard as an achievement, two leaderboards. Without the Game Center
/// capability, or when the player declines, every call quietly does nothing.
enum GameCenter {
    /// App Store Connect ids: `balloonbaron.ach.<postcard>` for the 22 postcards, and the two leaderboards.
    static func achievementID(_ a: Achievement) -> String { "balloonbaron.ach.\(a.rawValue)" }
    static let totalPassengers = "balloonbaron.lb.passengers"
    static let bestDay = "balloonbaron.lb.bestday"

    static var signedIn: Bool { GKLocalPlayer.local.isAuthenticated }

    /// Game Center shows its own sign-in sheet when it needs one; `then` runs once the player is in.
    static func signIn(then: @escaping () -> Void) {
        GKLocalPlayer.local.authenticateHandler = { sheet, _ in
            if let sheet {
                topController()?.present(sheet, animated: true)
            } else if GKLocalPlayer.local.isAuthenticated {
                then()
            }
        }
    }

    /// Sends the postcards earned so far and the two scores. Game Center ignores what it already has.
    static func report(_ s: GameState) {
        guard signedIn else { return }
        let earned = s.achievements.keys.map { a -> GKAchievement in
            let x = GKAchievement(identifier: achievementID(a))
            x.percentComplete = 100
            x.showsCompletionBanner = false // the postcard is the celebration
            return x
        }
        if !earned.isEmpty { GKAchievement.report(earned) { _ in } }
        let player = GKLocalPlayer.local
        GKLeaderboard.submitScore(s.statistics.passengers, context: 0, player: player, leaderboardIDs: [totalPassengers]) { _ in }
        let best = ([s.local] + s.parked.values.map(\.state)).compactMap(\.bestPax).max() ?? 0
        if best > 0 { GKLeaderboard.submitScore(best, context: 0, player: player, leaderboardIDs: [bestDay]) { _ in } }
    }

    /// Game Center's own dashboard: achievements, leaderboards, friends.
    static func openDashboard() {
        if signedIn { GKAccessPoint.shared.trigger(state: .dashboard) {} } else { signIn {} }
    }

    private static func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}

/// v123: the App Store page the family's letter sends players to, to write a review.
enum AppStoreLink {
    /// The app's Apple ID from App Store Connect (My Apps → the app → App Information → Apple ID), a number such as
    /// "6740000000". While it is nil the letter's review button shows Apple's own rating prompt instead.
    static let appStoreID: String? = nil

    /// The App Store's write-review page for this app (`https://apps.apple.com/app/id<ID>?action=write-review`).
    static var writeReviewURL: URL? {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)?action=write-review") }
    }
}

/// The morning reminder: off until the player turns it on in the menu. Each time the app goes to the background
/// it leaves one gentle note in Hezarfen's voice for about the same time tomorrow, replacing the last one.
enum Reminder {
    private static let key = "reminder"
    static var on: Bool { UserDefaults.standard.bool(forKey: key) }

    /// Asks iOS for permission the first time; `done` gets whether the reminder is now on.
    static func turnOn(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: key)
                done(granted)
            }
        }
    }

    static func turnOff() {
        UserDefaults.standard.set(false, forKey: key)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func schedule(day: Int) {
        guard on else { return }
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let cal = Calendar.current
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) else { return }
        var when = cal.dateComponents([.year, .month, .day, .hour, .minute], from: tomorrow)
        // Never in the night: between 8 in the morning and 9 in the evening.
        when.hour = min(max(when.hour ?? 9, 8), 21)
        let content = UNMutableNotificationContent()
        content.title = loc("hez.name")
        content.body = loc("reminder.body\(day % 4 + 1)")
        content.sound = .default
        let request = UNNotificationRequest(identifier: "morning", content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false))
        center.add(request)
    }
}
