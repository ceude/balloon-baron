import XCTest
@testable import BalloonBaronCore

/// v113 store: Egypt gates Luxor, the Founder Pack grants every cosmetic, show figures, the new decorations.
final class StoreV113Tests: XCTestCase {
    func newGame() -> Game { Game(company: "Test Air", colors: Rules.palettes[0], seed: 5) }

    func testEgyptGatesLuxorOnly() {
        var g = newGame()
        g.state.barons[.cap] = 1
        g.state.holding.cash = 1_000_000
        XCTAssertFalse(g.state.needsPack(.abq), "America is free")
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.barons[.abq] = g.state.day
        XCTAssertTrue(g.state.needsPack(.lux))
        XCTAssertFalse(g.enterRegion(.lux), "Egypt first")
        g.grantStoreItem(.egypt)
        XCTAssertFalse(g.state.needsPack(.lux))
        XCTAssertTrue(g.enterRegion(.lux))
    }

    func testFounderPackGrantsEverythingOnce() {
        var g = newGame()
        g.grantStoreItem(.gold)
        XCTAssertEqual(g.state.bundleLeft.count, StoreItem.bundle.count - 1)
        XCTAssertTrue(g.state.bundleWorth)
        XCTAssertEqual(g.state.bundleWas, 16.32, accuracy: 0.001)
        XCTAssertEqual(g.state.bundleOff, 57)
        let designs = g.state.designs.count
        g.grantStoreItem(.founder)
        XCTAssertTrue(StoreItem.bundle.allSatisfy { g.state.owned($0) })
        XCTAssertFalse(g.state.owned(.egypt), "Egypt isn't in the pack")
        XCTAssertFalse(g.state.bundleWorth)
        XCTAssertEqual(g.state.designs.count, designs + 6, "three patterns and three shapes not owned yet")
        XCTAssertEqual(g.state.design(of: g.state.balloon(g.state.flagship)!)?.shape, .heart, "first shape on the flagship")
        XCTAssertEqual(g.state.decorationCount, 7)
        if case .founderPack(18, _, .heart) = g.state.hezQueue.first {} else { XCTFail("one message: \(String(describing: g.state.hezQueue.first))") }
        XCTAssertEqual(StoreItem.bundle.count, 19)
        XCTAssertEqual(StoreItem.bundle.reduce(0) { $0 + $1.euro }, 17.31, accuracy: 0.001)
    }

    func testFiguresArePickedWhenBought() {
        var g = newGame()
        XCTAssertNil(g.state.showFigure)
        g.state.showFig = .figStar
        XCTAssertNil(g.state.showFigure, "not owned")
        g.grantStoreItem(.figTulip)
        XCTAssertEqual(g.state.showFigure, .figTulip)
        XCTAssertEqual(StoreItem.figTulip.productID, "balloonbaron.fig.tulip")
        XCTAssertEqual(StoreItem.egypt.euro, 2.99)
    }

    func testOldSavesStillDecode() throws {
        var g = newGame()
        g.grantStoreItem(.fountain)
        var json = String(decoding: try JSONEncoder().encode(g.state), as: UTF8.self)
        json = json.replacingOccurrences(of: ",\"showFig\":null", with: "")
        let s = try JSONDecoder().decode(GameState.self, from: Data(json.utf8))
        XCTAssertNil(s.showFig)
        XCTAssertTrue(s.owned(.fountain))
    }
}
