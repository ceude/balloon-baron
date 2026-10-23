#if DEBUG
import Foundation
import BalloonBaronCore

/// Screenshot runs on the simulator (.github/workflows/screens.yml), debug builds only. Launch arguments:
/// `-demoDays N` plays N days with a simple bot and opens on the home screen; `-demoIntro` keeps the intro;
/// `-demoPage fleet` opens an office page; `-demoRegion abq` plays on in Albuquerque after Cappadocia, `-demoRegion lux` then on in Luxor.
extension GameStore {
    func applyDemoArguments() {
        let args = ProcessInfo.processInfo.arguments
        func value(_ k: String) -> String? { args.firstIndex(of: k).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
        guard let days = value("-demoDays").flatMap(Int.init) else { return }
        LaunchGuard.settled() // runs are stopped from outside; that is not a crash
        var g = Game(company: "Şafak Balon", colors: Rules.palettes[0], seed: 7)
        g.state.cash = 30000
        for _ in 0..<days { Self.demoDay(&g) }
        if let r = value("-demoRegion"), r == "abq" || r == "lux" {
            g.state.barons[.cap] = g.state.day
            g.state.holding.cash = 400_000
            _ = g.enterRegion(.abq)
            g.state.cash = 120_000
            for _ in 0..<20 { Self.demoDay(&g) }
            if r == "lux" {
                g.state.barons[.abq] = g.state.day
                _ = g.enterRegion(.lux)
                g.state.cash = 120_000
                for _ in 0..<20 { Self.demoDay(&g) }
            }
        }
        g.startDay()
        g.state.hezQueue = []
        g.state.paper = nil
        g.state.eventDue = false
        g.state.newPostcards = []
        g.state.chapterNews = nil
        g.state.mergeNews = nil
        game = g
        currentRegion = g.state.region
        showIntro = args.contains("-demoIntro")
        page = value("-demoPage").flatMap(Page.init(rawValue:))
    }

    /// One day of a steady player: grows the fleet, staffs it, signs hotels, flies unless the flag is red.
    private static func demoDay(_ g: inout Game) {
        g.startDay()
        while g.nextHezarfen() != nil {}
        g.state.chapterNews = nil
        if g.state.winter == nil && g.state.cash > 45000 && g.state.balloons.count < 9 { _ = g.buyBalloon(.M) }
        while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let c = g.state.candidates.first { _ = g.hire(c.id) }
        for h in Hotel.allCases where g.state.hotelDeals.count < 2 && g.state.cash > h.dailyFee * 3 + 6000 { _ = g.signHotel(h) }
        if let o = g.state.poach { g.answerPoach(match: o.wage <= 400) }
        if g.launch(skip: g.state.weather?.flag == .red) != nil {
            _ = g.finishDay(flight: FlightResult(landing: .good, distance: 80))
        } else {
            _ = g.finishDay(flight: nil)
        }
    }
}
#endif
