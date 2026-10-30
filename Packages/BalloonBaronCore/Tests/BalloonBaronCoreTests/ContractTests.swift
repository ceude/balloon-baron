import XCTest
@testable import BalloonBaronCore

/// Prototype v125–v125.3: corporate contracts in Albuquerque, Luxor and Bristol, and bringing the fleet into a new region.
final class ContractTests: XCTestCase {
    func newGame(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    /// Playing in `r` (entered after the regions before it), chapter 2, with a mid fleet and a pilot for each balloon.
    func inRegion(_ r: RegionID, seed: UInt64 = 42, sizes: [BalloonSize] = [.M, .L, .M, .L, .M, .L, .M]) -> Game {
        var g = newGame(seed: seed)
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 5_000_000
        let path: [RegionID] = [.abq, .lux, .bri]
        for x in path {
            g.state.barons[x.unlockedBy!] = g.state.day
            XCTAssertTrue(g.enterRegion(x))
            g.state.transferAsk = nil
            if x == r { break }
        }
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
        g.assignPilots()
        return g
    }

    func setFlag(_ g: inout Game, _ f: Flag, fog: Bool = false) {
        g.state.weather?.flag = f
        g.state.weather?.fog = fog ? Fog(top: 120) : nil
    }

    /// A job of yours starting today.
    func book(_ g: inout Game, n: Int, price: Int = 150, len: Int = 1, fogP: [Double]? = nil, owner: ContractOwner? = nil) -> ContractJob {
        var c = g.state.local.contracts ?? ContractState()
        let k = ContractJob(id: g.state.nextID, owner: owner ?? g.state.contractOwner!, n: n, price: price, day: g.state.day, len: len, fogP: fogP)
        g.state.nextID += 1
        c.booked.append(k)
        c.next = g.state.day + 100
        g.state.local.contracts = c
        return k
    }

    /// Flies (or not) and ends the day.
    func run(_ g: inout Game, skip: Bool = false) -> DayReport {
        _ = g.launch(skip: skip)
        return g.finishDay(flight: nil)
    }

    // MARK: Offers

    func testNoContractsInCappadocia() {
        var g = newGame()
        g.state.local.chapter = 2
        g.contractMorning()
        XCTAssertNil(g.state.local.contracts)
        XCTAssertNil(RegionID.cap.contracts)
    }

    func testOfferRangesPerRegion() {
        for r in [RegionID.abq, .lux, .bri] {
            let K = r.contracts!
            for seed in UInt64(1)...25 {
                var g = inRegion(r, seed: seed)
                setFlag(&g, .green)
                g.state.local.contracts = ContractState()
                g.state.local.contracts?.next = g.state.day
                g.contractMorning()
                guard let o = g.state.local.contracts?.offer else { return XCTFail("\(r) no offer (seed \(seed))") }
                let seats = g.state.fleetSeats
                XCTAssertGreaterThanOrEqual(o.n, max(12, Int(Double(seats) * K.share.lowerBound) - 2), "\(r)")
                XCTAssertLessThanOrEqual(o.n, max(12, Int(Double(seats) * K.share.upperBound) + 2), "\(r)")
                XCTAssertEqual(o.n % 2, 0)
                XCTAssertTrue(K.cast.contains(o.owner))
                XCTAssertEqual(o.owner, K.cast[0], "the first owner calls first")
                XCTAssertTrue(o.first)
                XCTAssertLessThanOrEqual(o.price, o.top, "never above the market")
                XCTAssertLessThanOrEqual(o.top, g.state.price, "nor above your ticket")
                XCTAssertEqual(o.price % 5, 0)
                XCTAssertEqual(o.top % 5, 0)
                XCTAssertGreaterThanOrEqual(Double(o.len), K.len.lowerBound)
                XCTAssertLessThanOrEqual(Double(o.len), K.len.upperBound)
                let lead = o.day - g.state.day
                XCTAssertGreaterThanOrEqual(Double(lead), K.lead.lowerBound)
                if K.weekend {
                    XCTAssertEqual(weekday(o.day), 5, "Bristol's weekends start on a Saturday")
                    XCTAssertEqual(o.fogP?.count, 2)
                    for p in o.fogP ?? [] {
                        XCTAssertGreaterThanOrEqual(p, 0.05 - 1e-9)
                        XCTAssertLessThanOrEqual(p, 0.45 + 1e-9)
                        XCTAssertEqual((p * 20).rounded(), p * 20, accuracy: 1e-9)
                    }
                } else {
                    XCTAssertLessThanOrEqual(Double(lead), K.lead.upperBound)
                    XCTAssertNil(o.fogP)
                }
            }
        }
    }

    func testWeekdays() {
        XCTAssertEqual(weekday(1), 0) // Monday
        XCTAssertEqual(weekday(6), 5) // Saturday
        XCTAssertEqual(weekday(7), 6)
        XCTAssertEqual(weekday(8), 0)
    }

    func testOfferNeedsChapterTwoAndSeats() {
        var g = inRegion(.abq)
        g.state.local.chapter = 0
        g.contractMorning()
        XCTAssertNil(g.state.local.contracts?.offer, "chapter 2 first")
        g.state.local.chapter = 1
        g.contractMorning()
        XCTAssertNil(g.state.local.contracts?.offer, "the first offer comes the morning after")
        XCTAssertEqual(g.state.local.contracts?.next, g.state.day + 1)
        g.state.local.balloons = Array(g.state.local.balloons.prefix(1)) // 16 seats < 40
        g.state.local.contracts?.next = g.state.day
        g.contractMorning()
        XCTAssertNil(g.state.local.contracts?.offer)
    }

    func testUnansweredOfferLapsesToRival() {
        var g = inRegion(.abq)
        g.state.local.contracts = ContractState()
        g.state.local.contracts?.next = g.state.day
        g.contractMorning()
        let o = g.state.local.contracts!.offer!
        g.state.day += 1
        g.contractMorning()
        let c = g.state.local.contracts!
        XCTAssertNil(c.offer)
        XCTAssertEqual(c.rel, -1)
        XCTAssertTrue(c.met)
        XCTAssertEqual(c.booked.first?.rival, g.state.contractRival?.name)
        XCTAssertEqual(c.booked.first?.n, o.n)
    }

    func testNegotiatedPriceStaysUnderTheMarket() {
        var g = inRegion(.abq)
        let o = ContractOffer(owner: .rosa, n: 30, price: 150, day: g.state.day + 3, len: 1, fogP: nil, made: g.state.day, seen: nil, first: false, top: 160, negotiated: false)
        XCTAssertEqual(g.state.negotiatedPrice(o), 160, "10% more, capped at the reference")
        var o2 = o
        o2.top = 200
        XCTAssertEqual(g.state.negotiatedPrice(o2), 165)
        var o3 = o
        o3.top = 150
        XCTAssertEqual(g.state.negotiatedPrice(o3), 150, "at the cap: nothing to negotiate")
        g.state.local.contracts = ContractState()
        g.state.local.contracts?.offer = o
        var walked = 0, ok = 0
        for seed in UInt64(0)..<200 {
            var h = g
            h.rng = SplitMix64(seed: seed)
            switch h.negotiateContract() {
            case true?:
                ok += 1
                XCTAssertEqual(h.state.local.contracts?.offer?.price, 160)
                XCTAssertNil(h.negotiateContract(), "once")
            case false?:
                walked += 1
                XCTAssertNil(h.state.local.contracts?.offer)
                XCTAssertEqual(h.state.local.contracts?.booked.first?.rival, h.state.contractRival?.name)
            case nil: XCTFail()
            }
        }
        XCTAssertEqual(Double(walked) / 200, 0.35, accuracy: 0.1)
        XCTAssertGreaterThan(ok, 0)
    }

    // MARK: Settling

    func testOneDayGroupFliesFirstAndPays() {
        var g = inRegion(.abq)
        setFlag(&g, .green)
        let k = book(&g, n: 40, price: 150)
        XCTAssertEqual(g.state.contractHeld(capacity: 200), 40)
        let est = g.estimatedIncome()
        XCTAssertGreaterThanOrEqual(est.pax, 40)
        _ = g.launch()
        XCTAssertEqual(g.state.local.plan?.contract?.held, 40)
        XCTAssertEqual(g.state.local.plan?.contract?.job, k.id)
        let r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.contract, 6000)
        XCTAssertEqual(r.ledger.contractN, 40)
        XCTAssertNil(r.ledger.contractPenalty)
        XCTAssertTrue(r.events.contains(.contractFlown(company: k.owner.company, dayN: 0, len: 0, n: 40, price: 150, total: 6000)))
        XCTAssertTrue(r.events.contains(.contractProgress(owner: .rosa, ok: 1, need: 3)))
        let c = g.state.local.contracts!
        XCTAssertEqual(c.ok, 1)
        XCTAssertEqual(c.rel, 1)
        XCTAssertFalse(c.booked.contains { $0.id == k.id })
        XCTAssertEqual(c.depart?.owner, .rosa)
        XCTAssertEqual(c.depart?.from, k.day + 1)
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.rosa, .thanks, n: 0, price: 0)))
        XCTAssertEqual(g.state.value(.ctrDone), 1)
    }

    func testShortfallCostsAndGoesToRival() {
        var g = inRegion(.abq, sizes: [.M, .M, .M]) // 48 seats
        setFlag(&g, .green)
        let rival = g.state.contractRival!
        let ri = g.state.rivals.firstIndex { $0.id == rival.id }!
        let rep0 = g.state.rivals[ri].rep, b0 = g.state.rivals[ri].balloons.count
        _ = book(&g, n: 60, price: 150)
        let r = run(&g)
        XCTAssertEqual(r.ledger.contractN, 48)
        XCTAssertEqual(r.ledger.contractPenalty, 12 * 75)
        XCTAssertTrue(r.events.contains(.contractShort(short: 12, perSeat: 75, total: 900)))
        XCTAssertTrue(r.events.contains(.contractTrustDown(owner: .rosa, short: 12)))
        XCTAssertEqual(r.repWhy?[.contract] ?? 0, -0.02, accuracy: 1e-9)
        let c = g.state.local.contracts!
        XCTAssertEqual(c.fail, 1)
        XCTAssertEqual(c.rel, -1, "48 of 60 flew: 80% ≥ 75%")
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.rosa, .fail, n: 0, price: 0)))
        // the missing 12 flew with the rival, who got a bit more popular (12 people: no balloon)
        XCTAssertTrue(r.rivalEvents.contains(.rivalFlewGroup(rival: rival.name, company: "Mother Road Coaches", n: 12, len: 1, balloons: 0)))
        XCTAssertGreaterThan(g.state.rivals[ri].rep, rep0 - 0.2)
        XCTAssertEqual(g.state.rivals[ri].balloons.count, b0)
    }

    func testSkippingAContractDayCostsEverySeat() {
        var g = inRegion(.abq)
        setFlag(&g, .yellow)
        _ = book(&g, n: 30, price: 100)
        let r = run(&g, skip: true)
        XCTAssertEqual(r.ledger.contractPenalty, 30 * 50)
        XCTAssertEqual(g.state.local.contracts?.rel, -2, "none flew")
    }

    func testRedFlagMovesAnAlbuquerqueGroup() {
        var g = inRegion(.abq)
        let k = book(&g, n: 30, price: 150)
        setFlag(&g, .red)
        g.contractMorning()
        var j = g.state.local.contracts!.booked.first { $0.id == k.id }!
        XCTAssertEqual(j.day, k.day + 1)
        XCTAssertEqual(j.price, 120, "20% off on the first move")
        XCTAssertEqual(j.moves, 1)
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.rosa, .red, n: 0, price: 120)))
        // the second red morning moves it again without a cut; the third sends the tour home
        g.state.day += 1
        g.contractMorning()
        j = g.state.local.contracts!.booked.first { $0.id == k.id }!
        XCTAssertEqual(j.price, 120)
        XCTAssertEqual(j.day, k.day + 2)
        g.state.day += 1
        g.contractMorning()
        XCTAssertNil(g.state.local.contracts!.booked.first { $0.id == k.id })
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.rosa, .redCancel, n: 0, price: 0)))
    }

    func testRedMorningOfALuxorBlockIsSkipped() {
        var g = inRegion(.lux)
        let k = book(&g, n: 20, price: 140, len: 4)
        setFlag(&g, .red)
        g.contractMorning()
        XCTAssertEqual(g.state.local.contracts!.booked.first { $0.id == k.id }?.day, k.day, "a block doesn't move")
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.farouk, .redSkip, n: 20, price: 140)))
        XCTAssertEqual(g.state.contractHeld(capacity: 100), 0)
        let r = run(&g, skip: true)
        XCTAssertNil(r.ledger.contractPenalty, "a red morning isn't counted")
        XCTAssertTrue(r.events.contains(.contractRed(company: "Sobek Nile Cruises")))
        let j = g.state.local.contracts!.booked.first { $0.id == k.id }!
        XCTAssertEqual(j.flown, 0)
    }

    func testLuxorBlockIsJudgedOnItsLastDay() {
        var g = inRegion(.lux)
        let k = book(&g, n: 20, price: 140, len: 4)
        for i in 0..<4 {
            setFlag(&g, .green)
            g.state.local.contracts?.next = g.state.day + 100
            let r = run(&g)
            XCTAssertEqual(r.ledger.contract, 20 * 140)
            XCTAssertTrue(r.events.contains(.contractFlown(company: "Sobek Nile Cruises", dayN: i + 1, len: 4, n: 20, price: 140, total: 2800)))
            XCTAssertEqual(g.state.local.contracts?.ok, i == 3 ? 1 : 0)
        }
        XCTAssertNil(g.state.local.contracts!.booked.first { $0.id == k.id })
    }

    func testBristolFogGuarantee() {
        var g = inRegion(.bri)
        while weekday(g.state.day) != 5 { g.state.day += 1 }
        let k = book(&g, n: 30, price: 180, len: 2, fogP: [1, 0])
        setFlag(&g, .green)
        g.contractMorning()
        XCTAssertNotNil(g.state.weather?.fog, "the forecast decides the fog: 100%")
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.nigel, .fog, n: 0, price: 0)))
        XCTAssertEqual(g.state.contractHeld(capacity: 100), 0)
        let r = run(&g)
        XCTAssertEqual(r.ledger.contractVoucher, jsRound(30 * 180 * 0.15))
        XCTAssertNil(r.ledger.contractPenalty)
        XCTAssertTrue(r.events.contains(.contractFog(company: "West Country Weekenders", n: 30, voucher: 810)))
        // Sunday: no fog (0%), the group flies; the weekend counts as delivered
        setFlag(&g, .green)
        g.state.local.contracts?.next = g.state.day + 100
        g.contractMorning()
        XCTAssertNil(g.state.weather?.fog)
        let r2 = run(&g)
        XCTAssertEqual(r2.ledger.contract, 30 * 180)
        XCTAssertEqual(g.state.local.contracts?.ok, 1, "a foggy morning isn't a failure")
        XCTAssertNil(g.state.local.contracts!.booked.first { $0.id == k.id })
    }

    func testJobThatNeverFlewIsNobodysFault() {
        var g = inRegion(.lux)
        _ = book(&g, n: 20, price: 140, len: 1)
        setFlag(&g, .red)
        let r = run(&g, skip: true)
        XCTAssertTrue(r.events.contains(.contractWeather(company: "Sobek Nile Cruises")))
        XCTAssertEqual(g.state.local.contracts?.ok, 0)
        XCTAssertEqual(g.state.local.contracts?.fail, 0)
        XCTAssertEqual(g.state.local.contracts?.rel, 0)
    }

    // MARK: Relationship

    func testPreferredOperatorAfterThreeJobs() {
        var g = inRegion(.abq)
        for i in 0..<3 {
            setFlag(&g, .green)
            _ = book(&g, n: 30, price: 150)
            g.state.hezQueue = []
            let r = run(&g)
            XCTAssertEqual(g.state.local.contracts?.okWho, i + 1)
            if i < 2 { XCTAssertTrue(r.events.contains(.contractProgress(owner: .rosa, ok: i + 1, need: 3))) }
        }
        let c = g.state.local.contracts!
        XCTAssertTrue(c.pref)
        XCTAssertTrue(c.prefEver)
        XCTAssertEqual(c.rel, 3)
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.rosa, .pref, n: 0, price: 0)))
        XCTAssertTrue((g.state.paperNext ?? []).contains(.preferredOperator(company: "Mother Road Coaches", kind: .bus)) || (g.state.paper ?? []).contains(.preferredOperator(company: "Mother Road Coaches", kind: .bus)))
        XCTAssertEqual(g.state.value(.ctrPref), 1)
        // offers come sooner, a bit dearer; losing trust takes the title away
        var h = g
        h.state.local.contracts?.rel = 1
        h.state.local.contracts?.offer = ContractOffer(owner: .rosa, n: 30, price: 150, day: h.state.day + 3, len: 1, fogP: nil, made: h.state.day, seen: nil, first: false, top: 160, negotiated: false)
        h.declineContract()
        XCTAssertFalse(h.state.local.contracts!.pref)
        XCTAssertTrue(h.state.hezQueue.contains(.contract(.rosa, .lostPref, n: 0, price: 0)))
        let next = h.state.local.contracts!.next! - h.state.day
        XCTAssertTrue((6...9).contains(next), "the gap was set before the title went")
        var p = g
        p.state.local.contracts?.offer = ContractOffer(owner: .rosa, n: 30, price: 150, day: p.state.day + 3, len: 1, fogP: nil, made: p.state.day, seen: nil, first: false, top: 160, negotiated: false)
        p.acceptContract()
        XCTAssertTrue((6...9).contains(p.state.local.contracts!.next! - p.state.day), "the preferred operator hears sooner")
    }

    func testOwnerBreaksOffAndTheNextOneComes() {
        var g = inRegion(.abq)
        g.state.local.contracts = ContractState()
        for _ in 0..<3 {
            g.state.local.contracts?.offer = ContractOffer(owner: .rosa, n: 30, price: 150, day: g.state.day + 3, len: 1, fogP: nil, made: g.state.day, seen: nil, first: false, top: 160, negotiated: false)
            g.declineContract()
        }
        let c = g.state.local.contracts!
        XCTAssertEqual(c.gone, [.rosa])
        XCTAssertEqual(c.who, 1)
        XCTAssertEqual(c.rel, 0)
        XCTAssertFalse(c.met)
        XCTAssertEqual(c.next, g.state.day + 14)
        XCTAssertEqual(g.state.contractOwner, .hank)
        XCTAssertTrue(g.state.hezQueue.contains(.contract(.rosa, .bye, n: 0, price: 0)))
    }

    func testRivalGrowsWithAGroupYouDidntTake() {
        var g = inRegion(.abq)
        setFlag(&g, .green)
        let rival = g.state.contractRival!
        let ri = g.state.rivals.firstIndex { $0.id == rival.id }!
        let b0 = g.state.rivals[ri].balloons.count, rep0 = g.state.rivals[ri].rep
        g.state.local.contracts = ContractState()
        g.state.local.contracts?.next = g.state.day + 100
        g.state.local.contracts?.offer = ContractOffer(owner: .rosa, n: 50, price: 150, day: g.state.day, len: 1, fogP: nil, made: g.state.day, seen: nil, first: false, top: 160, negotiated: false)
        g.declineContract()
        _ = g.launch()
        let rp0 = g.state.local.plan!.rivalPax[ri]
        let r = g.finishDay(flight: nil)
        // 50 people: one balloon (24 or more), a second at 96
        XCTAssertEqual(g.state.rivals[ri].balloons.count - b0, 1)
        XCTAssertTrue(r.rivalEvents.contains(.rivalFlewGroup(rival: rival.name, company: "Mother Road Coaches", n: 50, len: 1, balloons: 1)))
        XCTAssertTrue((g.state.paper ?? []).contains(.rivalGroup(rival: rival.name, company: "Mother Road Coaches", n: 50, len: 1, balloons: 1, kind: .bus))
                      || (g.state.paperNext ?? []).contains(.rivalGroup(rival: rival.name, company: "Mother Road Coaches", n: 50, len: 1, balloons: 1, kind: .bus)))
        XCTAssertEqual(g.state.lastShare?.rivals[ri], rp0 + 50, "the group counts as the rival's passengers")
        XCTAssertNotEqual(g.state.rivals[ri].rep, rep0)
    }

    // MARK: Goals

    func testChapterGoalsAskForContracts() {
        func goals(_ r: RegionID, _ i: Int) -> [GoalKind: Double] {
            Dictionary(r.chapters[i].goals.map { ($0.kind, $0.target) }, uniquingKeysWith: { a, _ in a })
        }
        for r in [RegionID.abq, .lux, .bri] {
            XCTAssertEqual(goals(r, 1)[.ctrDone], 2, "\(r)")
            XCTAssertNil(goals(r, 1)[.bldMast], "\(r): the wind mast level 3 made way")
            XCTAssertEqual(goals(r, 2)[.ctrDone], 3, "\(r)")
        }
        XCTAssertNil(goals(.cap, 1)[.ctrDone])
    }

    // MARK: Bringing the fleet

    func testTransferLimitsAndArrival() {
        var g = newGame()
        g.grantStoreItem(.worldTour)
        g.state.barons[.cap] = 1
        g.state.holding.cash = 1_000_000
        g.state.local.balloons = []
        for (i, z) in [BalloonSize.L, .M, .M, .S, .S, .XL].enumerated() {
            g.state.local.balloons.append(Balloon(id: 500 + i, size: z, name: "C\(i)"))
        }
        g.state.local.flagship = 501
        g.state.local.pilots = (0..<4).map { Pilot(id: 600 + $0, name: "Pilot\($0)", level: $0 == 2 ? .senior : .experienced, xp: Double($0)) }
        g.state.local.netHistory = Array(repeating: 5000, count: 14)
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.transferAsk, .abq)
        let bs = g.transferBalloons
        XCTAssertTrue(bs.allSatisfy { [.S, .M].contains($0.balloon.size) }, "large baskets don't travel")
        XCTAssertEqual(bs.first?.balloon.size, .M)
        let def = g.transferDefaults
        XCTAssertEqual(def.balloons.count, 1, "one medium basket fills the 16 seats")
        XCTAssertEqual(def.pilots.first, 602, "the most senior first")
        XCTAssertEqual(def.pilots.count, 2)
        let base0 = g.state.parked[.cap]!.auto.base
        let inc = g.transferIncome(.cap, balloons: def.balloons, pilots: def.pilots)
        XCTAssertLessThan(inc.after, inc.now)
        // asking for too much brings only what fits
        let names = g.applyTransfer(balloons: [501, 502, 503], pilots: [600, 601, 602])
        XCTAssertEqual(names.pilots.count, 2)
        XCTAssertEqual(names.balloons.count, 1)
        XCTAssertNil(g.state.transferAsk)
        XCTAssertEqual(g.state.local.pilots.filter { $0.imported == .cap }.count, 2, "pilots come at once")
        XCTAssertEqual(g.state.local.transferShip?.day, g.state.day + 10)
        XCTAssertEqual(g.state.local.balloons.count, 1, "balloons come by cargo")
        XCTAssertEqual(g.state.parked[.cap]!.state.balloons.count, 5)
        XCTAssertEqual(g.state.parked[.cap]!.state.pilots.count, 2)
        let s0 = 24 + 16 + 16 + 8 + 8 + 32
        XCTAssertEqual(g.state.parked[.cap]!.auto.base, Double(jsRound(base0 * (1 - 16.0 / Double(s0) - 0.04))), accuracy: 1)
        XCTAssertEqual(g.state.parked[.cap]!.state.flagship, g.state.parked[.cap]!.state.balloons.first?.id, "the flagship left: the first balloon is the flagship")
        if case .transferBrought(let ps, let b, let day)? = g.state.hezQueue.first {
            XCTAssertEqual(ps.count, 2); XCTAssertEqual(b.count, 1); XCTAssertEqual(day, g.state.day + 10)
        } else { XCTFail("Hezarfen tells what came") }
        // goals don't count what was brought
        XCTAssertEqual(g.state.value(.pilots), 0)
        let seats0 = g.state.value(.seats)
        // ten days later the cargo arrives and the payments start
        for _ in 0..<10 {
            g.state.hezQueue = []
            _ = g.launch(skip: true)
            _ = g.finishDay(flight: nil)
        }
        XCTAssertNil(g.state.local.transferShip)
        XCTAssertEqual(g.state.local.balloons.filter { $0.imported == .cap }.count, 1)
        XCTAssertEqual(g.state.value(.seats), seats0, "the brought balloon doesn't count")
        XCTAssertTrue(g.state.hezQueue.contains(.cargoArrived(["C1"])))
        let debt = g.state.local.transferDebt!
        XCTAssertEqual(debt.left, 30)
        XCTAssertEqual(debt.installment, jsRound(35000 * 1.1 / 30))
        let h0 = g.state.holding.cash
        _ = g.launch(skip: true)
        let r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.transfer, debt.installment)
        XCTAssertEqual(g.state.local.transferDebt?.left, 29)
        XCTAssertGreaterThanOrEqual(g.state.holding.cash - h0, jsRound(Double(debt.installment) / 1.1) - 1)
    }

    func testTransferedPilotWageFollowsTheRegion() {
        var g = newGame()
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 5_000_000
        for x in [RegionID.abq, .lux] {
            g.state.barons[x.unlockedBy!] = g.state.day
            XCTAssertTrue(g.enterRegion(x))
        }
        g.state.local.pilots = [Pilot(id: 900, name: "Nour", level: .senior)]
        g.state.barons[.lux] = g.state.day
        XCTAssertTrue(g.enterRegion(.bri))
        g.applyTransfer(balloons: [], pilots: [900])
        XCTAssertEqual(g.state.local.pilots.first { $0.id == 900 }?.wage, jsRound(240 * 1.15 / 5) * 5)
    }

    /// v125.5: entering a new region late in the game, no morning event comes before its welcome cards.
    func testNoMorningEventOnANewRegionsFirstDays() {
        var g = newGame()
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 1_000_000
        g.state.day = 140
        g.state.barons[.cap] = 1
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.local.nextEvent, 154)
        XCTAssertNotEqual(g.state.eventDue, true)
    }
}
