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

    func testSoldHotelBelongsToTheStrongestRival() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 4)
        g.state.rep = 1.4
        let h = Hotel.allCases[1]
        g.state.ownHotels = [h]
        let top = g.state.rivals.filter(\.alive).max { $0.rep < $1.rep }!.name
        XCTAssertTrue(g.sellHotel(h))
        XCTAssertEqual(g.hotelRivalOwner(h), top)
        g.state.cash = 1_000_000
        XCTAssertFalse(g.signHotel(h), "no more deals with that hotel")
        XCTAssertEqual(g.hotelBuyPrice(h), jsRound(Double(h.buyPrice) * 1.1 / 100) * 100)
        let cash = g.state.cash, price = g.hotelBuyPrice(h)
        XCTAssertTrue(g.buyHotel(h))
        XCTAssertEqual(cash - g.state.cash, price)
        XCTAssertNil(g.hotelRivalOwner(h), "yours again")
    }

    func testBankruptOwnerOffersTheHotelCheap() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 4)
        let h = Hotel.allCases[1]
        g.state.ownHotels = [h]
        XCTAssertTrue(g.sellHotel(h))
        let owner = g.hotelRivalOwner(h)!
        g.rivalGone(owner, takenOver: false)
        XCTAssertNil(g.hotelRivalOwner(h))
        XCTAssertEqual(g.pendingHotelBargain?.price, jsRound(Double(h.buyPrice) * 0.7 / 100) * 100)
        g.state.cash = 1_000_000
        XCTAssertTrue(g.answerHotelBargain(buy: true))
        XCTAssertEqual(g.state.ownHotels, [h])
        XCTAssertNil(g.pendingHotelBargain)
    }

    func testTakingOverTheOwnerBringsTheHotelBack() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 4)
        let h = Hotel.allCases[0]
        g.state.ownHotels = [h]
        XCTAssertTrue(g.sellHotel(h))
        g.rivalGone(g.hotelRivalOwner(h)!, takenOver: true)
        XCTAssertEqual(g.state.ownHotels, [h])
        XCTAssertNil(g.pendingHotelBargain)
    }

    func testOldSavesWithoutHotelOwnersStillLoad() throws {
        let g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 4)
        var json = String(data: try JSONEncoder().encode(g.state), encoding: .utf8)!
        json = json.replacingOccurrences(of: "\"hotelOwners\":null,", with: "")
        XCTAssertNoThrow(try JSONDecoder().decode(GameState.self, from: Data(json.utf8)))
    }
}
