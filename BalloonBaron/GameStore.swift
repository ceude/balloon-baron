import Foundation
import Observation
import BalloonBaronCore

/// Owns the running game and persists it after every change.
@Observable
final class GameStore {
    var game: Game?
    /// The report shown after a day ends.
    var report: DayReport?
    /// Hezarfen's message currently on screen.
    var hezarfen: HezMessage?
    /// Passengers riding with you while the flight scene runs.
    var flightPax: Int?

    private static var saveURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("save.json")
    }

    init() {
        if let data = try? Data(contentsOf: Self.saveURL),
           let state = try? JSONDecoder().decode(GameState.self, from: data) {
            var g = Game(state: state)
            g.startDay()
            game = g
        }
    }

    var state: GameState? { game?.state }

    func newGame(company: String, colors: [String]) {
        var g = Game(company: company, colors: colors)
        g.startDay()
        game = g
        save()
        showNextHezarfen()
    }

    func save() {
        guard let state = game?.state, let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: Self.saveURL, options: .atomic)
    }

    /// Runs an action on the game and saves.
    func act(_ f: (inout Game) -> Void) {
        guard var g = game else { return }
        f(&g)
        game = g
        save()
    }

    func showNextHezarfen() {
        guard hezarfen == nil, report == nil, flightPax == nil else { return }
        act { hezarfen = $0.nextHezarfen() }
    }

    func dismissHezarfen() {
        hezarfen = nil
        showNextHezarfen()
    }

    func fly(skip: Bool = false) {
        var selfPax: Int?
        act { selfPax = $0.launch(skip: skip) }
        if let selfPax { flightPax = selfPax } else { endDay(nil) }
    }

    func endDay(_ result: FlightResult?) {
        flightPax = nil
        var r: DayReport?
        act { r = $0.finishDay(flight: result) }
        report = r
    }

    func closeReport() {
        report = nil
        act { $0.startDay() }
        showNextHezarfen()
    }

    #if DEBUG
    func resetForTesting() {
        try? FileManager.default.removeItem(at: Self.saveURL)
        game = nil
        report = nil
        hezarfen = nil
        flightPax = nil
    }
    #endif
}
