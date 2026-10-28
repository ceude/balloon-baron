import XCTest
@testable import BalloonBaronCore

/// v122: the tutorial that shows (Faz 1), the stronger thermal, and the guide office's and agency's three choices.
final class TutorialTests: XCTestCase {
    func newGame() -> Game {
        var g = Game(company: "Test", colors: ["#ff5e3a", "#ffffff"], seed: 7)
        g.startDay()
        return g
    }

    func testNewGameRunsTheTutorialAndRecordsEachStepOnce() {
        var g = newGame()
        XCTAssertTrue(g.state.tutorialOn)
        XCTAssertTrue(g.tutorialStep("price"))
        XCTAssertFalse(g.tutorialStep("price"), "a step is recorded once")
        XCTAssertEqual(g.state.tutorial?.steps["price"], 1, "with the day it was done")
        for k in TutorialState.all where k != "thermal" { g.tutorialStep(k) }
        XCTAssertTrue(g.state.tutorialOn, "not over until every step is done")
        g.tutorialStep("thermal")
        XCTAssertFalse(g.state.tutorialOn)
    }

    func testSkipEndsTheWholeTutorial() {
        var g = newGame()
        XCTAssertTrue(g.skipTutorial())
        XCTAssertFalse(g.state.tutorialOn)
        XCTAssertTrue(g.state.tutorialHas("skip"))
        XCTAssertFalse(g.skipTutorial(), "only once")
    }

    /// Saves from before v122 decode (no `tutorial` key); the ones that flew or are past day one skip it.
    func testOldSavesSkipTheTutorial() throws {
        func old(_ edit: (inout GameState) -> Void) throws -> GameState {
            var s = newGame().state
            edit(&s)
            var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! [String: Any]
            json["tutorial"] = nil
            var local = json["local"] as! [String: Any]
            local["guidePax"] = nil
            local["influPax"] = nil
            json["local"] = local
            let back = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
            XCTAssertNil(back.tutorial)
            return Game(state: back).state
        }
        XCTAssertFalse(try old { $0.day = 4 }.tutorialOn, "past day one")
        XCTAssertFalse(try old { $0.selfFlights = 1 }.tutorialOn, "already flew")
        XCTAssertTrue(try old { _ in }.tutorialOn, "a day-one save that hasn't flown yet gets it")
        let s = try old { $0.day = 4 }
        XCTAssertEqual(Game(state: s).state, s, "a current save is left alone")
    }

    func testThermalLiftsTwiceAsHard() {
        XCTAssertEqual(Rules.thermalLift, 1.0)
        var w = Weather(flag: .green, surfaceWind: 5, layers: [0, 0, 0, 0], target: 900, seed: 3, mission: nil, valley: 0)
        w.seed = 3
        var f = FlightSim(weather: w, pax: 4)
        f.moment = FlightMoment(kind: .thermal, x: f.x)
        f.alt = 200; f.airborne = true; f.heat = 0.5; f.vy = 0
        _ = f.step(0.05)
        XCTAssertTrue(f.inThermal)
        // 0.3 s of sim time: the lift adds 0.3 × 1.0, the cooling takes a little.
        XCTAssertGreaterThan(f.vy, 0.2)
        f.moment = nil
        _ = f.step(0.05)
        XCTAssertFalse(f.inThermal)
    }

    func testTutorialThermalLiesAheadTowardTheField() {
        let w = Weather(flag: .green, surfaceWind: 5, layers: [0, 0, 0, 0], target: -800, seed: 3, mission: nil, valley: 0)
        for k in [0.0, 0.5, 1.0] {
            let m = FlightMoment.tutorialThermal(w, k: k)
            XCTAssertEqual(m.kind, .thermal)
            XCTAssertTrue((FlightWorld.launchX - 700)...(FlightWorld.launchX - 380) ~= m.x)
        }
    }

    func testGuidesBringWhatTheyPromise() {
        var g = newGame()
        g.state.cash = 10000
        let before = g.state.rep
        XCTAssertTrue(g.runGuideFlight(.selin))
        XCTAssertEqual(g.state.cash, 10000 - 2400)
        XCTAssertEqual(g.state.rep, before + 0.07, accuracy: 1e-9)
        XCTAssertEqual(g.state.guideUntil, g.state.day + 4)
        XCTAssertEqual(g.state.guideCooldown, g.state.day + 6)
        XCTAssertEqual(g.state.local.guidePax, 7)
        XCTAssertFalse(g.runGuideFlight(.ayse), "then the wait")
        // The tourists they send count in today's market.
        let t = g.touristsToday()
        g.state.local.guidePax = nil
        XCTAssertEqual(t - g.touristsToday(), 2, "seven instead of the old five")
    }

    func testMehmetIsTheOldDealAndTheRescuePlansGuide() {
        XCTAssertEqual(GuideOffer.mehmet.cost, Rules.guideCost)
        XCTAssertEqual(GuideOffer.mehmet.days, 3)
        XCTAssertEqual(GuideOffer.mehmet.pax, 5)
        XCTAssertEqual(GuideOffer.mehmet.cooldown, 5)
        XCTAssertEqual(GuideOffer.ayse.cost, 900)
        var g = newGame()
        g.state.cash = 1000
        g.state.unlocked.insert(.guide)
        XCTAssertTrue(g.runGuideFlight(inRescue: true))
        XCTAssertEqual(g.state.cash, 1000 - 1500)
        XCTAssertEqual(g.state.local.guidePax, 5)
    }

    func testInfluencersPriceAndPull() {
        var g = newGame()
        g.state.cash = 50000
        let base = g.state.influencerCost
        XCTAssertEqual(InfluencerOffer.travel.cost(g.state), base, "the middle one is the old campaign")
        XCTAssertEqual(InfluencerOffer.local.cost(g.state) % 100, 0)
        XCTAssertEqual(InfluencerOffer.star.cost(g.state), Int((Double(base) * 1.8 / 100).rounded()) * 100)
        let rep = g.state.rep
        XCTAssertTrue(g.runInfluencer(.star))
        XCTAssertEqual(g.state.cash, 50000 - InfluencerOffer.star.cost(g.state))
        XCTAssertEqual(g.state.rep, min(1.4, rep + 0.16), accuracy: 1e-9)
        XCTAssertEqual(g.state.influencerUntil, g.state.day + 4)
        XCTAssertEqual(g.state.influencerCooldown, g.state.day + 12)
        XCTAssertEqual(g.state.local.influPax, 12)
        XCTAssertTrue(g.referralSources().contains { $0.source == .influencer && $0.count > 0 })
        XCTAssertFalse(g.runInfluencer(.local), "then the wait")
    }

    /// Unlock days stay: the guide office on day 7, the agency on day 8.
    func testUnlockDaysUnchanged() {
        XCTAssertEqual(Rules.unlockDay[.guide], 7)
        XCTAssertEqual(Rules.unlockDay[.agency], 8)
    }
}
