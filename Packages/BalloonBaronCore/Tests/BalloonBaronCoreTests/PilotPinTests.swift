import XCTest
@testable import BalloonBaronCore

final class PilotPinTests: XCTestCase {
    /// After any pin, swap, hire, fire, repair, self-flight, flagship change, sale or day: no pilot on two balloons,
    /// no pilot or pin that left, every pin honoured where the balloon can fly, and no idle pilot while a balloon that
    /// could fly has none.
    func checkInvariants(_ g: Game, _ tag: String, file: StaticString = #filePath, line: UInt = #line) {
        let s = g.state, ids = Set(s.pilots.map(\.id))
        var seen = Set<Int>(), pins = Set<Int>()
        func down(_ b: Balloon) -> Bool { b.damagedUntil > s.day || s.condition(b) <= 0 }
        func isSelf(_ b: Balloon) -> Bool { b.id == s.flagship && s.flyingSelf }
        for b in s.balloons {
            if let p = b.pilot {
                XCTAssertFalse(seen.contains(p), "\(tag): pilot on two balloons", file: file, line: line)
                XCTAssertTrue(ids.contains(p), "\(tag): pilot who left", file: file, line: line)
                seen.insert(p)
            }
            if let p = b.pinnedPilot {
                XCTAssertFalse(pins.contains(p), "\(tag): pin twice", file: file, line: line)
                XCTAssertTrue(ids.contains(p), "\(tag): pin of a pilot who left", file: file, line: line)
                pins.insert(p)
                if !isSelf(b) && !down(b) { XCTAssertEqual(b.pilot, p, "\(tag): pin not honoured", file: file, line: line) }
            }
            if isSelf(b) { XCTAssertNil(b.pilot, "\(tag): founder's balloon has a pilot", file: file, line: line) }
        }
        let idle = s.pilots.filter { !seen.contains($0.id) }.count
        let empty = s.balloons.filter { !isSelf($0) && !down($0) && $0.pilot == nil }.count
        XCTAssertFalse(idle > 0 && empty > 0, "\(tag): \(idle) idle pilots while \(empty) balloons wait", file: file, line: line)
    }

