import Foundation
import Observation
import BalloonBaronCore

/// Office pages opened from the side buttons on the home screen.
enum Page: String, Identifiable {
    case fleet, crew, market, goals, holding, map
    var id: String { rawValue }
}

/// Owns the running game and persists it after every change.
@Observable
final class GameStore {
    var game: Game? { didSet { currentRegion = game?.state.region ?? .cap } }
    /// The report shown after a day ends.
    var report: DayReport?
    /// Hezarfen's message currently on screen.
    var hezarfen: HezMessage?
    /// Chapter ceremony or merger news on screen; these come before Hezarfen.
    var chapter: ChapterNews?
    var merge: MergeNews?
    /// The office page on screen.
    var page: Page?
    /// A parked region whose problem the player is deciding.
    var issueRegion: RegionID?
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

    /// Shows the next popup in the prototype's order: chapter ceremony, merger news, then Hezarfen.
    func showNextHezarfen() {
        guard hezarfen == nil, chapter == nil, merge == nil, report == nil, flightPax == nil, page == nil, issueRegion == nil,
              let s = game?.state else { return }
        if let c = s.chapterNews {
            chapter = c
            act { $0.state.chapterNews = nil }
        } else if let m = s.mergeNews {
            merge = m
            act { $0.state.mergeNews = nil }
        } else {
            act { hezarfen = $0.nextHezarfen() }
        }
    }

    func dismissHezarfen() {
        hezarfen = nil
        showNextHezarfen()
    }

    func dismissPopup() {
        chapter = nil
        merge = nil
        showNextHezarfen()
    }

    func closePage() {
        page = nil
        issueRegion = nil
        showNextHezarfen()
    }

    /// Moves to another region (or into a new one) and closes the office pages.
    func goTo(_ r: RegionID) {
        page = nil
        issueRegion = nil
        act { g in
            if g.state.owns(r) { g.switchRegion(r) } else { _ = g.enterRegion(r) }
        }
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
        chapter = nil
        merge = nil
        page = nil
        issueRegion = nil
        flightPax = nil
    }
    #endif
}
