import XCTest
@testable import BalloonBaronCore

/// v144 (App Review 2.1(b)): the Grand Tour and the Supporter Edition are sold in the shop from day one. Buying early
/// only removes the paywall: each region still opens when you become baron of the one before it.
final class ShopEarly144Tests: XCTestCase {
    func newGame() -> Game { Game(company: "Test Air", colors: Rules.palettes[0], seed: 7) }

    func testGrandTourOnDayOneKeepsTheProgression() {
        var g = newGame()
        XCTAssertEqual(g.state.day, 1)
        g.grantStoreItem(.worldTour)
        XCTAssertTrue(g.state.owned(.worldTour))
        for r in RegionID.allCases where r != .cap { XCTAssertFalse(g.state.needsPack(r), "\(r): no paywall once owned") }
        XCTAssertFalse(g.state.regionOpen(.abq), "Albuquerque still waits for the Baron of Cappadocia")
        g.state.holding.cash = 10_000_000
        XCTAssertFalse(g.enterRegion(.abq))
        XCTAssertFalse(g.enterRegion(.lux))
        XCTAssertEqual(g.state.region, .cap)
        XCTAssertFalse(g.state.owns(.abq))
        XCTAssertFalse(StoreItem.bundle.contains { g.state.owned($0) }, "the Grand Tour holds no cosmetics")
        XCTAssertTrue(g.state.bundleWorth, "the Founder Pack is still offered")
        g.state.barons[.cap] = g.state.day
        XCTAssertTrue(g.enterRegion(.abq), "baron of Cappadocia: straight in, no offer")
        XCTAssertFalse(g.state.regionOpen(.lux), "Luxor waits for the Baron of Albuquerque")
        XCTAssertFalse(g.enterRegion(.lux))
    }

    func testSupporterOnDayOne() {
        var g = newGame()
        let designs = g.state.designs.count
        g.grantStoreItem(.supporter)
        XCTAssertTrue(g.state.owned(.supporter))
        XCTAssertTrue(g.state.owned(.worldTour))
        XCTAssertTrue(StoreItem.bundle.allSatisfy { g.state.owned($0) })
        XCTAssertFalse(g.state.bundleWorth)
        XCTAssertEqual(g.state.designs.count, designs + 7, "four patterns and three shapes as ready designs")
        XCTAssertNotNil(g.state.design(of: g.state.balloon(g.state.flagship)!)?.shape, "a shape on the flagship")
        XCTAssertFalse(g.state.regionOpen(.abq))
        // A restore later grants nothing twice.
        g.grantStoreItem(.supporter)
        g.grantStoreItem(.worldTour)
        XCTAssertEqual(g.state.designs.count, designs + 7)
        // The save keeps it.
        let data = try! JSONEncoder().encode(g.state)
        let s = try! JSONDecoder().decode(GameState.self, from: data)
        XCTAssertTrue(s.owned(.worldTour) && s.owned(.supporter))
    }

    /// Every product the shop lists, and the fifteen App Store product ids.
    func testFifteenProducts() {
        let ids = StoreItem.allCases.filter(\.isProduct).map(\.productID)
        XCTAssertEqual(ids.count, 15)
        XCTAssertEqual(Set(ids).count, 15)
        XCTAssertTrue(ids.contains("balloonbaron.worldtour"))
        XCTAssertTrue(ids.contains("balloonbaron.supporter"))
        XCTAssertTrue(ids.contains("balloonbaron.founder"))
    }
}
