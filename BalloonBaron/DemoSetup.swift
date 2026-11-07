#if DEBUG
import Foundation
import BalloonBaronCore

/// Screenshot runs on the simulator (.github/workflows/screens.yml), debug builds only. Launch arguments:
/// `-demoDays N` plays N days with a simple bot and opens on the home screen; `-demoIntro` keeps the intro;
/// `-demoPage fleet` opens an office page (`-demoUnit deals` then a holding desk, `-demoHolding deals|jersey` its money and deal); `-demoRegion abq` plays on in Albuquerque after Cappadocia, `-demoRegion lux` then on in Luxor, `bri` in Bristol, `mara` in the Maasai Mara.
/// One scene on top: `-demoScene issue` (pilots asking for a raise outside the office, then the card), `collect`, `album`, `deal`,
/// `letter` (the family's letter, sealed) and `letterRead` (the letter already open).
/// v124: `flight` (your own flight; in Bristol on a foggy morning with the airport's airspace), `glow` (Bristol's Night Glow night).
/// v125 (with `-demoRegion`): `contract` (a contract offer card), `contractScene` (the first offer's scene at the off-map
/// place), `transfer` (the card to bring the fleet, entering the region); v125.6: `cargo` (balloons on their way by cargo,
/// with `-demoPage fleet`). v126 (in Cappadocia, without `-demoRegion`): `charter` (the first charter offer's scene: the
/// plane lands at the airport, then the card), `charterDelay` (a booked charter group whose plane is late: the card).
/// The airport with the parked plane is the `charter` scene's last frames.
/// App Store captures (.github/workflows/store-shots.yml, tools/appstore/v2/store-shots.txt): `-demoStore` clears the
/// pictures (no tutorial, lessons or test button, no sponsor on any envelope, a green flag); `-demoCompany "Name"` names the
/// company; `-demoEmpire N` grows it after the days to N balloons, Baron of Cappadocia with a holding (its tower in the town),
/// every pilot hired, no sponsor on any envelope. Scenes: `auto` (the days advance
/// by themselves), `fireworks` (a wedding's fireworks over the town at night), `show` (the Balloon Show with the whole
/// fleet), `studio` (the design studio with the star balloon in the constellation pattern), `takeover` (a struggling rival
/// offers its company; with `-demoPage market -demoSection rivals`), `travel` (the flight across the world map to the current region).
extension GameStore {
    func applyDemoArguments() {
        let args = ProcessInfo.processInfo.arguments
        func value(_ k: String) -> String? { args.firstIndex(of: k).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
        guard let days = value("-demoDays").flatMap(Int.init) else { return }
        LaunchGuard.settled() // runs are stopped from outside; that is not a crash
        var g = Game(company: value("-demoCompany") ?? "Şafak Balon", colors: Rules.palettes[0], seed: 7)
        g.state.cash = 30000
        for _ in 0..<days { Self.demoDay(&g) }
        if let r = value("-demoRegion"), r == "abq" || r == "lux" || r == "bri" || r == "mara" {
            g.state.barons[.cap] = g.state.day
            g.state.holding.cash = 400_000
            // Regions past Cappadocia need the World Tour; without it enterRegion refuses and the run stays home.
            g.grantStoreItem(.worldTour)
            Self.demoEnter(&g, .abq)
            g.state.transferAsk = nil
            g.state.cash = 120_000
            for _ in 0..<20 { Self.demoDay(&g) }
            if r == "lux" || r == "bri" || r == "mara" {
                g.state.barons[.abq] = g.state.day
                g.state.holding.cash = max(g.state.holding.cash, 400_000)
                Self.demoEnter(&g, .lux)
                g.state.transferAsk = nil
                g.state.cash = 120_000
                for _ in 0..<20 { Self.demoDay(&g) }
            }
            if r == "bri" || r == "mara" {
                g.state.barons[.lux] = g.state.day
                g.state.holding.cash = max(g.state.holding.cash, 400_000)
                Self.demoEnter(&g, .bri)
                g.state.transferAsk = nil
                g.state.cash = 120_000
                for _ in 0..<20 { Self.demoDay(&g) }
            }
            if r == "mara" {
                g.state.barons[.bri] = g.state.day
                g.state.holding.cash = max(g.state.holding.cash, 400_000)
                Self.demoEnter(&g, .mara)
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
        if let n = value("-demoEmpire").flatMap(Int.init) { Self.demoEmpire(&g, balloons: n) }
        g.startDay()
        if let k = value("-demoSlow").flatMap(Double.init), k > 0 { DemoStudio.slow = k }
        if args.contains("-demoStore") {
            // App Store pictures: no lessons or coach, no test button, nothing written on any envelope, a green day
            DemoStudio.store = true
            _ = g.skipTutorial()
            g.removeAllAds()
            g.state.weather?.flag = .green
            g.state.tipsSeen = Set(Tip.allCases)
            if value("-demoEmpire") != nil { g.state.selfFlights = max(g.state.selfFlights ?? 0, 60) } // no flight lessons
            g.state.tutorialDone = true
            UserDefaults.standard.set(true, forKey: "ventTip") // the flight's one-time vent tip
            g.state.poach = nil
            // every postcard already in the album, so none stops the advancing days; only the happy reviews
            var cards = g.state.postcards ?? [:]
            for a in Achievement.allCases where cards[a] == nil { cards[a] = 1 }
            g.state.postcards = cards
            g.state.newPostcards = []
            g.state.postcardsLater = []
            g.state.letterDay = g.state.letterDay ?? 1 // the family's letter was read long ago
            g.state.hezLater = []
            g.state.local.reviews = g.state.local.reviews.filter { $0.stars >= 4 }
            // no charter offer (its first one plays the airport's scene) while the days advance
            if g.state.contractConfig != nil {
                var c = g.state.local.contracts ?? ContractState()
                c.next = g.state.day + 999
                c.scene = true
                c.met = true
                g.state.local.contracts = c
            }
            // the regions on autopilot run smoothly: no open problem, no halved income
            for r in Array(g.state.parked.keys) {
                g.state.parked[r]?.auto.issue = nil
                g.state.parked[r]?.auto.modifiers = []
                g.state.parked[r]?.auto.lastIssue = g.state.day
                g.state.parked[r]?.state.openIssue = nil
            }
        }
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
        if args.contains("-demoStore"), let p = page {
            // the store pictures need the page open: put it back if a first-morning card closed it
            for t in [1.0, 2.5] { DispatchQueue.main.asyncAfter(deadline: .now() + t) { if self.page == nil { self.page = p } } }
        }
        pageSection = value("-demoSection").flatMap(PageSection.init(rawValue:)) // the page opens scrolled to it
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
            if args.contains("-demoBurn") {
                // the burner held for the first 5 s, let go, then again: the balloon climbs off the field
                DemoFlight.burn = { t in (t > 0.4 && t < 5.4) || (t > 7.4 && t < 9.6) || (t > 12 && t < 13.5) }
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
                while gg.state.balloons.count + 4 > gg.state.hangarCapacity, gg.upgrade(.hangar) {} // v127: room for them
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
                while gg.state.balloons.count + 4 > gg.state.hangarCapacity, gg.upgrade(.hangar) {} // v127: room for them
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
        case "auto":
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.startAuto() }
        case "fireworks":
            DemoStudio.holdNight = true
            night = Night(event: .fireworks(game?.state.hotelDeals.first ?? .stone))
        case "show":
            if let ids = game?.showFleet.map(\.id) { night = Night(event: .show(balloons: ids)) }
        case "studio":
            DemoStudio.open = true
            DemoStudio.preset = (pattern: .sky, shape: .star, colors: ["#2b2350", "#ffc23d", "#ffffff"])
            page = .workshop
        case "takeover":
            if var gg = game, let i = gg.state.rivals.indices.first(where: { gg.state.rivals[$0].alive }) {
                gg.state.rivals[i].offer = max(60000, gg.state.rivals[i].balloons.count * 30000)
                game = gg
            }
        case "travel":
            let to = g.state.region
            travel = Travel(from: to == .cap ? .bri : .cap, to: to)
        case "letter", "letterRead":
            game?.state.letterDay = game?.state.day
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.letter = true }
        default: break
        }
    }

    /// The App Store's late game: Baron of Cappadocia with `n` balloons, a pilot for each, the buildings at the top, the
    /// workshop open and a holding with money in it. Balloons are bought by the rules (with the money given here).
    private static func demoEmpire(_ g: inout Game, balloons n: Int) {
        g.state.barons[.cap] = g.state.barons[.cap] ?? max(1, g.state.day - 30)
        var lv = g.state.buildings ?? [:]
        for b in Building.allCases { lv[b] = b == .hangar ? 6 : b.maxLevel }
        while Hangar.capacity[lv[.hangar] ?? 6] < n && (lv[.hangar] ?? 6) < Hangar.maxLevel { lv[.hangar] = (lv[.hangar] ?? 6) + 1 }
        g.state.buildings = lv
        g.state.workshopDay = g.state.workshopDay ?? max(1, g.state.day - 60)
        g.state.cash = 1_000_000_000
        let sizes: [BalloonSize] = [.M, .L, .M, .S, .L]
        var k = 0
        while g.state.balloons.count < n, g.buyBalloon(sizes[k % sizes.count]) { k += 1 }
        // A pilot for every balloon. Twelve seniors with twelve different names lead the crew page (it lists the big
        // balloons' pilots first, the most senior first, then by name); the first three show the characters.
        let traits: [PilotTrait] = [.careful, .daredevil, .loyal, .thrifty, .showman, .storyteller]
        if let model = g.state.pilots.first {
            for j in g.state.pilots.indices { g.state.pilots[j].level = .experienced }
            let names = g.state.region.pilotNames, initials = g.state.region.pilotInitials
            var i = 0
            while g.state.pilots.count < n - 1 {
                var p = model
                p.id = g.state.nextID
                g.state.nextID += 1
                p.name = "\(names[i % names.count]) \(initials[(i * 7 + i / names.count + 3) % initials.count])."
                p.trait = traits[(i * 5 + 1) % traits.count]
                p.level = i < 12 ? .senior : i % 3 == 0 ? .rookie : .experienced
                p.customWage = nil
                p.xp = 0
                g.state.pilots.append(p)
                i += 1
            }
            let seniors = g.state.pilots.indices.filter { g.state.pilots[$0].level == .senior }
                .sorted { g.state.pilots[$0].name.localizedCompare(g.state.pilots[$1].name) == .orderedAscending }
            for (k, j) in seniors.enumerated() { g.state.pilots[j].trait = traits[k % traits.count] }
        }
        for k in StoreItem.allCases { g.grantStoreItem(k) } // the studio's star balloon and constellation, the square's decor
        for i in g.state.balloons.indices { g.state.balloons[i].design = nil } // the balloons keep the company's colours
        g.assignPilots()
        // one day flown with the whole fleet, so the market's "yesterday" is the empire's
        g.state.cash = 3_000_000
        g.state.weather?.flag = .green
        demoDay(&g)
        g.state.cash = 3_043_969
        g.state.holding.cash = max(g.state.holding.cash, 8_760_000)
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
        if g.state.winter == nil && g.state.cash > 45000 && g.state.balloons.count < 9 {
            if g.state.balloons.count >= g.state.hangarCapacity { _ = g.upgrade(.hangar) } else { _ = g.buyBalloon(.M) } // v127
        }
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

/// `-demoBurn`: the flight's burner held on this rhythm (seconds since the flight began).
enum DemoFlight {
    static var burn: ((Double) -> Bool)?
}

/// The design studio opened by `-demoScene studio`, with this design already chosen; `store`: `-demoStore` is on.
enum DemoStudio {
    static var store = false
    /// `-demoScene fireworks`: the night doesn't pass by itself after a few quiet seconds.
    static var holdNight = false
    /// `-demoSlow 0.15`: the night and the Balloon Show run at this speed, so the CI simulator (which draws them at a few
    /// frames a second) records them smoothly; the video is sped up again afterwards (tools/appstore/v2/clips.py).
    static var slow = 1.0
    static var open = false
    static var preset: (pattern: Pattern, shape: EnvelopeShape?, colors: [String])?
}
#endif
