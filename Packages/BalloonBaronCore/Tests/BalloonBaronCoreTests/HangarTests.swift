import XCTest
@testable import BalloonBaronCore

/// v127: the hangar's capacity, the balloons outside it, the warnings.
final class HangarTests: XCTestCase {
    /// A game on day 30 with `n` balloons (the flagship and `n - 1` more) and a pilot for each.
    func fleetGame(_ n: Int, hangar: Int = 1, seed: UInt64 = 5) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.day = 30
        g.state.lastSelfFly = 30
        g.state.cash = 100_000
        g.state.unlocked.formUnion([.fleet, .crew, .market])
        for i in 1..<n { g.state.balloons.append(Balloon(id: 1000 + i, size: .M, name: "B\(i)")) }
        for i in 0..<n { g.state.pilots.append(Pilot(id: 5000 + i, name: "P \(i)", level: .experienced)) }
        if hangar > 1 { g.state.buildings = [.hangar: hangar] }
        g.assignPilots()
        return g
    }

    func testCapacityLevelsAndCosts() {
        XCTAssertEqual((1...8).map { lv -> Int in var r = RegionState(rivals: []); r.buildings = [.hangar: lv]; return r.hangarCapacity },
                       [6, 12, 24, 48, 96, 192, 384, 768])
        XCTAssertEqual(Building.hangar.maxLevel, 8)
        XCTAssertEqual(Building.mast.maxLevel, 3)
        XCTAssertEqual((1...8).map { Building.hangar.upgradeCost(from: $0) },
                       [12000, 45000, 120_000, 350_000, 900_000, 2_400_000, 6_000_000, nil])
        XCTAssertNil(Building.office.upgradeCost(from: 3))
        var g = fleetGame(3)
        g.state.cash = 20_000_000
        for lv in 2...8 { XCTAssertTrue(g.upgrade(.hangar)); XCTAssertEqual(g.state.level(.hangar), lv) }
        XCTAssertFalse(g.upgrade(.hangar), "8 is the top")
        XCTAssertEqual(g.state.upkeepFactor, 0.7, "levels 4 to 8 keep level 3's upkeep cut")
        XCTAssertEqual(g.state.value(.bldHangar), 8)
        XCTAssertTrue(g.state.done(Goal(kind: .bldHangar, target: 3)), "the barons' hangar level 3 goal still holds")
    }

    func testNewestStandOutsideFlagshipAlwaysInside() {
        var g = fleetGame(9)
        let ids = g.state.balloons.map(\.id)
        XCTAssertEqual(g.state.outsideCount, 3)
        XCTAssertEqual(g.state.outsideIDs, Set(ids.suffix(3)))
        // The flagship bought last is still inside; the one before the cut goes out instead.
        g.state.flagship = ids[8]
        XCTAssertEqual(g.state.outsideIDs, Set(ids[5...7]))
        XCTAssertFalse(g.state.isOutside(g.state.balloons[8]))
        for b in g.state.balloons { XCTAssertEqual(g.state.isOutside(b), g.state.outsideIDs.contains(b.id)) }
        XCTAssertEqual(g.state.insideBalloons.count, 6)
        XCTAssertEqual(g.state.sortedFleet.suffix(3).map(\.id).sorted(), Array(ids[5...7]).sorted(), "outside ones at the bottom")
    }

    func testOutsideCannotFlyHasNoPilotAndCostsNoUpkeep() {
        var g = fleetGame(9)
        g.startDay()
        let out = g.state.outsideIDs
        XCTAssertEqual(out.count, 3)
        for b in g.state.balloons where out.contains(b.id) {
            XCTAssertEqual(g.state.status(b), .outside)
            XCTAssertNil(b.pilot)
        }
        XCTAssertEqual(g.state.flyingToday.count, 6)
        XCTAssertEqual(g.state.idlePilots.count, 9 - 5, "the flagship flies itself; five pilots fly, the rest wait")
        XCTAssertEqual(g.state.fleetSeats, BalloonSize.S.capacity + 5 * 16, "the starting small flagship and five inside")
        XCTAssertEqual(g.state.value(.seats), Double(BalloonSize.S.capacity + 8 * 16), "goals count every owned seat")
        XCTAssertEqual(g.state.value(.balloons), 9)
        XCTAssertEqual(g.showFleet.count, 6)
        g.state.weather?.flag = .green
        _ = g.launch()
        let r = g.finishDay(flight: FlightResult(landing: .good, distance: 120))
        XCTAssertEqual(r.ledger.upkeep, BalloonSize.S.upkeep + 5 * BalloonSize.M.upkeep, "no upkeep outside")
        XCTAssertLessThanOrEqual(r.capacity, BalloonSize.S.capacity + 5 * 16)
    }

    func testUpgradeMovesThemInAndBuyingIsNotBlocked() {
        var g = fleetGame(6)
        XCTAssertEqual(g.state.outsideCount, 0)
        g.state.cash = 1_000_000
        XCTAssertTrue(g.buyBalloon(.S))
        XCTAssertEqual(g.state.outsideCount, 1)
        XCTAssertTrue(g.state.isOutside(g.state.balloons.last!))
        XCTAssertNotNil(g.hangarWarn(outsideBefore: 0))
        XCTAssertEqual(g.state.local.hangarReminder, g.state.day + Hangar.reminderDays)
        XCTAssertTrue(g.upgrade(.hangar))
        g.assignPilots()
        XCTAssertEqual(g.state.outsideCount, 0)
        XCTAssertNotNil(g.state.balloons.last?.pilot, "moved in and got a pilot")
    }

    func testForcedSkipLooksOnlyInside() {
        var g = fleetGame(8)
        g.startDay()
        for i in g.state.balloons.indices where !g.state.isOutside(g.state.balloons[i]) { g.state.balloons[i].damagedUntil = g.state.day + 2 }
        XCTAssertTrue(g.state.forcedSkip, "everything inside is in repair; the ones outside can't fly anyway")
    }

    func testReminderAtMostEveryFiveDays() {
        var g = fleetGame(8)
        var days: [Int] = []
        for _ in 0..<12 {
            g.startDay()
            if g.state.hezQueue.contains(.hangarOutside(2)) { days.append(g.state.day) }
            while g.nextHezarfen() != nil {}
            g.launch(skip: true)
            g.finishDay(flight: nil)
        }
        XCTAssertGreaterThanOrEqual(days.count, 2)
        XCTAssertTrue(zip(days, days.dropFirst()).allSatisfy { $1 - $0 >= Hangar.reminderDays }, "\(days)")
        var fits = fleetGame(6)
        fits.startDay()
        XCTAssertFalse(fits.state.hezQueue.contains { if case .hangarOutside = $0 { return true } else { return false } })
    }

    func testFactoryAndCargoWarnWhenTheyLeaveBalloonsOutside() {
        var g = fleetGame(6)
        g.state.factory = Factory()
        g.state.factory?.job = FactoryJob(size: .S, done: g.state.day + 1, region: g.state.region, rival: nil, price: 0)
        var ev: [DayEvent] = []
        g.factoryDay(&ev, tomorrow: g.state.day + 1)
        XCTAssertEqual(g.state.balloons.count, 7)
        XCTAssertTrue(g.state.hezQueue.contains(.hangarFull(1)))
        g.state.hezQueue = []
        g.state.local.transferShip = TransferShip(day: g.state.day, balloons: [Balloon(id: 9001, size: .M, name: "X"), Balloon(id: 9002, size: .M, name: "Y")])
        g.transferArrive()
        XCTAssertEqual(g.state.hezQueue.last, .hangarFull(3), "after the cargo's own card")
    }

    func testFourHundredBalloonsStayQuick() {
        var g = fleetGame(400, hangar: 3)
        XCTAssertEqual(g.state.outsideCount, 376)
        let t = Date()
        g.startDay()
        let sorted = g.state.sortedFleet
        let st = sorted.map { g.state.status($0) }
        XCTAssertEqual(st.filter { $0 == .outside }.count, 376)
        XCTAssertTrue(sorted.suffix(376).allSatisfy { g.state.isOutside($0) })
        XCTAssertEqual(g.state.flyingToday.count, 24)
        _ = g.launch(skip: true)
        g.finishDay(flight: nil)
        XCTAssertLessThan(Date().timeIntervalSince(t), 5, "a day with 400 balloons")
    }

    func testDefaultBalloonNameComesFromTheApp() {
        var g = fleetGame(1)
        let keep = Rules.defaultBalloonName
        defer { Rules.defaultBalloonName = keep }
        Rules.defaultBalloonName = { "Balon \($0)" }
        g.state.balloons += Rules.balloonNames.enumerated().map { Balloon(id: 3000 + $0.offset, size: .S, name: $0.element) }
        let id = g.state.nextID
        g.state.cash = 100_000
        XCTAssertTrue(g.buyBalloon(.S))
        XCTAssertEqual(g.state.balloons.last?.name, "Balon \(id)")
    }

    func testOldSaveWithoutReminderLoads() throws {
        let g = fleetGame(8)
        var data = try JSONEncoder().encode(g.state)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertFalse(String(data: data, encoding: .utf8)!.contains("hangarReminder"))
        json["_"] = nil
        data = try JSONSerialization.data(withJSONObject: json)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back.outsideCount, 2, "an old save keeps its level; the extra balloons are outside")
    }
}
