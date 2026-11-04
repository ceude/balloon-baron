import XCTest
@testable import BalloonBaronCore

/// QA v141: the same crew brought along from Cappadocia through every region to the Maasai Mara (the v125 transfer:
/// 16 seats and two pilots a time, pilots at once, balloons by cargo ten days later). Names, levels, experience, traits,
/// designs and equipment travel; pins and sponsor deals stay behind; wages follow the region (Bristol ×1.15, the Mara
/// ×1.1); nothing is duplicated or lost, going back to an earlier region finds it without them.
final class FleetTransfer141Tests: XCTestCase {
    /// Every balloon and pilot id in the game: the region you're in, the parked ones and the cargo on its way.
    func allIDs(_ g: Game) -> (balloons: [Int], pilots: [Int]) {
        var bs = g.state.local.balloons.map(\.id) + (g.state.local.transferShip?.balloons.map(\.id) ?? [])
        var ps = g.state.local.pilots.map(\.id)
        for (_, p) in g.state.parked {
            bs += p.state.balloons.map(\.id) + (p.state.transferShip?.balloons.map(\.id) ?? [])
            ps += p.state.pilots.map(\.id)
        }
        return (bs, ps)
    }

    func days(_ g: inout Game, _ n: Int) {
        for _ in 0..<n {
            g.state.hezQueue = []
            _ = g.launch(skip: true)
            _ = g.finishDay(flight: nil)
        }
    }

    /// Enters `r` (its unlocking baron granted) and brings the two crew pilots and the two small balloons.
    @discardableResult
    func enter(_ g: inout Game, _ r: RegionID, balloons: [Int], pilots: [Int]) -> (pilots: [String], balloons: [String]) {
        g.state.barons[r.unlockedBy!] = g.state.day
        XCTAssertTrue(g.canOpenOffice(.ist))
        XCTAssertTrue(g.enterRegion(r), "enter \(r)")
        XCTAssertEqual(g.state.transferAsk, r, "the bring-along card once on entering \(r)")
        return g.applyTransfer(balloons: balloons, pilots: pilots)
    }

