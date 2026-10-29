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

    /// v122.11: day 3's price reminder leads the morning, ahead of the lesson cap, and takes the `price` lesson's place.
    func testDayThreePriceReminderComesFirst() {
        var g = newGame()
        g.state.day = 3
        g.state.tutorial = TutorialState()
        g.state.hezQueue = [.tip(.fleet), .spring, .tip(.goals), .tip(.price), .tip(.price3)]
        g.spreadMorning()
        XCTAssertEqual(g.state.hezQueue, [.tip(.price3), .tip(.fleet), .spring])
        XCTAssertEqual(g.state.hezLater ?? [], [.tip(.goals)])
    }

    func testDayThreePriceReminderOnlyForTutorialSavesInCappadocia() {
        var g = newGame()
        g.state.tutorial = TutorialState()
        g.state.day = 3
        g.unlockCheck()
        XCTAssertTrue(g.state.hezQueue.contains(.tip(.price3)))
        var old = newGame()
        old.state.tutorial = TutorialState(done: true, old: true)
        old.state.day = 3
        old.unlockCheck()
        XCTAssertFalse(old.state.hezQueue.contains(.tip(.price3)), "an old save never saw day 2's crowd")
        var four = newGame()
        four.state.tutorial = TutorialState()
        four.state.day = 4
        four.unlockCheck()
        XCTAssertFalse(four.state.hezQueue.contains(.tip(.price3)))
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

/// v123: the family's letter comes once, from day 50; v123.1 and v123 add only optional fields to the save.
final class LetterTests: XCTestCase {
    func testLetterComesOnceFromDayFifty() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 3)
        g.state.day = 49
        XCTAssertFalse(g.state.letterDue)
        g.state.day = 50
        XCTAssertTrue(g.state.letterDue)
        g.markLetterShown()
        XCTAssertEqual(g.state.letterDay, 50)
        XCTAssertFalse(g.state.letterDue)
        g.state.day = 80
        XCTAssertFalse(g.state.letterDue, "only once")
        g.markLetterRated()
        XCTAssertEqual(g.state.letterRated, true)
    }

    func testOldSaveWithoutLetterFieldsLoads() throws {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 3)
        g.state.day = 70
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state)) as! [String: Any]
        for k in ["letterDay", "letterRated", "rateAsked"] { json.removeValue(forKey: k) }
        if var t = json["tutorial"] as? [String: Any] { t.removeValue(forKey: "old"); json["tutorial"] = t }
        let s = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(s.letterDay)
        XCTAssertNil(s.rateAsked)
        XCTAssertTrue(s.letterDue, "a save already past day 50 gets the letter on its next morning")
    }
}
