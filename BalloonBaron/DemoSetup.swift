#if DEBUG
import Foundation
import BalloonBaronCore

/// Screenshot runs on the simulator (.github/workflows/screens.yml), debug builds only. Launch arguments:
/// `-demoDays N` plays N days with a simple bot and opens on the home screen; `-demoIntro` keeps the intro;
/// `-demoPage fleet` opens an office page (`-demoUnit deals` then a holding desk, `-demoHolding deals|jersey` its money and deal); `-demoRegion abq` plays on in Albuquerque after Cappadocia, `-demoRegion lux` then on in Luxor.
/// One scene on top: `-demoScene issue` (pilots asking for a raise outside the office, then the card), `collect`, `album`, `deal`,
/// `letter` (the family's letter, sealed) and `letterRead` (the letter already open).
/// v124: `flight` (your own flight; in Bristol on a foggy morning with the airport's airspace), `glow` (Bristol's Night Glow night).
extension GameStore {
    func applyDemoArguments() {
        let args = ProcessInfo.processInfo.arguments
        func value(_ k: String) -> String? { args.firstIndex(of: k).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
        guard let days = value("-demoDays").flatMap(Int.init) else { return }
        LaunchGuard.settled() // runs are stopped from outside; that is not a crash
        var g = Game(company: "Şafak Balon", colors: Rules.palettes[0], seed: 7)
        g.state.cash = 30000
        for _ in 0..<days { Self.demoDay(&g) }
        if let r = value("-demoRegion"), r == "abq" || r == "lux" || r == "bri" {
            g.state.barons[.cap] = g.state.day
            g.state.holding.cash = 400_000
            _ = g.enterRegion(.abq)
            g.state.cash = 120_000
            for _ in 0..<20 { Self.demoDay(&g) }
            if r == "lux" || r == "bri" {
                g.state.barons[.abq] = g.state.day
                _ = g.enterRegion(.lux)
                g.state.cash = 120_000
                for _ in 0..<20 { Self.demoDay(&g) }
            }
            if r == "bri" {
                g.state.barons[.lux] = g.state.day
                g.state.holding.cash = max(g.state.holding.cash, 400_000)
                _ = g.enterRegion(.bri)
                g.state.cash = 120_000
                for _ in 0..<20 { Self.demoDay(&g) }
            }
        }
        // `-demoHolding deals`: holding money for the deals desk; `jersey`: the jersey sponsorship is running.
        if let h = value("-demoHolding") {
            g.state.holding.cash = 15_000_000
            if h == "jersey" { g.sponsorJersey() }
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
        switch value("-demoScene") {
        case "issue":
            game?.state.local.openIssue = Autopilot.OpenIssue(kind: .raise, day: g.state.day)
            game?.state.local.issueSeen = g.state.day
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.showLiveIssue() }
        case "collect":
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.startCollect() }
        case "album":
            var got = game?.state.postcards ?? [:]
            for a in Achievement.allCases.prefix(6) { got[a] = got[a] ?? 5 }
            game?.state.postcards = got
            showAlbum = true
        case "flight":
            // v124: in Bristol a foggy morning with the airport's airspace on the way
            if var gg = game, var w = gg.state.weather {
                w.flag = .green
                if gg.state.region == .bri {
                    w.fog = Fog(top: 120)
                    w.air = Airspace(x0: 700, x1: 1200, floor: 360)
                }
                gg.state.weather = w
                game = gg
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.fly() }
        case "glow":
            // v124: Bristol's Night Glow, booked on a festival day, then the night
            if var gg = game, gg.state.region == .bri {
                gg.state.fiesta = Fiesta(start: gg.state.day, end: gg.state.day + 3)
                gg.state.cash = max(gg.state.cash, 50000)
                _ = gg.bookGlow()
                game = gg
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.fly(skip: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.closeReport() }
                }
            }
        case "deal":
            if var gg = game, !gg.state.rivals.isEmpty {
                gg.state.rivals[0].offer = 60000
                game = gg
                deal = DealOffer(rival: 0, bankrupt: false)
            }
        case "letter", "letterRead":
            game?.state.letterDay = game?.state.day
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.letter = true }
        default: break
        }
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
