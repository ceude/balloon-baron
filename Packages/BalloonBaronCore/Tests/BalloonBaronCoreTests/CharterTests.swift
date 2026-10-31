import XCTest
@testable import BalloonBaronCore

/// Prototype v126–v126.1: Cappadocia's charter contracts (the late plane), per-owner progress, vehicles arriving once.
final class CharterTests: XCTestCase {
    /// Cappadocia on `day`, chapter 2, a mid fleet with a pilot for each balloon, a quiet morning.
    func cap(seed: UInt64 = 42, day: Int = 40, sizes: [BalloonSize] = [.M, .M, .S, .M]) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        g.state.day = day
        g.state.local.chapter = 1
        g.state.local.balloons = []
        g.state.local.pilots = []
        for (i, z) in sizes.enumerated() {
            g.state.local.balloons.append(Balloon(id: g.state.nextID, size: z, name: "B\(i)"))
            g.state.local.pilots.append(Pilot(id: g.state.nextID + 1000, name: "P\(i)", level: .experienced))
            g.state.nextID += 1
        }
        g.state.local.flagship = g.state.local.balloons[0].id
        g.state.local.selfFly = false
        g.state.lastSelfFly = g.state.day
        g.state.cash = 100_000
        g.state.hezQueue = []
        g.state.local.nextEvent = day + 30
        g.state.local.winter = nil
        g.state.weather?.flag = .green
        g.state.weather?.fog = nil
        g.assignPilots()
        return g
    }

    /// A job of yours (owner Ji-woo) starting today, the `nth` taken here.
    @discardableResult
    func book(_ g: inout Game, n: Int = 14, price: Int = 150, nth: Int = 1, warned: Bool? = nil, owner: ContractOwner = .jiwoo) -> ContractJob {
        var c = g.state.local.contracts ?? ContractState()
        var k = ContractJob(id: g.state.nextID, owner: owner, n: n, price: price, day: g.state.day, len: 2, fogP: nil)
        k.nth = nth
        k.warned = warned
        if warned != nil { k.warnRolled = true }
        g.state.nextID += 1
        c.booked.append(k)
        c.next = g.state.day + 100
        c.taken = nth
        g.state.local.contracts = c
        return k
    }

    func job(_ g: Game, _ id: Int) -> ContractJob? { g.state.local.contracts?.booked.first { $0.id == id } }

    // MARK: The config and the offer

    func testCappadociaConfig() {
        let K = RegionID.cap.contracts!
        XCTAssertEqual(K.kind, .plane)
        XCTAssertEqual(K.cast, [.jiwoo, .chen, .murat])
        XCTAssertEqual(K.minChapter, 1)
        XCTAssertEqual(K.minSeats, 40)
        XCTAssertEqual(K.firstWait, 1)
        XCTAssertEqual(K.firstDay, 40)
        XCTAssertTrue(K.quiet)
        XCTAssertEqual(K.gap, 11...15)
        XCTAssertEqual(K.prefGap, 7...10)
        XCTAssertEqual(K.lead, 3...5)
        XCTAssertEqual(K.len, 2...2)
        XCTAssertEqual(K.share, 0.25...0.4)
        XCTAssertEqual(K.price, 0.8...0.9)
        XCTAssertEqual(K.prefPrice, 1.06)
        XCTAssertEqual(K.pen, 0.5)
        XCTAssertEqual(K.redCut, 0)
        XCTAssertFalse(K.redMove)
        XCTAssertEqual(K.prefNeed, 3)
        XCTAssertEqual(K.cool, 14)
        XCTAssertEqual(K.sceneZoom, 0.6)
        let D = K.delay!
        XCTAssertEqual(D.after, 2)
        XCTAssertEqual(D.warnP, 0.35)
        XCTAssertEqual(D.lateP, 0.6)
        XCTAssertEqual(D.land, 0.3...0.7)
        XCTAssertEqual(D.waitPay, 0.4)
        XCTAssertNil(RegionID.abq.contracts?.delay)
        XCTAssertEqual(RegionID.abq.contracts?.firstDay, 0)
        XCTAssertEqual(ContractOwner.jiwoo.company, "Haneul Wings")
        XCTAssertEqual(ContractOwner.murat.color, "#1f6f8b")
    }

    func testFirstOfferNotBeforeDayForty() {
        var g = cap(day: 30)
        g.contractMorning()
        XCTAssertEqual(g.state.local.contracts?.next, 40, "max(day + firstWait, firstDay)")
        XCTAssertNil(g.state.local.contracts?.offer)
        var h = cap(day: 44)
        h.contractMorning()
        XCTAssertEqual(h.state.local.contracts?.next, 45, "past day 40: the morning after")
        // chapter 1: nothing at all
        var k = cap(day: 60)
        k.state.local.chapter = 0
        k.contractMorning()
        XCTAssertNil(k.state.local.contracts?.next)
    }

    func testOfferRangesInCappadocia() {
        let K = RegionID.cap.contracts!
        for seed in UInt64(1)...25 {
            var g = cap(seed: seed)
            g.state.local.contracts = ContractState()
            g.state.local.contracts?.next = g.state.day
            g.contractMorning()
            guard let o = g.state.local.contracts?.offer else { return XCTFail("no offer (seed \(seed))") }
            let seats = g.state.fleetSeats
            XCTAssertEqual(o.len, 2)
            XCTAssertEqual(o.n % 2, 0)
            XCTAssertGreaterThanOrEqual(o.n, max(12, Int(Double(seats) * K.share.lowerBound) - 2))
            XCTAssertLessThanOrEqual(o.n, max(12, Int(Double(seats) * K.share.upperBound) + 2))
            XCTAssertEqual(o.owner, .jiwoo)
            XCTAssertLessThanOrEqual(o.price, o.top)
            XCTAssertLessThanOrEqual(o.top, g.state.price)
            XCTAssertEqual(o.price % 5, 0)
            XCTAssertTrue((3...5).contains(o.day - g.state.day))
            XCTAssertNil(o.fogP)
        }
    }

    func testOfferNeedsFortySeats() {
        var g = cap(sizes: [.M, .S]) // 24 seats
        g.state.local.contracts = ContractState()
        g.state.local.contracts?.next = g.state.day
        g.contractMorning()
        XCTAssertNil(g.state.local.contracts?.offer)
    }

    func testOfferWaitsForAQuietMorning() {
        func tryOffer(_ f: (inout Game) -> Void) -> Game {
            var g = cap()
            g.state.local.contracts = ContractState()
            g.state.local.contracts?.next = g.state.day
            f(&g)
            g.contractMorning()
            return g
        }
        XCTAssertNotNil(tryOffer { _ in }.state.local.contracts?.offer, "a quiet morning")
        let busy: [(String, (inout Game) -> Void)] = [
            ("morning event", { g in g.state.local.nextEvent = g.state.day; g.state.unlocked.insert(.crew) }),
            ("chapter", { g in g.state.chapterNews = ChapterNews(region: .cap, index: 1) }),
            ("cards", { g in g.state.hezQueue = [.spring, .spring, .spring] }),
            ("transfer", { g in g.state.transferAsk = .cap }),
            ("merger", { g in g.state.mergeNews = MergeNews(a: "A", b: "B", name: "AB", balloons: 3, cash: 1, sharePercent: 10, rep: 1, colors: []) })
        ]
        for (why, f) in busy {
            let g = tryOffer(f)
            XCTAssertNil(g.state.local.contracts?.offer, why)
            XCTAssertEqual(g.state.local.contracts?.next, g.state.day, "\(why): next stays")
        }
        // two cards are fine; winter stops morning events, so it's quiet too
        XCTAssertNotNil(tryOffer { g in g.state.hezQueue = [.spring, .spring] }.state.local.contracts?.offer)
        XCTAssertNotNil(tryOffer { g in
            g.state.local.nextEvent = g.state.day; g.state.unlocked.insert(.crew); g.state.local.winter = Winter(start: g.state.day, end: g.state.day + 7)
        }.state.local.contracts?.offer)
    }

    func testAcceptCountsTheJobs() {
        var g = cap()
        g.state.local.contracts = ContractState()
        g.state.local.contracts?.next = g.state.day
        g.contractMorning()
        g.acceptContract()
        XCTAssertEqual(g.state.local.contracts?.taken, 1)
        XCTAssertEqual(g.state.local.contracts?.booked.first?.nth, 1)
        XCTAssertEqual(g.state.local.contracts?.booked.first?.len, 2)
    }

    // MARK: The late plane

    func testNoDelayWarningInTheFirstTwoJobs() {
        for nth in 1...2 {
            for seed in UInt64(0)..<40 {
                var g = cap(seed: seed)
                g.rng = SplitMix64(seed: seed)
                var k = book(&g, nth: nth)
                // the job starts tomorrow: tonight's report may warn
                var c = g.state.local.contracts!
                c.booked[0].day = g.state.day + 1
                g.state.local.contracts = c
                k.day += 1
                let r = run(&g, skip: true)
                XCTAssertFalse(r.events.contains(.contractDelayWarning(owner: .jiwoo)), "job \(nth)")
                XCTAssertEqual(job(g, k.id)?.warnRolled, true)
                XCTAssertNil(job(g, k.id)?.warned)
            }
        }
    }

    func testDelayWarningFromTheThirdJob() {
        var warned = 0
        for seed in UInt64(0)..<200 {
            var g = cap(seed: seed)
            g.rng = SplitMix64(seed: seed)
            book(&g, nth: 3)
            var c = g.state.local.contracts!
            c.booked[0].day = g.state.day + 1
            g.state.local.contracts = c
            let r = run(&g, skip: true)
            if r.events.contains(.contractDelayWarning(owner: .jiwoo)) {
                warned += 1
                XCTAssertEqual(g.state.local.contracts?.booked.first?.warned, true)
            }
            // rolled once only
            let id = g.state.local.contracts!.booked[0].id
            XCTAssertEqual(job(g, id)?.warnRolled, true)
        }
        XCTAssertEqual(Double(warned) / 200, 0.35, accuracy: 0.1)
    }

    func testWarnedPlaneIsLateOrOnTime() {
        var late = 0
        for seed in UInt64(0)..<200 {
            var g = cap(seed: seed)
            g.rng = SplitMix64(seed: seed)
            let k = book(&g, nth: 3, warned: true)
            g.contractMorning()
            if let dl = job(g, k.id)?.delay {
                late += 1
                XCTAssertEqual(dl.day, g.state.day)
                XCTAssertNil(dl.choice)
                XCTAssertTrue((0.3...0.7).contains(dl.chance))
                XCTAssertEqual((dl.chance * 10).rounded(), dl.chance * 10, accuracy: 1e-9)
                XCTAssertEqual(g.state.contractDelayPending?.id, k.id)
                XCTAssertTrue(g.state.hezQueue.contains(.contractDelayIntro), "the first time Hezarfen explains")
                XCTAssertFalse(g.state.hezQueue.contains { if case .contract(_, .today, _, _) = $0 { return true }; return false }, "no 'today' line")
                XCTAssertEqual(g.state.local.contracts?.delays, 1)
            } else {
                XCTAssertTrue(g.state.hezQueue.contains(.contract(.jiwoo, .onTime, n: 14, price: 150)))
            }
        }
        XCTAssertEqual(Double(late) / 200, 0.6, accuracy: 0.1)
        // the intro once only
        var g = cap()
        g.state.local.contracts = ContractState()
        g.state.local.contracts?.delayIntroShown = true
        let k = book(&g, nth: 3, warned: true)
        for seed in UInt64(0)..<20 {
            var h = g
            h.rng = SplitMix64(seed: seed)
            h.contractMorning()
            if job(h, k.id)?.delay != nil { XCTAssertFalse(h.state.hezQueue.contains(.contractDelayIntro)) }
        }
        // a red morning: no delay
        var r = cap()
        let kr = book(&r, nth: 3, warned: true)
        r.state.weather?.flag = .red
        for seed in UInt64(0)..<20 {
            var h = r
            h.rng = SplitMix64(seed: seed)
            h.contractMorning()
            XCTAssertNil(job(h, kr.id)?.delay)
        }
    }

    /// A job with a late plane today, landing or not.
    func lateJob(lands: Bool, price: Int = 150) -> (Game, ContractJob) {
        var g = cap()
        var k = book(&g, n: 14, price: price, nth: 3, warned: true)
        k.delay = ContractDelay(day: g.state.day, chance: 0.5, lands: lands, choice: nil)
        g.state.local.contracts?.booked[0] = k
        return (g, k)
    }

    func testHoldAndItLands() {
        var (g, k) = lateJob(lands: true)
        XCTAssertEqual(g.chooseContractDelay(.hold), .landed)
        XCTAssertEqual(job(g, k.id)?.day, k.day, "the group flies today as planned")
        XCTAssertNil(g.state.contractDelayPending)
        XCTAssertEqual(g.state.contractHeld(capacity: 100), 14)
        let r = run(&g)
        XCTAssertEqual(r.ledger.contract, 14 * 150)
        XCTAssertNil(r.ledger.contractWait)
    }

    func testHoldAndItDoesntCome() {
        var (g, k) = lateJob(lands: false)
        XCTAssertEqual(g.chooseContractDelay(.hold), .noShow)
        XCTAssertEqual(job(g, k.id)?.day, k.day + 1, "the group moves a day")
        XCTAssertEqual(g.state.local.contracts?.wait, ContractWait(day: g.state.day, n: 14, pay: 60, owner: .jiwoo))
        XCTAssertEqual(g.state.contractHeld(capacity: 100), 0)
        XCTAssertEqual(g.state.contractWaitSeats(capacity: 100), 14)
        XCTAssertEqual(g.state.contractWaitSeats(capacity: 10), 10)
        let est = g.estimatedIncome()
        let rel0 = g.state.local.contracts!.rel
        _ = g.launch()
        XCTAssertEqual(g.state.local.plan?.contractWait, 14)
        let r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.contractWait, 14 * 60, "40% of the price per empty seat")
        XCTAssertTrue(r.events.contains(.contractDelayNoShow(owner: .jiwoo, seats: 14, amount: 840)))
        XCTAssertNil(g.state.local.contracts?.wait)
        XCTAssertEqual(g.state.local.contracts?.rel, rel0, "trust kept")
        XCTAssertGreaterThan(est.income, 0)
        // tomorrow the group flies
        XCTAssertEqual(g.state.contractToday?.id, k.id)
    }

    func testOpenWhenItDoesntCome() {
        var (g, k) = lateJob(lands: false)
        let rel0 = g.state.local.contracts!.rel
        XCTAssertEqual(g.chooseContractDelay(.open), .openOk)
        XCTAssertEqual(job(g, k.id)?.day, k.day + 1)
        XCTAssertNil(g.state.local.contracts?.wait)
        XCTAssertEqual(g.state.local.contracts?.rel, rel0)
        XCTAssertNil(job(g, k.id)?.arrived, "it lands tomorrow")
        let r = run(&g)
        XCTAssertNil(r.ledger.contract)
        XCTAssertNil(r.ledger.contractWait)
    }

    func testOpenWhenItLandsAfterAll() {
        var (g, k) = lateJob(lands: true)
        g.state.local.contracts?.rel = 1
        XCTAssertEqual(g.chooseContractDelay(.open), .stranded)
        XCTAssertEqual(job(g, k.id)?.day, k.day + 1)
        XCTAssertEqual(g.state.local.contracts?.rel, 0, "trust −1")
        XCTAssertNotNil(job(g, k.id)?.arrived, "it stands there: no landing to show tomorrow")
        XCTAssertEqual(g.chooseContractDelay(.hold), nil, "answered once")
        // at −3 the owner breaks off
        var (h, _) = lateJob(lands: true)
        h.state.local.contracts?.rel = -2
        XCTAssertEqual(h.chooseContractDelay(.open), .stranded)
        XCTAssertEqual(h.state.local.contracts?.gone, [.jiwoo])
        XCTAssertTrue(h.state.hezQueue.contains(.contract(.jiwoo, .bye, n: 0, price: 0)))
    }

    func testUnansweredDelayHoldsTheSeats() {
        var (g, _) = lateJob(lands: false)
        _ = g.launch()
        XCTAssertEqual(g.state.local.plan?.contractWait, 14)
        XCTAssertNotNil(g.state.local.contracts?.wait)
    }

    // MARK: v126.1: progress per owner

    func testProgressCountsOnlyTheOwnersJobs() {
        var g = cap(sizes: [.L, .L, .L])
        g.state.local.contracts = ContractState()
        // a job with Chen (not calling now) done in full: his count, not Ji-woo's, and no trust or progress line
        book(&g, n: 12, owner: .chen)
        for _ in 0..<2 { g.state.weather?.flag = .green; _ = run(&g) }
        var c = g.state.local.contracts!
        XCTAssertEqual(c.ok, 1, "the region's total")
        XCTAssertEqual(c.okByOwner?["chen"], 1)
        XCTAssertEqual(g.state.contractOk(with: .chen), 1)
        XCTAssertEqual(g.state.contractOk(with: .jiwoo), 0)
        XCTAssertEqual(c.okWho, 0)
        XCTAssertEqual(c.rel, 0)
        // then Ji-woo's
        book(&g, n: 12, owner: .jiwoo)
        var last: DayReport?
        for _ in 0..<2 { g.state.weather?.flag = .green; last = run(&g) }
        c = g.state.local.contracts!
        XCTAssertEqual(c.ok, 2)
        XCTAssertEqual(g.state.contractOk(with: .jiwoo), 1)
        XCTAssertEqual(c.okWho, 1)
        XCTAssertEqual(c.rel, 1)
        XCTAssertTrue(last!.events.contains(.contractProgress(owner: .jiwoo, ok: 1, need: 3)))
        XCTAssertEqual(g.state.value(.ctrDone), 2, "the chapter goal counts every company")
    }

    func testOldSavesProgressBelongsToTheCurrentOwner() {
        var c = ContractState()
        c.okWho = 2
        c.who = 1
        XCTAssertNil(c.okByOwner)
        XCTAssertEqual(c.ok(with: .chen, current: .chen), 2)
        XCTAssertEqual(c.ok(with: .jiwoo, current: .chen), 0)
        // the next job done in full counts on top of it
        var g = cap(sizes: [.L, .L, .L])
        g.state.local.contracts = c
        book(&g, n: 12, owner: .chen)
        for _ in 0..<2 { g.state.weather?.flag = .green; _ = run(&g) }
        XCTAssertEqual(g.state.local.contracts?.okByOwner?["chen"], 3)
        // decoding an old save without the new keys
        let json = #"{"booked":[{"id":7,"owner":"rosa","n":20,"price":100,"day":5,"len":1,"moves":0,"got":0,"short":0,"flown":0,"fogged":0,"paid":false,"arrived":5}],"ok":1,"fail":0,"who":0,"rel":1,"okWho":1,"met":true,"pref":false,"prefEver":false,"gone":[],"scene":true}"#
        let old = try! JSONDecoder().decode(ContractState.self, from: Data(json.utf8))
        XCTAssertNil(old.okByOwner)
        XCTAssertEqual(old.ok(with: .rosa, current: .rosa), 1)
        XCTAssertTrue(old.booked[0].hasArrived)
        XCTAssertNil(old.booked[0].nth)
    }

    func testBreakingOffResetsThatOwnersCount() {
        var g = cap()
        var c = ContractState()
        c.okByOwner = ["jiwoo": 2, "chen": 1]
        c.okWho = 2
        c.rel = -2
        c.offer = ContractOffer(owner: .jiwoo, n: 14, price: 150, day: g.state.day + 3, len: 2, fogP: nil, made: g.state.day, seen: nil, first: false, top: 160, negotiated: false)
        g.state.local.contracts = c
        g.declineContract()
        c = g.state.local.contracts!
        XCTAssertEqual(c.gone, [.jiwoo])
        XCTAssertEqual(c.okByOwner?["jiwoo"], 0)
        XCTAssertEqual(c.okByOwner?["chen"], 1)
        XCTAssertEqual(g.state.contractOwner, .chen)
        XCTAssertEqual(g.state.contractOk(with: .chen), 1)
    }

    // MARK: v126.1: the vehicle arrives once

    func testVehicleArrivesOnceAndStays() {
        var g = cap()
        let k = book(&g)
        XCTAssertEqual(g.state.contractDue?.id, k.id)
        g.markContractArrived()
        XCTAssertNil(g.state.contractDue)
        XCTAssertEqual(g.state.contractParked.map(\.id), [k.id])
        // the second day: still there, no second arrival
        _ = run(&g)
        XCTAssertNil(g.state.contractDue)
        XCTAssertEqual(g.state.contractParked.map(\.id), [k.id])
        // a job moved by a late plane that landed after all: it stays, no arrival tomorrow
        var (h, hk) = lateJob(lands: true)
        h.markContractArrived()
        h.chooseContractDelay(.open)
        XCTAssertEqual(h.state.contractParked.map(\.id), [hk.id], "parked on a day it doesn't fly")
        _ = run(&h)
        XCTAssertNil(h.state.contractDue)
        // a plane that didn't come lands the next day, once
        var (m, mk) = lateJob(lands: false)
        m.chooseContractDelay(.hold)
        XCTAssertNil(m.state.contractDue, "not today: the job starts tomorrow")
        _ = run(&m)
        XCTAssertEqual(m.state.contractDue?.id, mk.id)
        m.markContractArrived()
        XCTAssertNil(m.state.contractDue)
    }

    func testRedFlagMoveKeepsTheCoachesArrived() {
        var g = abq()
        let k = book(&g, n: 30, price: 150, owner: .rosa)
        g.state.local.contracts?.booked[0].len = 1
        g.markContractArrived()
        g.state.weather?.flag = .red
        g.contractMorning()
        XCTAssertEqual(job(g, k.id)?.day, k.day + 1)
        g.state.day += 1
        XCTAssertNil(g.state.contractDue, "no second arrival")
        XCTAssertEqual(g.state.contractParked.map(\.id), [k.id])
    }

    func testDepartureStartsOnce() {
        var g = cap()
        g.state.local.contracts = ContractState()
        g.state.local.contracts?.depart = ContractDepart(owner: .jiwoo, n: 14, from: g.state.day)
        g.markContractLeaving()
        XCTAssertEqual(g.state.local.contracts?.depart?.leaving, true)
        g.clearContractDepart()
        XCTAssertNil(g.state.local.contracts?.depart)
    }

    func testAlbuquerqueSceneIsShortAfterCappadocia() {
        var g = abq()
        XCTAssertFalse(g.state.contractSceneShort)
        var c = ContractState()
        c.taken = 1
        g.state.parked[.cap]?.state.contracts = c
        XCTAssertTrue(g.state.contractSceneShort)
    }

    /// Albuquerque, entered from a Cappadocia baron, chapter 2.
    func abq() -> Game {
        var g = cap(day: 100, sizes: [.M, .L, .M, .L])
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 5_000_000
        g.state.barons[.cap] = g.state.day
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.transferAsk = nil
        g.state.local.chapter = 1
        g.state.local.balloons = [Balloon(id: 900, size: .L, name: "A"), Balloon(id: 901, size: .L, name: "B")]
        g.state.local.pilots = [Pilot(id: 950, name: "P", level: .experienced), Pilot(id: 951, name: "Q", level: .experienced)]
        g.state.local.flagship = 900
        g.state.local.selfFly = false
        g.assignPilots()
        return g
    }

    func run(_ g: inout Game, skip: Bool = false) -> DayReport {
        _ = g.launch(skip: skip)
        return g.finishDay(flight: nil)
    }
}
