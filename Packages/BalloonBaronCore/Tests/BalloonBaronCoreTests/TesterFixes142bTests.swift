import XCTest
@testable import BalloonBaronCore

/// v142b TestFlight fixes: pilots placed at once when a bigger hangar lets balloons in, and pilot names that don't repeat.
final class TesterFixes142bTests: XCTestCase {
    /// Day 30, a full level-1 hangar (six balloons, the flagship flown by the founder) and a pilot for each other one.
    func fullHangar(seed: UInt64 = 5) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.day = 30
        g.state.lastSelfFly = 30
        g.state.selfFly = true
        g.state.cash = 2_000_000
        g.state.unlocked.formUnion([.fleet, .crew, .market])
        for i in 1..<6 { g.state.balloons.append(Balloon(id: 1000 + i, size: .M, name: "B\(i)")) }
        for i in 1..<6 { g.state.pilots.append(Pilot(id: 5000 + i, name: "P\(i) A.", level: .experienced)) }
        g.assignPilots()
        return g
    }

    /// The tester's case: a take-over brings balloons and their pilots into a full hangar, so the balloons stand
    /// outside and the pilots wait; after the hangar upgrade they fly the next flight without touching anything.
    func testHangarUpgradeGivesTheBalloonsThatMoveInTheirPilots() {
        var g = fullHangar()
        let i = g.state.rivals.indices.first { g.state.rivals[$0].alive }!
        g.state.rivals[i].balloons = [.M, .M, .S]
        g.state.rivals[i].offer = 10_000
        XCTAssertTrue(g.takeOver(i))
        XCTAssertEqual(g.state.outsideCount, 3)
        XCTAssertEqual(g.state.idlePilots.count, 3, "the rival's pilots came, but their balloons stand outside")
        let moved = g.state.outsideIDs
        XCTAssertTrue(g.upgrade(.hangar))
        XCTAssertEqual(g.state.outsideCount, 0)
        for b in g.state.balloons where moved.contains(b.id) {
            XCTAssertNotNil(b.pilot, "\(b.name) moved in and has a pilot at once")
        }
        XCTAssertTrue(g.state.idlePilots.isEmpty)
        XCTAssertEqual(g.state.flyingToday.count, 9, "all nine balloons fly the next flight")
    }

    func testEveryRegionHasFortyDifferentNames() {
        for r in RegionID.allCases {
            XCTAssertGreaterThanOrEqual(r.pilotNames.count, 40, "\(r)")
            XCTAssertEqual(Set(r.pilotNames).count, r.pilotNames.count, "\(r): no name twice")
            XCTAssertFalse(r.pilotNames.contains { $0.contains(" ") }, "\(r): one-word first names")
        }
    }

    func testCandidatesTakeFirstNamesTheCrewDoesNotHave() {
        for seed in UInt64(1)...30 {
            var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
            g.state.school = true
            let pool = g.state.region.pilotNames
            g.state.pilots = (0..<20).map { Pilot(id: 7000 + $0, name: "\(pool[$0]) K.", level: .rookie) }
            g.newCandidates()
            let crew = Set(g.state.pilots.map { GameState.firstName($0.name) })
            let firsts = g.state.candidates.map { GameState.firstName($0.name) }
            XCTAssertEqual(g.state.candidates.count, 4)
            XCTAssertEqual(Set(firsts).count, firsts.count, "seed \(seed): candidates differ from each other")
            XCTAssertTrue(crew.isDisjoint(with: firsts), "seed \(seed): \(firsts) vs the crew")
        }
    }

    func testOnceEveryFirstNameIsUsedTheFullNameStillDiffers() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 3)
        let pool = g.state.region.pilotNames
        g.state.pilots = pool.enumerated().map { Pilot(id: 7000 + $0.offset, name: "\($0.element) K.", level: .rookie) }
        for _ in 0..<10 {
            g.newCandidates()
            let names = g.state.pilots.map(\.name) + g.state.candidates.map(\.name)
            XCTAssertEqual(Set(names).count, names.count, "a repeated first name gets another initial: \(g.state.candidates.map(\.name))")
        }
    }

    func testTakeOverCrewAvoidsTheCrewsNames() {
        var g = fullHangar()
        let pool = g.state.region.pilotNames
        g.state.pilots = (0..<30).map { Pilot(id: 7000 + $0, name: "\(pool[$0]) K.", level: .rookie) }
        g.state.candidates = []
        let i = g.state.rivals.indices.first { g.state.rivals[$0].alive }!
        g.state.rivals[i].balloons = Array(repeating: .M, count: 8)
        let crew = g.state.dealCrew(i, bankrupt: false)
        XCTAssertEqual(crew, g.state.dealCrew(i, bankrupt: false), "the card and the deal show the same people")
        let firsts = crew.map { GameState.firstName($0.name) }
        XCTAssertEqual(Set(firsts).count, 8, "\(firsts)")
        XCTAssertTrue(Set(pool.prefix(30)).isDisjoint(with: firsts))
    }

    func testFirstName() {
        XCTAssertEqual(GameState.firstName("Derya K."), "Derya")
        XCTAssertEqual(GameState.firstName("Ali"), "Ali")
    }
}