    func game() -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 3)
        g.startDay()
        for i in 0..<6 {
            g.state.balloons.append(Balloon(id: 1000 + i, size: [.S, .M, .L][i % 3], name: "B\(i)"))
            g.state.pilots.append(Pilot(id: 2000 + i, name: "P\(i) A.", level: [.rookie, .experienced, .senior][i % 3]))
        }
        g.assignPilots()
        return g
    }

    func testPinAndSwap() {
        var g = game()
        let a = g.state.balloons[1].id, b = g.state.balloons[2].id
        let pa = g.state.balloons[1].pilot!, pb = g.state.balloons[2].pilot!
        g.pinPilot(balloon: a, pilot: pb)
        XCTAssertEqual(g.state.balloons.first { $0.id == a }?.pilot, pb)
        XCTAssertEqual(g.state.balloons.first { $0.id == b }?.pilot, pa, "the two swap")
        checkInvariants(g, "swap")
        g.pinPilot(balloon: a, pilot: nil)
        XCTAssertNil(g.state.balloons.first { $0.id == a }?.pinnedPilot)
        checkInvariants(g, "auto")
    }

    func testFiredPinnedPilotIsDroppedAndBalloonRefilled() {
        var g = game()
        let a = g.state.balloons[3].id, p = g.state.pilots[0].id
        g.pinPilot(balloon: a, pilot: p)
        g.state.pilots.removeAll { $0.id == p }
        g.assignPilots()
        XCTAssertNil(g.state.balloons.first { $0.id == a }?.pinnedPilot)
        checkInvariants(g, "fired")
    }

    func testPinnedBalloonInRepairLendsItsPilot() {
        var g = game()
        let a = g.state.balloons[4].id, p = g.state.pilots[2].id
        g.pinPilot(balloon: a, pilot: p)
        g.state.pilots.removeLast()
        if let i = g.state.balloons.firstIndex(where: { $0.id == a }) { g.state.balloons[i].damagedUntil = g.state.day + 2 }
        g.assignPilots()
        XCTAssertEqual(g.state.balloons.first { $0.id == a }?.pinnedPilot, p, "the pin stays")
        XCTAssertTrue(g.state.balloons.contains { $0.id != a && $0.pilot == p }, "the pilot flies another balloon meanwhile")
        checkInvariants(g, "repair")
    }

    func testRandomStress() {
        for seed in UInt64(1)...6 {
            var g = game(), rng = SplitMix64(seed: seed &* 7919)
            var nextID = 5000
            for step in 0..<1500 {
                let k = rng.int(100)
                if k < 30, !g.state.pilots.isEmpty {
                    let b = rng.pick(g.state.balloons).id, p = rng.pick(g.state.pilots).id
                    g.pinPilot(balloon: b, pilot: p)
                    let bb = g.state.balloons.first { $0.id == b }!
                    if !(bb.id == g.state.flagship && g.state.flyingSelf) && bb.damagedUntil <= g.state.day && g.state.condition(bb) > 0 {
                        XCTAssertEqual(bb.pilot, p, "seed \(seed) step \(step): pick not applied")
                    }
                } else if k < 36 {
                    g.pinPilot(balloon: rng.pick(g.state.balloons).id, pilot: nil)
                } else if k < 44 + Int(seed % 3) * 4 {
                    nextID += 1
                    g.state.pilots.append(Pilot(id: nextID, name: "H\(nextID) B.", level: .experienced)); g.assignPilots()
                } else if k < 52, g.state.pilots.count > 1 {
                    let p = rng.pick(g.state.pilots).id
                    g.state.pilots.removeAll { $0.id == p }; g.assignPilots()
                } else if k < 60 {
                    let i = rng.int(g.state.balloons.count)
                    g.state.balloons[i].damagedUntil = g.state.day + rng.int(3); g.assignPilots()
                } else if k < 65 {
                    g.state.local.selfFly.toggle(); g.assignPilots()
                } else if k < 70 {
                    g.state.flagship = rng.pick(g.state.balloons).id; g.assignPilots()
                } else if k < 74, g.state.balloons.count > 3 {
                    let b = rng.pick(g.state.balloons).id
                    g.state.balloons.removeAll { $0.id == b }
                    if g.state.flagship == b { g.state.flagship = g.state.balloons[0].id }
                    g.assignPilots()
                } else if k < 80 {
                    nextID += 1
                    g.state.balloons.append(Balloon(id: nextID, size: .M, name: "N\(nextID)")); g.assignPilots()
                } else {
                    g.state.day += 1; g.assignPilots()
                }
                checkInvariants(g, "seed \(seed) step \(step)")
            }
        }
    }

    func testCappadociaInitials() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 9)
        for _ in 0..<200 {
            g.newCandidates()
            for p in g.state.candidates { XCTAssertFalse(["Q.", "W.", "X."].contains(String(p.name.suffix(2))), p.name) }
        }
        var s = g.state
        s.local.pilots = [Pilot(id: 1, name: "Mert X.", level: .rookie), Pilot(id: 2, name: "Elif W.", level: .rookie)]
        s.migrate()
        XCTAssertEqual(s.local.pilots.map(\.name), ["Mert S.", "Elif V."])
    }

    /// Real days: buying, hiring, firing, selling, flying yourself or not, landings and accidents, with the player
    /// re-pinning pilots every morning. Checked right after each morning's placing and after each pick.
    func testRealDaysWithPins() {
        for seed in UInt64(1)...4 {
            var g = Game(company: "Sim", colors: Rules.palettes[0], seed: seed)
            var rng = SplitMix64(seed: seed &* 131)
            for day in 0..<160 {
                if g.state.over { break }
                g.startDay()
                while g.nextHezarfen() != nil {}
                checkInvariants(g, "seed \(seed) day \(day) morning")
                g.state.cash = max(g.state.cash, 200_000)
                if g.state.balloons.count < 12 && rng.chance(0.3) { _ = g.buyBalloon([.S, .M, .L][rng.int(3)]) }
                if rng.chance(0.5), let c = g.state.candidates.first { _ = g.hire(c.id) }
                if rng.chance(0.08), g.state.pilots.count > 1 { g.fire(rng.pick(g.state.pilots).id) }
                if rng.chance(0.05), g.state.balloons.count > 2 { _ = g.sellBalloon(rng.pick(g.state.balloons).id) }
                g.setSelfFly(rng.chance(0.5) || !g.state.licenseValid)
                for _ in 0..<rng.int(4) where !g.state.pilots.isEmpty {
                    g.pinPilot(balloon: rng.pick(g.state.balloons).id, pilot: rng.chance(0.15) ? nil : rng.pick(g.state.pilots).id)
                    checkInvariants(g, "seed \(seed) day \(day) pick")
                }
                let landing: FlightResult.Landing = rng.chance(0.1) ? .hard : .good
                if g.launch(skip: false) != nil {
                    _ = g.finishDay(flight: FlightResult(landing: landing, distance: 60, mission: nil, missionDone: false))
                } else { _ = g.finishDay(flight: nil) }
                if let offer = g.state.poach { g.answerPoach(match: offer.wage <= 200) }
            }
            XCTAssertTrue(g.state.balloons.contains { $0.pinnedPilot != nil }, "seed \(seed): pins survive the days")
        }
    }
}
