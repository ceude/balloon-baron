#if DEBUG
import Foundation
import BalloonBaronCore

/// Screenshot runs on the simulator (.github/workflows/screens.yml), debug builds only. Launch arguments:
/// `-demoDays N` plays N days with a simple bot and opens on the home screen; `-demoIntro` keeps the intro;
/// `-demoPage fleet` opens an office page (`-demoUnit deals` then a holding desk, `-demoHolding deals|jersey` its money and deal); `-demoRegion abq` plays on in Albuquerque after Cappadocia, `-demoRegion lux` then on in Luxor.
/// One scene on top: `-demoScene issue` (pilots asking for a raise outside the office, then the card), `collect`, `album`, `deal`,
/// `letter` (the family's letter, sealed) and `letterRead` (the letter already open).
/// v124: `flight` (your own flight; in Bristol on a foggy morning with the airport's airspace), `glow` (Bristol's Night Glow night).
/// v125 (with `-demoRegion`): `contract` (a contract offer card), `contractScene` (the first offer's scene at the off-map
/// place), `transfer` (the card to bring the fleet, entering the region); v125.6: `cargo` (balloons on their way by cargo,
/// with `-demoPage fleet`). v126 (in Cappadocia, without `-demoRegion`): `charter` (the first charter offer's scene: the
/// plane lands at the airport, then the card), `charterDelay` (a booked charter group whose plane is late: the card).
/// The airport with the parked plane is the `charter` scene's last frames.
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
            // Regions past Cappadocia need the World Tour; without it enterRegion refuses and the run stays home.
            g.grantStoreItem(.worldTour)
            Self.demoEnter(&g, .abq)
            g.state.transferAsk = nil
            g.state.cash = 120_000
            for _ in 0..<20 { Self.demoDay(&g) }
            if r == "lux" || r == "bri" {
                g.state.barons[.abq] = g.state.day
                g.state.holding.cash = max(g.state.holding.cash, 400_000)
                Self.demoEnter(&g, .lux)
                g.state.transferAsk = nil
                g.state.cash = 120_000
                for _ in 0..<20 { Self.demoDay(&g) }
            }
            if r == "bri" {
                g.state.barons[.lux] = g.state.day
                g.state.holding.cash = max(g.state.holding.cash, 400_000)
                Self.demoEnter(&g, .bri)
                g.state.transferAsk = nil
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
        case "contract", "contractScene":
            // v125: chapter 2 with a mid fleet; this morning the region's contract offer comes
            if var gg = game, gg.state.contractConfig != nil {
                gg.state.local.chapter = max(gg.state.local.chapter, 1)
                gg.state.cash = max(gg.state.cash, 400_000)
                for z in [BalloonSize.M, .L, .M, .L] { _ = gg.buyBalloon(z) }
                gg.state.weather?.flag = .green
                gg.state.local.contracts = ContractState()
                gg.state.local.contracts?.next = gg.state.day
                gg.state.local.contracts?.scene = value("-demoScene") == "contract"
                gg.state.local.contracts?.met = value("-demoScene") == "contract"
                gg.contractMorning()
                gg.state.hezQueue = []
                game = gg
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.showNextHezarfen() }
            }
        case "charter", "charterDelay":
            // v126: Cappadocia, chapter 2, a quiet morning with the first charter offer (its scene at the airport); or a
            // charter group of yours flying today whose plane is late
            if var gg = game, gg.state.region == .cap, gg.state.contractConfig != nil {
                gg.state.local.chapter = max(gg.state.local.chapter, 1)
                gg.state.cash = max(gg.state.cash, 400_000)
                for z in [BalloonSize.M, .L, .M, .L] { _ = gg.buyBalloon(z) }
                gg.state.weather?.flag = .green
                gg.state.local.nextEvent = gg.state.day + 30
                gg.state.local.contracts = ContractState()
                gg.state.local.contracts?.next = gg.state.day
                gg.contractMorning()
                if value("-demoScene") == "charterDelay" {
                    gg.state.local.contracts?.scene = true
                    gg.acceptContract()
                    if var c = gg.state.local.contracts, !c.booked.isEmpty {
                        c.taken = 3
                        c.booked[0].day = gg.state.day
                        c.booked[0].nth = 3
                        c.booked[0].warned = true
                        c.booked[0].warnRolled = true
                        c.booked[0].delay = ContractDelay(day: gg.state.day, chance: 0.6, lands: true)
                        c.next = gg.state.day + 30
                        gg.state.local.contracts = c
                    }
                }
                gg.state.hezQueue = []
                game = gg
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.showNextHezarfen() }
            }
        case "transfer":
            if var gg = game, !gg.state.parked.isEmpty {
                gg.state.transferAsk = gg.state.region
                game = gg
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.showNextHezarfen() }
            }
        case "cargo":
            // v125.6: the fleet page with balloons still on their way by cargo (with `-demoPage fleet`)
            if var gg = game, !gg.state.parked.isEmpty {
                gg.applyTransfer(balloons: gg.transferDefaults.balloons, pilots: [])
                gg.state.hezQueue = []
                game = gg
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

    /// Enters a region for a screenshot run; a refusal would leave every later scene in the wrong region, so it says so.
    private static func demoEnter(_ g: inout Game, _ r: RegionID) {
        let ok = g.enterRegion(r)
        if !ok { NSLog("DemoSetup: enterRegion(\(r.rawValue)) refused (open \(g.state.regionOpen(r)), needsPack \(g.state.needsPack(r)))") }
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
