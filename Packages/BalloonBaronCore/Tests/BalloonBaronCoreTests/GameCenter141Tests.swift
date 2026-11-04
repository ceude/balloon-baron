import XCTest
@testable import BalloonBaronCore

/// v141.1: every postcard is a Game Center achievement, and all of them fit Apple's 1000 points with room kept for a
/// future region's two postcards.
final class GameCenter141Tests: XCTestCase {
    func testPointsFitWithRoomForAFutureRegion() {
        let total = Achievement.allCases.reduce(0) { $0 + $1.gameCenterPoints }
        XCTAssertEqual(total, 880)
        XCTAssertLessThanOrEqual(total + Achievement.gameCenterReserve, Achievement.gameCenterLimit)
        XCTAssertGreaterThanOrEqual(Achievement.gameCenterReserve, 90, "room for an entry and a baron postcard")
    }

    func testEveryPostcardHasPointsInRange() {
        for a in Achievement.allCases {
            XCTAssertGreaterThanOrEqual(a.gameCenterPoints, 1, a.rawValue)
            XCTAssertLessThanOrEqual(a.gameCenterPoints, 100, a.rawValue)
        }
        XCTAssertEqual(Achievement.world.gameCenterPoints, 100)
        XCTAssertGreaterThan(Achievement.baronMara.gameCenterPoints, Achievement.baronBri.gameCenterPoints, "the hardest baron is worth the most")
    }
}

/// v141.1: the offices are listed İstanbul, Seoul, New York, London, Tokyo, Dubai, every office once.
final class OfficeOrder141Tests: XCTestCase {
    func testListedOrder() {
        XCTAssertEqual(Office.listed, [.ist, .sel, .nyc, .lon, .tyo, .dxb])
        XCTAssertEqual(Set(Office.listed), Set(Office.allCases))
        XCTAssertEqual(Office.lon.rawValue, "par", "the save key stays")
    }
}

/// v141.1 (developer): milder rains, a $10 park fee, a bigger reserve when sending the Mara's money away; still the hardest.
final class MaraBalance1411Tests: XCTestCase {
    func testMilderRainsAndTheFee() {
        XCTAssertEqual(Mara.parkFee, 10)
        XCTAssertEqual([Mara.longRains, Mara.shortRains, Mara.rainsEvery], [10, 5, 45])
        XCTAssertEqual(Mara.rainsDemand, 0.55)
        XCTAssertEqual(Mara.rainsGreen, 0.28); XCTAssertEqual(Mara.rainsYellow, 0.62)
        XCTAssertLessThan(Mara.rainsGreen, 0.35, "the rains still ground more mornings than any winter")
        XCTAssertEqual(Holding.withdrawKeep(.mara), 60000)
        XCTAssertEqual(Holding.withdrawKeep(.cap), 10000)
    }
}

extension Game {
    /// v141.2: the Maasai Mara entered and its first safari-plane group flown in full (it runs on autopilot).
    mutating func flewMaraGroup() {
        var st = newRegionState(.mara)
        var c = ContractState(); c.ok = 1
        st.contracts = c
        state.parked[.mara] = ParkedRegion(state: st, auto: Autopilot(base: 1000, since: state.day, lastIssue: state.day))
    }
}

extension HoldingGoal {
    /// The order the campaign simulator meets them on average (v141.2).
    static let order1412: [HoldingGoal] = [.million, .baronLux, .celebrity, .research, .offices, .worldGames, .maraGroup]
}

/// v141.2 (developer): the TV goal is gone; the Mara's first safari-plane group counts, there or on autopilot.
final class MaraGoal1412Tests: XCTestCase {
    func newGame() -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 42)
        g.startDay()
        return g
    }

    func testTheMarasFirstGroupIsAGoal() {
        var g = newGame()
        XCTAssertFalse(HoldingGoal.allCases.map(\.rawValue).contains("tv"))
        XCTAssertFalse(g.state.met(.maraGroup))
        g.state.holding.tvCount = 3
        XCTAssertFalse(g.state.met(.maraGroup), "TV campaigns no longer count")
        g.flewMaraGroup()
        XCTAssertTrue(g.state.met(.maraGroup))
        XCTAssertEqual(g.state.maraGroups, 1)
    }

    func testAWorldBaronWithoutTheMaraGroupLosesTheTitleOnLoad() throws {
        var g = newGame()
        g.state.barons = [.cap: 1, .abq: 2, .lux: 3, .bri: 4]
        g.state.holding.millionOn = 10
        g.state.holding.tvCount = 1
        g.state.holding.celebrity = Celebrity(index: 0, until: 100)
        g.state.holding.research = Holding.researchLevels.count
        for o in Office.allCases { g.state.holding.offices[o] = 1 }
        g.state.holding.worldGamesUntil = 60
        g.state.holding.worldBaron = 300
        g.state.postcards = [.world: 300]
        let data = try JSONEncoder().encode(g.state)
        var back = Game(state: try JSONDecoder().decode(GameState.self, from: data))
        back.state.migrate()
        XCTAssertNil(back.state.holding.worldBaron, "the Mara's first group is wanted now")
        XCTAssertEqual(back.state.postcards?[.world], 300, "the postcard stays in the album")
        back.flewMaraGroup()
        back.holdingGoalsNow()
        XCTAssertNotNil(back.state.holding.worldBaron)
    }
}
