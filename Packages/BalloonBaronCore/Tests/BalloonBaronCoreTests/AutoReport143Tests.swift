import XCTest
@testable import BalloonBaronCore

/// v143: the autopilot report. Leaving a region keeps its last 14 days' report lines on average with the fleet and the
/// prices; each evening keeps how its autopilot money was worked out, adding up to what the holding booked; the last
/// seven evenings are kept for the sparkline; older saves load without any of it.
final class AutoReport143Tests: XCTestCase {
    /// Baron of Cappadocia with a small fleet and pilots, the World Tour bought, money in the holding.
    func company(seed: UInt64 = 11) -> Game {
        var g = Game(company: "Report Air", colors: Rules.palettes[0], seed: seed)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 2_000_000
        g.state.cash = 200_000
        g.state.local.balloons = [Balloon(id: 900, size: .M, name: "A"), Balloon(id: 901, size: .M, name: "B"), Balloon(id: 902, size: .L, name: "C")]
        g.state.local.flagship = 900
        g.state.local.pilots = [Pilot(id: 950, name: "P1", level: .experienced, xp: 40), Pilot(id: 951, name: "P2", level: .experienced, xp: 40)]
        g.assignPilots()
        return g
    }

    @discardableResult
    func play(_ g: inout Game, _ n: Int) -> [DayReport] {
        var out: [DayReport] = []
        for _ in 0..<n {
            g.state.hezQueue = []
            if g.launch() != nil { out.append(g.finishDay(flight: FlightResult(landing: .good, distance: 120))) }
            else { out.append(g.finishDay(flight: nil)) }
        }
        return out
    }

    func testSnapshotMatchesTheLastFourteenDays() throws {
        var g = company()
        let reports = play(&g, 20)
        let last = Array(reports.suffix(14))
        XCTAssertEqual(g.state.local.recentDays?.count, 14, "a rolling 14 days")
        let day = g.state.day
        g.state.barons[.abq] = nil
        XCTAssertTrue(g.enterRegion(.abq))
        let snap = try XCTUnwrap(g.state.parked[.cap]?.auto.left)
        XCTAssertEqual(snap.day, day)
        XCTAssertEqual(snap.days, 14)
        func avg(_ f: (DayReport) -> Int) -> Int { jsRound(Double(last.reduce(0) { $0 + f($1) }) / 14) }
        XCTAssertEqual(snap.avg.net, avg { $0.net - ($0.ledger.showRefund ?? 0) })
        XCTAssertEqual(snap.avg.tickets, avg { $0.ledger.tickets + ($0.ledger.evening ?? 0) })
        XCTAssertEqual(snap.avg.fuel, avg { $0.ledger.fuel })
        XCTAssertEqual(snap.avg.wages, avg { $0.ledger.wages })
        XCTAssertEqual(snap.avg.upkeep, avg { $0.ledger.upkeep })
        XCTAssertEqual(snap.avg.insurance, avg { $0.ledger.insurance })
        XCTAssertEqual(snap.avg.tips, avg { $0.ledger.tips })
        XCTAssertEqual(snap.avg.named + snap.avg.other, snap.avg.net, "the lines add up to the net")
        let pax = last.reduce(0) { $0 + $1.passengers }, cap = last.reduce(0) { $0 + $1.capacity }
        XCTAssertGreaterThan(cap, 0)
        XCTAssertEqual(try XCTUnwrap(snap.occupancy), min(1, Double(pax) / Double(cap)), accuracy: 1e-9)
        let cap0 = g.state.parked[.cap]!.state
        XCTAssertEqual(snap.balloons, cap0.balloons.count)
        XCTAssertEqual(snap.pilots, cap0.pilots.count)
        XCTAssertEqual(snap.seats, cap0.balloons.reduce(0) { $0 + $1.size.capacity })
        XCTAssertEqual(snap.price, cap0.price)
        let rp = cap0.rivals.filter(\.alive).map(\.price)
        XCTAssertEqual(snap.rivalMin, rp.min())
        // and the base comes from the same days' net (85% of the median), as before
        let med = cap0.netHistory.suffix(14).sorted()[7]
        XCTAssertEqual(g.state.parked[.cap]!.auto.base, Double(max(0, med)) / RegionID.cap.fx * Holding.autopilotEfficiency, accuracy: 1e-6)
    }

