import XCTest
@testable import BalloonBaronCore

final class SaveCodeTests: XCTestCase {
    func testTrimmedStateKeepsTheGameAndDecodes() throws {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 7)
        g.startDay()
        for i in 0..<30 { g.state.local.reviews.append(Review(reviewer: 0, kind: .general, variant: 0, stars: 5, day: i, args: [:])) }
        g.state.local.repHistory = (0..<120).map { RepPoint(day: $0, rep: 3) }
        g.state.paperNext = []
        let s = g.state.forCode()
        XCTAssertEqual(s.reviews.count, 8)
        XCTAssertEqual(s.reviews.first, g.state.reviews.first)
        XCTAssertEqual(s.repHistory.count, 60)
        XCTAssertEqual(s.repHistory.last?.day, 119)
        XCTAssertNil(s.paperNext)
        XCTAssertEqual(s.day, g.state.day)
        XCTAssertEqual(s.cash, g.state.cash)
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(back.balloons.count, g.state.balloons.count)
        var g2 = Game(state: back)
        g2.startDay()
        XCTAssertNotNil(g2.state.weather)
    }
}
