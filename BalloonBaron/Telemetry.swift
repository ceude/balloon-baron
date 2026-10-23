import CryptoKit
import Foundation
import UIKit
import BalloonBaronCore

/// Anonymous usage signals to TelemetryDeck (its v2 ingest API, the same body its own SDK sends), so retention and
/// progress can be measured instead of guessed. No personal data: the player is a random id, hashed before it
/// leaves the phone. Off while `appID` is empty.
enum Telemetry {
    /// The TelemetryDeck app id (dashboard → app settings). Empty: nothing is sent.
    static let appID = ""
    private static let endpoint = URL(string: "https://nom.telemetrydeck.com/v2/")!
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

    static func bought(_ k: StoreItem, day: Int) {
        send("store.bought", value: Double(day), ["item": k.rawValue])
    }

    private static func progress(_ s: GameState) -> [String: String] {
        ["day": String(s.day), "region": s.region.rawValue, "chapter": String(s.chapter), "balloons": String(s.balloons.count)]
    }
}