    func testTheEveningBreakdownAddsUpToWhatTheHoldingBooked() throws {
        var g = company(seed: 5)
        play(&g, 16)
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.barons[.abq] = g.state.day
        play(&g, 16)
        g.switchRegion(.cap)
        // Cappadocia is here again, Albuquerque parked; enter Luxor too so two regions send
        g.state.barons[.lux] = g.state.day
        g.state.barons[.bri] = nil
        XCTAssertTrue(g.enterRegion(.lux))
        XCTAssertEqual(Set(g.state.parked.keys), [.cap, .abq])
        // campaigns, an office and R&D, so the factors show
        _ = g.runBillboards(in: .cap)
        _ = g.runTVCampaign(in: .abq)
        _ = g.openOffice(.ist)
        _ = g.fundResearch()
        for _ in 0..<5 {
            g.runAutopilots()
            _ = g.holdingDay()
            let h = g.state.holding
            let days = [RegionID.cap, .abq].compactMap { g.state.parked[$0]?.auto.lastDay }
            XCTAssertEqual(days.count, 2)
            XCTAssertTrue(days.allSatisfy { $0.day == g.state.day && $0.sent })
            XCTAssertEqual(days.reduce(0) { $0 + $1.gross }, h.todayGross)
            XCTAssertEqual(days.reduce(0) { $0 + $1.expense }, h.todayCost)
            XCTAssertEqual(days.reduce(0) { $0 + $1.rent }, h.todayRent ?? 0)
            XCTAssertEqual(days.reduce(0) { $0 + $1.net }, h.todayGross - h.todayCost - (h.todayRent ?? 0), "what reached the holding")
            for r in [RegionID.cap, .abq] {
                let a = try XCTUnwrap(g.state.parked[r]?.auto), d = try XCTUnwrap(a.lastDay)
                let product = d.factors.reduce(d.base * d.swing) { $0 * $1.mult }
                XCTAssertEqual(product, a.todayRaw * g.holdingBoost(r) * h.officeMultiplier(r), accuracy: 1e-6, "the factors are the whole multiplier")
                XCTAssertLessThanOrEqual(abs(Double(d.gross) - product), 1, "the gross is the region's rounded day")
                XCTAssertTrue(d.swing >= 0.85 && d.swing <= 1.15)
                XCTAssertEqual(a.week?.last, d.net)
            }
            XCTAssertTrue(g.state.parked[.cap]!.auto.lastDay!.factors.contains { $0.kind == .billboards && $0.mult == Holding.billboardBoost })
            XCTAssertTrue(g.state.parked[.cap]!.auto.lastDay!.factors.contains { $0.kind == .office && $0.mult == 1.25 })
            XCTAssertTrue(g.state.parked[.abq]!.auto.lastDay!.factors.contains { $0.kind == .tv })
            g.state.day += 1
        }
    }

    func testAKeptRegionsBreakdownIsWhatStayedInItsBox() throws {
        var g = company(seed: 9)
        play(&g, 15)
        g.setSendsToHolding(.cap, false)
        XCTAssertTrue(g.enterRegion(.abq))
        let c0 = g.state.parked[.cap]!.state.cash
        g.runAutopilots()
        _ = g.holdingDay()
        let a = try XCTUnwrap(g.state.parked[.cap]?.auto), d = try XCTUnwrap(a.lastDay)
        XCTAssertFalse(d.sent)
        XCTAssertEqual(d.kept, g.state.parked[.cap]!.state.cash - c0)
        XCTAssertEqual(d.kept, a.kept)
        XCTAssertEqual(d.net, d.gross - d.expense)
        XCTAssertEqual(d.rent, 0)
    }

    func testTheWeekRollsOverSevenEvenings() {
        var g = company(seed: 3)
        play(&g, 15)
        XCTAssertTrue(g.enterRegion(.abq))
        var nets: [Int] = []
        for _ in 0..<10 {
            g.runAutopilots()
            _ = g.holdingDay()
            nets.append(g.state.parked[.cap]!.auto.lastDay!.net)
            g.state.day += 1
        }
        XCTAssertEqual(g.state.parked[.cap]?.auto.week, Array(nets.suffix(7)))
    }

    func testPlayedDaysKeepTheirLinesAndATransferScalesTheSnapshot() throws {
        var g = company(seed: 21)
        let reports = play(&g, 3)
        let lines = try XCTUnwrap(g.state.local.recentDays)
        XCTAssertEqual(lines.count, 3)
        for (l, r) in zip(lines, reports) {
            XCTAssertEqual(l.net, r.net - (r.ledger.showRefund ?? 0))
            XCTAssertEqual(l.pax, r.passengers)
            XCTAssertEqual(l.seats, r.capacity)
            XCTAssertEqual(l.named + l.other, l.net)
        }
        play(&g, 12)
        XCTAssertTrue(g.enterRegion(.abq))
        let before = try XCTUnwrap(g.state.parked[.cap]?.auto.left)
        _ = g.applyTransfer(balloons: [900], pilots: [])
        let after = try XCTUnwrap(g.state.parked[.cap]?.auto.left)
        XCTAssertEqual(after.balloons, before.balloons - 1)
        XCTAssertLessThan(after.seats, before.seats)
        XCTAssertEqual(after.avg.named + after.avg.other, after.avg.net)
    }

    func testOldSavesDecodeWithoutTheReport() throws {
        var g = company(seed: 4)
        play(&g, 15)
        XCTAssertTrue(g.enterRegion(.abq))
        g.runAutopilots()
        _ = g.holdingDay()
        // strip every v143 key, as a save from 1.0 has it
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state)) as? [String: Any])
        func strip(_ o: Any) -> Any {
            if var d = o as? [String: Any] {
                for k in ["left", "lastDay", "week", "recentDays"] { d[k] = nil }
                for (k, v) in d { d[k] = strip(v) }
                return d
            }
            if let a = o as? [Any] { return a.map(strip) }
            return o
        }
        json = strip(json) as! [String: Any]
        let data = try JSONSerialization.data(withJSONObject: json)
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("recentDays"))
        let s = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertNil(s.parked[.cap]?.auto.left, "parked before v143: no snapshot, the report shows a note")
        XCTAssertNil(s.parked[.cap]?.auto.week)
        var back = Game(state: s)
        back.runAutopilots()
        _ = back.holdingDay()
        XCTAssertNotNil(back.state.parked[.cap]?.auto.lastDay, "the evening's breakdown starts at once")
        XCTAssertEqual(back.state.parked[.cap]?.auto.week?.count, 1)
    }
}
