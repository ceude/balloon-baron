import XCTest
@testable import BalloonBaronCore

/// A hotel tug-of-war answered on the spot with "let it go": the hotel goes to a rival for a month, so it can't be
/// signed again the same day for three days' fee instead of the payment.
final class HotelIssueTests: XCTestCase {
    func testLetGoHotelIsLockedForAMonth() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 9)
        g.state.day = 200
        g.state.rep = 1.4
        g.state.cash = 500_000
        g.state.holding.cash = 1_000_000
        let h = Hotel.allCases.first { g.state.stars >= $0.minStars }!
        XCTAssertTrue(g.signHotel(h))
        g.state.local.openIssue = Autopilot.OpenIssue(kind: .hotel, day: g.state.day)
        XCTAssertEqual(g.issueCost(in: g.state.region, choice: .a), jsRound(Double(h.dailyFee * Rules.hotelKeepDays) / 100) * 100, "two months of that hotel's fee")
        XCTAssertTrue(g.resolveLiveIssue(.b))
        XCTAssertFalse(g.state.hotelDeals.contains(h))
        XCTAssertNotNil(g.hotelLockedByRival(h))
        XCTAssertFalse(g.signHotel(h), "no signing it back the same day")
        g.state.day += Rules.hotelLostDays
        XCTAssertTrue(g.signHotel(h), "after a month it's free again")
    }
}

final class HotelSaleTests: XCTestCase {
    func testOwnedHotelSellsForSixtyPercent() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 4)
        let h = Hotel.allCases[0]
        g.state.ownHotels = [h]
        let cash = g.state.cash
        XCTAssertEqual(g.rescueSellHotel, h)
        XCTAssertTrue(g.sellHotel(h))
        XCTAssertEqual(g.state.cash - cash, jsRound(Double(h.buyPrice) * 0.6 / 100) * 100)
        XCTAssertTrue(g.state.ownHotels.isEmpty)
        XCTAssertFalse(g.sellHotel(h), "only once")
        XCTAssertNil(g.rescueSellHotel)
    }
}
