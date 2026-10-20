import SwiftUI
import Observation
import BalloonBaronCore

/// Office pages opened from the side buttons on the home screen.
enum Page: String, Identifiable {
    case fleet, crew, bank, market, goals, holding, map, town
    var id: String { rawValue }
}

/// A rival's offer waiting for an answer.
struct DealOffer: Equatable {
    var rival: Int
    var bankrupt: Bool
}

/// Owns the running game and persists it after every change.
@Observable
final class GameStore {
    var game: Game?
    /// The report shown after a day ends.
    var report: DayReport?
    /// Hezarfen's message currently on screen.
    var hezarfen: HezMessage?
    /// Chapter ceremony or merger news on screen; these come before Hezarfen.
    var chapter: ChapterNews?
    var merge: MergeNews?
    /// A rival wants one of your pilots (after Hezarfen, like the prototype).
    var poach: PoachOffer?
    /// A struggling rival offers its company, or a bankrupt one its fleet.
    var deal: DealOffer?
    /// The menu (save code, new game, sound) and the popularity chart.
    var showMenu = false
    var showRepChart = false
    /// The office page on screen.
    var page: Page?
    /// Section the page scrolls to when it opens from the town.
    var pageSection: PageSection?
    /// Zone the full-screen town glides to when it opens from the home screen.
    var townFocus: TownFocus?
    /// The town's card for the agencies and for buildings that open later.
    var townCard: TownCard?
    /// A parked region whose problem the player is deciding.
    var issueRegion: RegionID?
    /// The dream-flight intro runs at every launch, like the prototype.
    var showIntro = true
    /// Passengers are being gathered (the seat-filling screen before take-off).
    var collecting = false
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
            currentRegion = state.region
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
        currentRegion = g.state.region
        save()
    }

    /// Shows the next popup in the prototype's order: chapter ceremony, merger news, then Hezarfen.
    func showNextHezarfen() {
        guard !showIntro, !collecting, hezarfen == nil, chapter == nil, merge == nil, poach == nil, deal == nil, !showMenu, townCard == nil,
              report == nil, flightPax == nil, page == nil, issueRegion == nil, let g = game else { return }
        let s = g.state
        if let c = s.chapterNews {
            chapter = c
            act { $0.state.chapterNews = nil }
        } else if let m = s.mergeNews {
            merge = m
            act { $0.state.mergeNews = nil }
        } else if !s.hezQueue.isEmpty {
            act { hezarfen = $0.nextHezarfen() }
        } else if let p = s.poach {
            // The offer is shown once; it leaves the state so rivals can try again later.
            act { $0.state.poach = nil }
            if s.pilots.contains(where: { $0.id == p.pilotID }), s.rivals.indices.contains(p.rivalIndex), s.rivals[p.rivalIndex].alive {
                poach = p
            } else {
                showNextHezarfen()
            }
        } else if let d = g.pendingDeal {
            act { $0.markDealSeen(d.rival, bankrupt: d.bankrupt) }
            deal = DealOffer(rival: d.rival, bankrupt: d.bankrupt)
        }
    }

    /// Keep the pilot by matching the rival's wage, or let them go.
    func answerPoach(_ offer: PoachOffer, match: Bool) {
        act { g in
            g.state.poach = offer
            g.answerPoach(match: match)
        }
        poach = nil
        showNextHezarfen()
    }

    /// Accept or decline a rival's company or fleet.
    func answerDeal(_ d: DealOffer, accept: Bool) {
        act { g in
            if accept {
                if d.bankrupt { _ = g.buyBankruptFleet(d.rival) } else { _ = g.takeOver(d.rival) }
            } else {
                g.declineDeal(d.rival, bankrupt: d.bankrupt)
            }
        }
        deal = nil
        showNextHezarfen()
    }

    func closeMenu() {
        showMenu = false
        showNextHezarfen()
    }

    /// Wipes the save and starts over from the intro.
    func startOver() {
        try? FileManager.default.removeItem(at: Self.saveURL)
        game = nil
        currentRegion = .cap
        report = nil
        hezarfen = nil
        chapter = nil
        merge = nil
        poach = nil
        deal = nil
        page = nil
        issueRegion = nil
        collecting = false
        flightPax = nil
        showMenu = false
        showRepChart = false
        showIntro = true
    }

    /// A save code to continue on another device (base64 JSON), and loading one.
    var saveCode: String? {
        guard let state = game?.state, let data = try? JSONEncoder().encode(state) else { return nil }
        return data.base64EncodedString()
    }

    @discardableResult
    func load(code: String) -> Bool {
        guard let data = Data(base64Encoded: code.trimmingCharacters(in: .whitespacesAndNewlines)),
              let state = try? JSONDecoder().decode(GameState.self, from: data) else { return false }
        var g = Game(state: state)
        g.startDay()
        game = g
        currentRegion = state.region
        save()
        showMenu = false
        showNextHezarfen()
        return true
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

    // MARK: Town

    /// A tapped building: its office page (scrolled to its section), its card, or the goals.
    func tapTown(_ tap: TownTap) {
        switch tap {
        case .page(let p, let section):
            pageSection = section
            page = p
        case .card(let c):
            townCard = c
        case .goals:
            page = .goals
        }
    }

    /// Opens Şirketim full screen, gliding to a zone if one was tapped.
    func openTown(_ focus: TownFocus?) {
        townFocus = focus
        page = .town
    }

    func closeTownCard() {
        townCard = nil
        showNextHezarfen()
    }

    /// Scrolls a page that opened from the town to the building's section.
    func scrollToSection(_ proxy: ScrollViewProxy) {
        guard let s = pageSection else { return }
        pageSection = nil
        DispatchQueue.main.async { proxy.scrollTo(s, anchor: .top) }
    }

    func closePage() {
        pageSection = nil
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

    func startCollect() {
        collecting = true
    }

    /// The intro balloon has left the screen.
    func finishIntro() {
        showIntro = false
        showNextHezarfen()
    }

    func cancelCollect() {
        collecting = false
    }

    func fly(skip: Bool = false) {
        collecting = false
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
    func resetForTesting() { startOver() }
    #endif
}
