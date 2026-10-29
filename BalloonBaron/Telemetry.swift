import CryptoKit
import Foundation
import UIKit
import BalloonBaronCore

/// Anonymous usage signals to TelemetryDeck (its v2 ingest API, the same body its own SDK sends), so retention and
/// progress can be measured instead of guessed. No personal data: the player is a random id, hashed before it
/// leaves the phone. Off while `appID` is empty.
enum Telemetry {
    /// The TelemetryDeck app id (dashboard → app settings). Empty: nothing is sent.
    static let appID = "DDCDA4AF-F981-44C6-854E-F92166114D47"
    /// The organisation's namespace on TelemetryDeck (dashboard → setup); signals go to its own ingest path.
    private static let endpoint = URL(string: "https://nom.telemetrydeck.com/v2/namespace/com.cud/")!
    private static let session = UUID().uuidString

    private static let user: String = {
        let key = "telemetry.user"
        let id = UserDefaults.standard.string(forKey: key) ?? {
            let new = UUID().uuidString
            UserDefaults.standard.set(new, forKey: key)
            return new
        }()
        return SHA256.hash(data: Data(id.utf8)).map { String(format: "%02x", $0) }.joined()
    }()

    private struct Body: Encodable {
        let receivedAt: String, appID: String, clientUser: String, sessionID: String, type: String
        let floatValue: Double?
        let payload: [String: String]
        let isTestMode: String
    }

    /// Sends one signal. `value` is a number TelemetryDeck can chart (a day, an amount).
    static func send(_ type: String, value: Double? = nil, _ payload: [String: String] = [:]) {
        guard !appID.isEmpty else { return }
        var p = payload
        p["appVersion"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        p["systemVersion"] = UIDevice.current.systemVersion
        p["locale"] = Locale.current.identifier
        #if DEBUG
        let test = "true"
        #else
        let test = "false"
        #endif
        let stamp = ISO8601DateFormatter().string(from: Date())
        let body = Body(receivedAt: stamp, appID: appID, clientUser: user, sessionID: session, type: type, floatValue: value, payload: p, isTestMode: test)
        guard let data = try? JSONEncoder().encode([body]) else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        URLSession.shared.dataTask(with: request).resume()
    }

    /// The app came to the front.
    static func opened(_ s: GameState?) {
        send("app.opened", value: s.map { Double($0.day) }, s.map(progress) ?? [:])
    }

    /// A day ended: where the player is, and what happened that is worth counting.
    static func dayEnded(_ s: GameState, _ r: DayReport) {
        send("day.ended", value: Double(r.day), progress(s))
        for e in r.events {
            switch e {
            case let .chapterDone(id, _): send("chapter.done", value: Double(r.day), ["chapter": id, "region": s.region.rawValue])
            case let .baron(region): send("baron", value: Double(r.day), ["region": region.rawValue])
            default: break
            }
        }
        if s.over { send("game.over", value: Double(r.day), progress(s)) }
    }

    /// A chapter finished during the day, the moment its goals were met.
    static func chapterNow(_ s: GameState, _ news: ChapterNews) {
        let chapters = news.region.chapters
        guard chapters.indices.contains(news.index) else { return }
        if news.index == chapters.count - 1 {
            send("baron", value: Double(s.day), ["region": news.region.rawValue])
        } else {
            send("chapter.done", value: Double(s.day), ["chapter": chapters[news.index].id, "region": news.region.rawValue])
        }
    }

    static func bought(_ k: StoreItem, day: Int) {
        send("store.bought", value: Double(day), ["item": k.rawValue])
    }

    /// v122: a step of the tutorial that shows (`tutorial.price` … `tutorial.ga_bank_done`), once each, with the day:
    /// the players who leave in their first three days are compared with the steps they reached.
    static func tutorial(_ step: String, day: Int) {
        send("tutorial.\(step)", value: Double(day), ["day": String(day)])
    }

    /// v123: the family's letter: `letter.shown`, `letter.rate` (its App Store button) or `letter.later`, with the day.
    static func letter(_ what: String, day: Int) {
        send("letter.\(what)", value: Double(day), ["day": String(day)])
    }

    /// The funnel's first steps: a company founded, the intro balloon gone.
    static func started(company: String) { send("game.started") }
    static func introDone(_ s: GameState?) { send("intro.done", value: s.map { Double($0.day) }) }

    /// How the day's own flight ended (perfect … crash), to see where flying gets too hard.
    static func flight(_ r: FlightResult, _ s: GameState) {
        var p = progress(s)
        p["landing"] = r.landing.rawValue
        p["mission"] = r.mission == nil ? "none" : (r.missionDone ? "done" : "missed")
        send("flight.result", value: Double(s.day), p)
    }

    /// A store screen opened: "bazaar", or an item's card.
    static func storeViewed(_ screen: String, _ s: GameState?) {
        send("store.viewed", value: s.map { Double($0.day) }, ["screen": screen])
    }

    /// An offer (the Grand Tour after the ceremony) was shown, and what the player did with it.
    static func offer(_ name: String, _ answer: String, _ s: GameState?) {
        send("offer.\(answer)", value: s.map { Double($0.day) }, ["offer": name])
    }

    /// Session length: the app came to the front, and how many seconds later it left.
    private static var activeSince: Date?
    static func became(active: Bool) {
        if active {
            activeSince = Date()
        } else if let since = activeSince {
            activeSince = nil
            send("session.ended", value: Date().timeIntervalSince(since).rounded())
        }
    }

    private static func progress(_ s: GameState) -> [String: String] {
        ["day": String(s.day), "region": s.region.rawValue, "chapter": String(s.chapter), "balloons": String(s.balloons.count)]
    }
}
