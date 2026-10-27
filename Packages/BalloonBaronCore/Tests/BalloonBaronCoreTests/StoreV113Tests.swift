import XCTest
@testable import BalloonBaronCore

/// v113 store: Egypt gates Luxor, the Founder Pack grants every cosmetic, show figures, the new decorations.
final class StoreV113Tests: XCTestCase {
    func newGame() -> Game { Game(company: "Test Air", colors: Rules.palettes[0], seed: 5) }

    /// v115: Cappadocia is the free game; America and Egypt need the Grand Tour (or the Supporter Edition).
    func testGrandTourGatesTheWorld() {
        var g = newGame()
        g.state.barons[.cap] = 1
        g.state.holding.cash = 1_000_000
        XCTAssertTrue(g.state.needsPack(.abq))
        XCTAssertFalse(g.enterRegion(.abq), "Grand Tour first")
        g.grantStoreItem(.worldTour)
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.barons[.abq] = g.state.day
        XCTAssertTrue(g.enterRegion(.lux))
        var h = newGame()
        h.grantStoreItem(.supporter)
        XCTAssertTrue(h.state.owned(.worldTour))
        XCTAssertTrue(h.state.owned(.founder) || StoreItem.bundle.allSatisfy { h.state.owned($0) })
        XCTAssertTrue(h.state.owned(.pigeons), "the pack items come with it")
        XCTAssertEqual(StoreItem(rawValue: "egypt"), .worldTour, "v113 Egypt buyers have the Grand Tour")
    }

    func testFounderPackGrantsEverythingOnce() {
        var g = newGame()
        g.grantStoreItem(.gold)
        XCTAssertEqual(g.state.bundleLeft.count, StoreItem.bundle.count - 1)
        XCTAssertTrue(g.state.bundleWorth)
        XCTAssertEqual(g.state.bundleWas, 13.89, accuracy: 0.001)
        XCTAssertEqual(g.state.bundleOff, 50)
        let designs = g.state.designs.count
        g.grantStoreItem(.founder)
        XCTAssertTrue(StoreItem.bundle.allSatisfy { g.state.owned($0) })
        XCTAssertFalse(g.state.owned(.worldTour), "the Grand Tour isn't in the pack")
        XCTAssertFalse(g.state.bundleWorth)
        XCTAssertEqual(g.state.designs.count, designs + 6, "three patterns and three shapes not owned yet")
        XCTAssertTrue(g.state.owned(.figTulip), "figures come in their pack")
        XCTAssertEqual(g.state.design(of: g.state.balloon(g.state.flagship)!)?.shape, .heart, "first shape on the flagship")
        XCTAssertEqual(g.state.decorationCount, 7)
        if case .founderPack(11, _, .heart) = g.state.hezQueue.first {} else { XCTFail("one message: \(String(describing: g.state.hezQueue.first))") }
        XCTAssertEqual(StoreItem.bundle.count, 12)
        XCTAssertEqual(StoreItem.bundle.reduce(0) { $0 + $1.euro }, 14.88, accuracy: 0.001)
    }

    func testFiguresArePickedWhenBought() {
        var g = newGame()
        XCTAssertNil(g.state.showFigure)
        g.state.showFig = .figStar
        XCTAssertNil(g.state.showFigure, "not owned")
        g.grantStoreItem(.figurePack)
        XCTAssertEqual(g.state.showFigure, .figStar)
        XCTAssertFalse(StoreItem.figTulip.isProduct, "sold in the pack")
        XCTAssertEqual(StoreItem.figurePack.productID, "balloonbaron.figurepack")
        XCTAssertEqual(StoreItem.worldTour.euro, 4.99)
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