    func testSameCrewFromCappadociaToTheMara() throws {
        var g = Game(company: "Crew Air", colors: Rules.palettes[0], seed: 7)
        g.startDay()
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 20_000_000
        // Cappadocia: five balloons, two of them small with designs and a second burner, and three pilots with traits
        g.state.local.balloons = [
            Balloon(id: 500, size: .M, name: "Yıldız", design: 3),
            Balloon(id: 501, size: .S, name: "Peri", ad: nil, design: 5, burner: 2),
            Balloon(id: 502, size: .S, name: "Tüf", design: 9, turningVent: true),
            Balloon(id: 503, size: .L, name: "Büyük"),
            Balloon(id: 504, size: .XL, name: "Dev")
        ]
        g.state.local.balloons[1].ad = nil
        g.state.local.flagship = 503
        g.state.local.pilots = [
            Pilot(id: 600, name: "Ayşe K.", level: .senior, xp: 140, trait: .careful),
            Pilot(id: 601, name: "Mehmet T.", level: .experienced, xp: 55, trait: .nightOwl),
            Pilot(id: 602, name: "Can D.", level: .rookie, xp: 4, trait: .showman)
        ]
        g.state.local.selfFly = false
        g.state.local.netHistory = Array(repeating: 6000, count: 14)
        g.pinPilot(balloon: 500, pilot: 600)
        g.pinPilot(balloon: 501, pilot: 601)
        XCTAssertEqual(g.state.local.balloons.first { $0.id == 500 }?.pinnedPilot, 600)
        let crew = [600, 601], cargo = [501, 502]
        let before = allIDs(g)
        XCTAssertFalse(g.canOpenOffice(.nyc))

        // Albuquerque: the crew and both small balloons come along
        let got = enter(&g, .abq, balloons: cargo, pilots: crew)
        XCTAssertEqual(Set(got.pilots), ["Ayşe K.", "Mehmet T."])
        XCTAssertEqual(Set(got.balloons), ["Peri", "Tüf"])
        XCTAssertTrue(g.canOpenOffice(.nyc), "New York opens with Albuquerque")
        let cap = g.state.parked[.cap]!.state
        XCTAssertEqual(Set(cap.pilots.map(\.id)), [602], "only Can stays home")
        XCTAssertEqual(Set(cap.balloons.map(\.id)), [500, 503, 504])
        XCTAssertNil(cap.balloons.first { $0.id == 500 }?.pinnedPilot, "a pin on a pilot who left is cleared at home")
        XCTAssertEqual(g.state.local.transferShip?.day, g.state.day + Transfer.shipDays)
        XCTAssertFalse(g.state.local.balloons.contains { cargo.contains($0.id) }, "balloons are on the cargo")
        for id in crew {
            let p = try XCTUnwrap(g.state.local.pilots.first { $0.id == id }, "pilots arrive at once")
            XCTAssertEqual(p.imported, .cap)
        }
        let ayse = g.state.local.pilots.first { $0.id == 600 }!
        XCTAssertEqual(ayse.level, .senior); XCTAssertEqual(ayse.xp, 140); XCTAssertEqual(ayse.trait, .careful)
        XCTAssertEqual(ayse.wage, 240, "same money, same wage")
        let mehmet = g.state.local.pilots.first { $0.id == 601 }!
        XCTAssertEqual(mehmet.trait, .nightOwl); XCTAssertEqual(mehmet.wage, Pilot.baseWage(.experienced, school: false, trait: .nightOwl))
        XCTAssertEqual(Set(allIDs(g).balloons), Set(before.balloons + g.state.local.balloons.map(\.id)), "nothing lost")

        // the cargo lands ten days later with names, designs and equipment
        days(&g, Transfer.shipDays)
        XCTAssertNil(g.state.local.transferShip)
        let peri = try XCTUnwrap(g.state.local.balloons.first { $0.id == 501 })
        XCTAssertEqual(peri.name, "Peri"); XCTAssertEqual(peri.design, 5); XCTAssertEqual(peri.burners, 2); XCTAssertNil(peri.pinnedPilot)
        let tuf = try XCTUnwrap(g.state.local.balloons.first { $0.id == 502 })
        XCTAssertEqual(tuf.design, 9); XCTAssertTrue(tuf.hasTurningVent); XCTAssertEqual(tuf.imported, .cap)
        g.pinPilot(balloon: 501, pilot: 600)
        XCTAssertEqual(g.state.local.balloons.first { $0.id == 501 }?.pinnedPilot, 600, "a pin can be set again in the new region")

        // Luxor, Bristol and the Maasai Mara: the same crew each time
        for (r, wage) in [(RegionID.lux, 240), (.bri, jsRound(240 * 1.15 / 5) * 5), (.mara, 265)] {
            let from = g.state.region
            let names = enter(&g, r, balloons: cargo, pilots: crew)
            XCTAssertEqual(names.pilots.count, 2, "\(r): both pilots")
            XCTAssertEqual(names.balloons.count, 2, "\(r): both balloons (16 seats)")
            XCTAssertTrue(g.state.parked[from]!.state.balloons.allSatisfy { $0.pinnedPilot != 600 }, "the pin stays behind")
            let a = g.state.local.pilots.first { $0.id == 600 }!
            XCTAssertEqual(a.wage, wage, "\(r): Ayşe's wage")
            XCTAssertEqual(a.level, .senior); XCTAssertEqual(a.trait, .careful); XCTAssertEqual(a.name, "Ayşe K.")
            XCTAssertEqual(a.imported, from)
            days(&g, Transfer.shipDays)
            XCTAssertEqual(Set(g.state.local.balloons.filter { $0.imported == from }.map(\.id)), Set(cargo), "\(r): cargo arrived")
            let ids = allIDs(g)
            XCTAssertEqual(ids.balloons.count, Set(ids.balloons).count, "\(r): no balloon twice")
            XCTAssertEqual(ids.pilots.count, Set(ids.pilots).count, "\(r): no pilot twice")
            XCTAssertTrue(before.balloons.allSatisfy(ids.balloons.contains), "\(r): no balloon lost")
            XCTAssertTrue(before.pilots.allSatisfy(ids.pilots.contains), "\(r): no pilot lost")
        }
        // Mara wages: from Bristol's ×1.15 to the Mara's ×1.1 (Bristol 275 → 265, the night owl 145 → 140)
        XCTAssertEqual(g.state.local.pilots.first { $0.id == 601 }?.wage, 140)
        XCTAssertEqual(g.state.local.balloons.first { $0.id == 501 }?.design, 5, "designs travel all the way")
        XCTAssertTrue(g.canOpenOffice(.dxb), "Dubai with the Mara")
        let debt = try XCTUnwrap(g.state.local.transferDebt)
        XCTAssertEqual(debt.from, .bri)
        XCTAssertEqual(debt.installment, jsRound(Double(BalloonSize.S.cost * 2) * RegionID.mara.fx / 30))

        // back to Cappadocia: the crew isn't there, Can is; then back to the Mara where they are
        g.setSendsToHolding(.lux, false)
        g.switchRegion(.cap)
        XCTAssertFalse(g.state.local.pilots.contains { crew.contains($0.id) })
        XCTAssertEqual(g.state.local.pilots.map(\.id), [602])
        XCTAssertFalse(g.state.local.balloons.contains { cargo.contains($0.id) })
        g.switchRegion(.mara)
        XCTAssertEqual(Set(g.state.local.pilots.filter { crew.contains($0.id) }.map(\.id)), Set(crew))
        XCTAssertFalse(g.state.holding.sends(.lux), "the send switch stays per region")
        XCTAssertTrue(g.state.holding.sends(.mara))
        // and through a save
        let data = try JSONEncoder().encode(g.state)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back, g.state)
    }

    /// The cargo lands in a full hangar: the brought balloons wait outside (never blocked, never lost).
    func testCargoIntoAFullHangarWaitsOutside() {
        var g = Game(company: "Crew Air", colors: Rules.palettes[0], seed: 9)
        g.startDay()
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 5_000_000
        g.state.local.balloons = [Balloon(id: 700, size: .S, name: "A"), Balloon(id: 701, size: .S, name: "B"), Balloon(id: 702, size: .L, name: "C")]
        g.state.local.flagship = 702
        g.state.local.pilots = [Pilot(id: 800, name: "Ayşe K.", level: .senior)]
        g.state.barons[.cap] = g.state.day
        XCTAssertTrue(g.enterRegion(.abq))
        g.applyTransfer(balloons: [700, 701], pilots: [800])
        for i in 0..<5 { g.state.local.balloons.append(Balloon(id: 900 + i, size: .M, name: "N\(i)")) }
        XCTAssertEqual(g.state.local.balloons.count, 6)
        XCTAssertEqual(g.state.hangarCapacity, 6)
        days(&g, Transfer.shipDays)
        XCTAssertEqual(g.state.local.balloons.count, 8)
        XCTAssertEqual(g.state.outsideCount, 2)
        XCTAssertTrue(g.state.local.outsideIDs.isSuperset(of: [700, 701]), "the newest stand outside")
    }
}
