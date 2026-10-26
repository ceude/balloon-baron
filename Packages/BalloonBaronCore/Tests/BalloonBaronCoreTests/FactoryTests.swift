import XCTest
@testable import BalloonBaronCore

/// v114: the balloon factory: workshop levels, your own balloons at half price, rival orders, the chapter 3 goal.
final class FactoryTests: XCTestCase {
    func newGame(seed: UInt64 = 7) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    func play(_ g: inout Game) {
        g.startDay()
        while g.nextHezarfen() != nil {}
        if g.launch() != nil { g.finishDay(flight: FlightResult(landing: .good, distance: 120)) } else { g.finishDay(flight: nil) }
    }

    func testLevelsOpenSizesAtHalfPrice() {
        var g = newGame()
        g.state.cash = 1_000_000
        XCTAssertEqual(g.state.factoryLevel, 0)
        XCTAssertFalse(g.upgradeFactory(), "workshop first")
        XCTAssertTrue(g.buildWorkshop())
        XCTAssertEqual(g.state.factoryLevel, 1)
        XCTAssertTrue(g.state.factorySizes.isEmpty)
        let cash = g.state.cash
        XCTAssertTrue(g.upgradeFactory())
        XCTAssertEqual(cash - g.state.cash, 30000)
        XCTAssertEqual(g.state.factorySizes, [.S])
        XCTAssertTrue(g.upgradeFactory()); XCTAssertTrue(g.upgradeFactory())
        XCTAssertEqual(g.state.factorySizes, [.S, .M, .L])
        XCTAssertNil(g.state.factoryNextCost)
        XCTAssertFalse(g.upgradeFactory())
        XCTAssertEqual(g.state.factoryCost(.M), 17500)
        XCTAssertEqual(g.state.factoryPrice(.M), 28000)
    }

    func testOwnBalloonArrivesAfterItsDays() {
        var g = newGame()
        g.state.cash = 200_000
        g.buildWorkshop(); g.upgradeFactory()
        let n = g.state.balloons.count
        XCTAssertFalse(g.buildBalloon(.M), "level 2 makes small ones only")
        XCTAssertTrue(g.buildBalloon(.S))
        XCTAssertFalse(g.buildBalloon(.S), "one at a time")
        XCTAssertEqual(g.state.value(.factoryBuilt), 0)
        for _ in 0..<2 { play(&g) }
        XCTAssertEqual(g.state.balloons.count, n, "not yet")
        play(&g)
        XCTAssertEqual(g.state.balloons.count, n + 1)
        XCTAssertEqual(g.state.factory?.made, 1)
        XCTAssertEqual(g.state.factory?.saved, 7500)
        XCTAssertEqual(g.state.value(.factoryBuilt), 1)
        XCTAssertFalse(g.state.factoryBusy)
    }

    func testRivalOrderPaysOnDeliveryAndGrowsTheRival() {
        var g = newGame()
        g.state.cash = 500_000
        g.buildWorkshop(); g.upgradeFactory(); g.upgradeFactory()
        let r = g.state.local.rivals[0]
        let o = FactoryOrder(rival: r.name, size: .M, price: g.state.factoryPrice(.M), until: g.state.day + 1)
        g.state.factory?.order = o
        XCTAssertTrue(g.state.factoryOrderDue)
        g.markFactoryOrderSeen()
        XCTAssertFalse(g.state.factoryOrderDue, "shown once")
        let before = r.balloons.count
        XCTAssertTrue(g.acceptFactoryOrder())
        XCTAssertTrue(g.state.factoryBusy)
        let cash = g.state.cash
        for _ in 0..<5 { play(&g) }
        let after = g.state.local.rivals.first { $0.name == r.name }!
        XCTAssertGreaterThanOrEqual(after.balloons.count, before + 1)
        XCTAssertEqual(g.state.factory?.orders, 1)
        XCTAssertEqual(g.state.factory?.earned, 28000 - 17500)
        XCTAssertGreaterThan(g.state.cash, cash - 50000, "the price came in")
    }

    func testDeclinedOrUnansweredOrderLapses() {
        var g = newGame()
        g.state.cash = 500_000
        g.buildWorkshop(); g.upgradeFactory(); g.upgradeFactory()
        let o1 = FactoryOrder(rival: g.state.local.rivals[0].name, size: .M, price: 28000, until: g.state.day)
        g.state.factory?.order = o1
        g.declineFactoryOrder()
        XCTAssertNil(g.state.factory?.order)
        g.state.factory?.order = o1
        play(&g)
        XCTAssertNotEqual(g.state.factory?.order, o1, "lapsed overnight")
    }

    func testOrdersComeNowAndThenWhileTheLineIsFree() {
        var g = newGame(seed: 11)
        g.state.cash = 2_000_000
        g.buildWorkshop(); g.upgradeFactory(); g.upgradeFactory()
        var asked = 0
        for _ in 0..<120 {
            if g.state.factory?.order != nil { asked += 1; g.declineFactoryOrder() }
            play(&g)
        }
        XCTAssertGreaterThan(asked, 2)
        XCTAssertLessThan(asked, 25)
    }

    func testChapterThreeAsksForAFactoryBalloon() {
        let goals = Chapter.all(in: .cap)[2].goals.map(\.kind)
        XCTAssertTrue(goals.contains(.factoryBuilt))
        XCTAssertFalse(goals.contains(.workshop))
    }

    func testOldSavesDecodeWithoutAFactory() throws {
        var g = newGame()
        g.state.cash = 200_000
        g.buildWorkshop()
        var json = String(decoding: try JSONEncoder().encode(g.state), as: UTF8.self)
        json = json.replacingOccurrences(of: ",\"factory\":null", with: "")
        let s = try JSONDecoder().decode(GameState.self, from: Data(json.utf8))
        XCTAssertNil(s.factory)
        XCTAssertEqual(s.factoryLevel, 1)
    }
}
