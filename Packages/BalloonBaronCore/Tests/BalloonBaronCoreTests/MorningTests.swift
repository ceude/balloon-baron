import XCTest
@testable import BalloonBaronCore

/// v121.12: the newcomer fixes from the playtest.
final class MorningTests: XCTestCase {
    func newGame() -> Game { Game(company: "Test Air", colors: Rules.palettes[0], seed: 11) }

    func testAMorningShowsAtMostTwoLessonsAndOnePostcard() {
        var g = newGame()
        g.state.day = 3
        g.state.hezQueue = [.tip(.fleet), .spring, .tip(.goals), .tip(.mission), .tip(.price)]
        g.state.newPostcards = [.first, .mission]
        g.spreadMorning()
        XCTAssertEqual(g.state.hezQueue, [.tip(.fleet), .spring, .tip(.goals)])
        XCTAssertEqual(g.state.hezLater ?? [], [.tip(.mission), .tip(.price)])
        XCTAssertEqual(g.state.newPostcards ?? [], [.first])
        g.spreadMorning()
        XCTAssertEqual(g.state.hezLater ?? [], [.tip(.mission), .tip(.price)], "once a morning")
        g.state.hezQueue = []
        g.state.day = 4
        g.spreadMorning()
        XCTAssertEqual(g.state.hezQueue, [.tip(.mission), .tip(.price)], "the rest come the next morning, in order")
        XCTAssertEqual(g.state.newPostcards ?? [], [.mission])
    }

    func testOnlyBalloonIsRepairedInTwoDays() {
        var g = newGame()
        g.state.selfFlights = Rules.coachFlights
        g.state.day = 5
        g.startDay()
        g.state.weather?.flag = .green
        guard g.launch(skip: false) != nil else { return XCTFail("the flagship should fly") }
        let r = g.finishDay(flight: FlightResult(landing: .crash, distance: 400))
        XCTAssertLessThanOrEqual(g.state.balloons[0].damagedUntil - 5, Rules.onlyBalloonRepairDays)
        XCTAssertTrue(r.events.contains(.onlyBalloonRepair(days: Rules.onlyBalloonRepairDays)))
        XCTAssertNotEqual(g.state.firstCleanFlight, true, "a crash isn't the first-flight postcard")
    }

    func testStarsAreRoundedLikeTheScreen() {
        let rep = 0.75 + (2.96 - 3) / 4
        XCTAssertEqual(Rules.stars(rep), 3.0)
    }

    func testStalePraiseIsDropped() {
        var g = newGame()
        g.state.pilots = []
        g.state.hezQueue = [.praise(.pilot), .spring]
        XCTAssertEqual(g.nextHezarfen(), .spring)
    }

    func testForcedSkipWhenTheOnlyBalloonIsInRepair() {
        var g = newGame()
        XCTAssertFalse(g.state.forcedSkip)
        g.state.balloons[0].damagedUntil = g.state.day + 2
        XCTAssertTrue(g.state.forcedSkip)
    }

    func testSeasonsFromAnotherRegionEndWhenYouComeBack() {
        var g = newGame()
        g.state.day = 589
        g.state.fiesta = Fiesta(start: 546, end: 549)
        g.state.winter = Winter(start: 546, end: 553)
        g.startDay()
        XCTAssertNil(g.state.fiesta)
        XCTAssertNil(g.state.winter)
        XCTAssertEqual(g.state.nextWinter, 589 + 45)
    }

    func testATakeOverBringsThePilotsOnTheirContracts() {
        var g = newGame()
        g.state.cash = 1_000_000
        g.state.rivals[0].offer = 1000
        let crew = g.state.dealCrew(0, bankrupt: false)
        XCTAssertEqual(crew.count, g.state.rivals[0].balloons.count)
        XCTAssertEqual(crew, g.state.dealCrew(0, bankrupt: false), "the card and the deal show the same people")
        let before = g.state.pilots.count
        XCTAssertTrue(g.takeOver(0))
        XCTAssertEqual(g.state.pilots.count, before + crew.count)
        XCTAssertEqual(Set(g.state.pilots.map(\.id)).count, g.state.pilots.count, "unique ids")
        for p in g.state.pilots.suffix(crew.count) {
            XCTAssertEqual(Double(p.wage), Double(p.level.wage), accuracy: Double(p.level.wage) * 0.1 + 1)
        }
    }

    func testABankruptFleetBringsItsPilots() {
        var g = newGame()
        g.state.cash = 1_000_000
        g.state.rivals[1].forSale = ForSale(sizes: [.S, .S, .M], price: 1000)
        let before = g.state.pilots.count
        XCTAssertTrue(g.buyBankruptFleet(1))
        XCTAssertEqual(g.state.pilots.count, before + 3)
    }
}
