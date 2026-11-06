import XCTest
@testable import BalloonBaronCore

/// v141.8 (developer): TV and billboards bought for several regions at once got the same guide line (and newspaper story)
/// once per region. Now one word and one story per kind of purchase.
final class DeedOnce1418Tests: XCTestCase {
    func rich() -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 42)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.local.netHistory = [20000, 22000, 24000]
        g.state.holding.cash = 200_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.holding.cash = 100_000_000
        g.state.hezQueue = []
        g.state.paperNext = nil
        return g
    }

    func testSeveralRegionsOneWord() {
        var g = rich()
        g.state.parked[.cap]!.state.rep = 1
        XCTAssertTrue(g.runTVCampaign(in: .abq))
        XCTAssertTrue(g.runTVCampaign(in: .cap))
        XCTAssertTrue(g.runBillboards(in: .abq))
        XCTAssertTrue(g.runBillboards(in: .cap))
        XCTAssertEqual(g.state.hezQueue.filter { $0 == HezMessage.deed(.tv) }.count, 1)
        XCTAssertEqual(g.state.hezQueue.filter { $0 == HezMessage.deed(.billboards) }.count, 1)
        XCTAssertEqual((g.state.paperNext ?? []).filter { $0 == PaperItem.deed(.tv) }.count, 1)
        XCTAssertEqual((g.state.paperNext ?? []).filter { $0 == PaperItem.deed(.billboards) }.count, 1)
    }
}
