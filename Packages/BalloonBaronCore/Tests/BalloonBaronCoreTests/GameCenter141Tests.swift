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
