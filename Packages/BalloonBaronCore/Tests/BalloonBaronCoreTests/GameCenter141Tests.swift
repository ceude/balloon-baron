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
