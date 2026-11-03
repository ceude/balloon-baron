import XCTest
@testable import BalloonBaronCore

/// v135 / v135.1: the outskirts' numbers and the valley's layout, checked against the prototype (`outLayout` dumped
/// from prototype/balloon-baron.html v135.1).
final class Outskirts135Tests: XCTestCase {
    /// The off-map places' ground (app `ContractPlace.free`, shifted), which the layout keeps clear of.
    static func free(_ r: RegionID) -> (Double, Double) -> Bool {
        let rects: [(Double, Double, Double, Double)], shift: (Double, Double)
        switch r {
        case .abq: rects = [(3, 17.5, 19, 33)]; shift = (0, 12)
        case .lux: rects = [(23.5, -12.5, 37, -6.5), (29.5, -9, 31.8, 8.6)]; shift = (0, 0)
        case .bri: rects = [(-20, 3, -5.6, 10.6)]; shift = (0, 0)
        case .cap: rects = [(19.5, -2.5, 48, 9.6)]; shift = (0, 0)
        }
        return { gx, gy in let x = gx - shift.0, y = gy - shift.1; return !rects.contains { x > $0.0 && x < $0.2 && y > $0.1 && y < $0.3 } }
    }

    struct Expect {
        var region: RegionID, tracks: [Double], sites: Int, fields: [(Double, Double)], decor: [String], crews: [(Double, Double)], loops: Int, trees: Int
    }

    func testLayoutMatchesPrototype() {
        let all = [
        Expect(region: .cap, tracks: [16.65, 14.85, 11.7, 14.85, 12.6, 6.3, 8.55, 6.75], sites: 40, fields: [(11.298481829, -6.101115004), (-2.785091351, 20.671131186), (22.934850915, -3.589925473), (10.871543245, -10.470263379), (1.648927381, 24.66514705), (-5.888823175, 22.565547158), (0.571300342, 27.742944037), (14.010422599, -11.855246206)],
               decor: ["orchard", "vine", "dovecote", "view", "orchard", "farm", "vine", "rival", "orchard", "dovecote", "farm", "vine", "rival"], crews: [(-2.336580356, 23.285385709), (16.848895905, -5.069776583), (-4.297709864, 15.513847463), (15.696825553, -8.709726756), (14.344209341, 36.655915517)], loops: 1, trees: 16),
        Expect(region: .abq, tracks: [16.65, 13.95, 8.1, 16.65, 14.85, 13.95, 8.1, 5.4, 8.1, 6.3], sites: 38, fields: [(12.680306718, -4.235486987), (-1.807642159, 19.950779339), (12.308649871, -8.318697288), (3.04547791, 23.996267935), (19.131239996, -7.310196342), (22.346881553, -4.380604731), (4.530062353, 26.225443948), (-4.946635791, 23.52974807)],
               decor: ["scrub", "rv", "mesa", "view", "farm", "scrub", "mesa", "rival", "scrub", "mesa", "rival"], crews: [(-1.81653341, 28.593352101), (24.175353782, -2.04420971), (-1.347710854, 30.474169982), (16.191563297, -3.627517194), (-10.103871914, 10.389494766), (39.670962872, 11.844968832)], loops: 2, trees: 25),
        Expect(region: .lux, tracks: [16.65, 14.85, 13.95, 16.65, 8.1, 13.95, 5.85, 6.75, 7.2, 7.65], sites: 39, fields: [(11.543727945, -3.739329483), (-0.715300961, 20.370353803), (3.912831392, 24.348084647), (21.861444055, -0.661889526), (24.912757576, 5.270421068), (-5.650600062, 21.8657031), (19.6623201, -7.134979857), (-1.338328206, 25.088983004)],
               decor: ["cane", "palms", "crops", "view", "farm", "cane", "palms", "crops", "rival", "cane", "palms", "rival"], crews: [(-3.492707361, 20.124536742), (23.308895612, -3.205370543), (-14.276529738, 13.609784198), (13.515883532, -7.466308977), (16.5394807, 36.145051941), (38.966595944, 14.403630007)], loops: 2, trees: 23),
        Expect(region: .bri, tracks: [16.65, 13.95, 13.95, 16.65, 14.85, 13.95, 8.55, 5.4, 6.75], sites: 38, fields: [(0.289412615, 18.705208156), (12.495354112, -5.304063627), (22.147171704, -3.816572567), (3.339025722, 25.911895344), (25.937726638, -3.364681326), (5.027135181, 28.793547546), (1.224420525, 29.666685532), (24.171168405, -5.896533255)],
               decor: ["pasture", "pasture", "farm", "view", "pasture", "crops", "pasture", "rival", "farm", "pasture", "rival"], crews: [(-1.932863035, 20.59841503), (23.656766695, -1.766815775), (-0.648309041, 27.578502345), (17.489529343, -4.520145051), (15.681309206, 36.624599886), (34.075978431, 16.241313828)], loops: 2, trees: 18)
        ]
        for e in all {
            let L = OutskirtsLayout(region: e.region, free: Self.free(e.region))
            XCTAssertEqual(L.tracks.count, e.tracks.count, "\(e.region) tracks")
            for (t, len) in zip(L.tracks, e.tracks) { XCTAssertEqual(t.len, len, accuracy: 1e-6, "\(e.region) track length") }
            XCTAssertEqual(L.sites.count, e.sites, "\(e.region) sites")
            XCTAssertEqual(L.fields.count, Outskirts.maxFields, "\(e.region) fields")
            for (c, f) in zip(L.fields, e.fields) { XCTAssertEqual(c.cx, f.0, accuracy: 1e-6); XCTAssertEqual(c.cy, f.1, accuracy: 1e-6) }
            XCTAssertEqual(L.decor.compactMap { $0.kind?.rawValue }, e.decor, "\(e.region) decor")
            XCTAssertEqual(L.crews.count, e.crews.count, "\(e.region) crews")
            for (k, s) in zip(L.crews, e.crews) { XCTAssertEqual(k.spot.x, s.0, accuracy: 1e-6); XCTAssertEqual(k.spot.y, s.1, accuracy: 1e-6) }
            XCTAssertEqual(L.loops.count, e.loops, "\(e.region) loops")
            XCTAssertEqual(L.trees.count, e.trees, "\(e.region) trees")
            // everything stays on the flanks, away from the town, the main roads and each other
            for c in L.sites {
                for p in c.poly { XCTAssertTrue(Outskirts.flank(p.x, p.y) || abs(abs(p.x - p.y) - Outskirts.calm) < 0.3) }
                XCTAssertFalse(c.cx > -2.5 && c.cx < 17.5 && c.cy > -2.5 && c.cy < 17.5)
                XCTAssertFalse(L.sites.contains { $0.cx != c.cx && $0.contains(c.cx, c.cy, 0) }, "plots overlap")
            }
            for T in L.tracks { for p in T.P { XCTAssertTrue(Outskirts.flank(p.x, p.y)) } }
        }
    }

    func testFieldsCrewsAndUse() {
        XCTAssertEqual(Outskirts.fields(inside: 6), 0)
        XCTAssertEqual(Outskirts.fields(inside: 17), 0)
        XCTAssertEqual(Outskirts.fields(inside: 18), 1)
        XCTAssertEqual(Outskirts.fields(inside: 100), 7)
        XCTAssertEqual(Outskirts.fields(inside: 294), 24)
        XCTAssertEqual(Outskirts.fields(inside: 800), 24)
        XCTAssertEqual(Outskirts.crews(fields: 0), 1)
        XCTAssertEqual(Outskirts.crews(fields: 6), 2)
        XCTAssertEqual(Outskirts.crews(fields: 24), 4)
        // the nearest field is always in use, the rest about half the time, the same all day
        XCTAssertTrue(Outskirts.inUse(0, fields: 3, day: 77))
        XCTAssertFalse(Outskirts.inUse(3, fields: 3, day: 77))
        var used = 0
        for day in 1...200 { for i in 1..<24 where Outskirts.inUse(i, fields: 24, day: day) { used += 1 } }
        XCTAssertEqual(Double(used) / Double(200 * 23), Outskirts.useShare, accuracy: 0.05)
        XCTAssertEqual(Outskirts.inUse(5, fields: 24, day: 300), Outskirts.inUse(5, fields: 24, day: 300))
    }

    func testHeadquartersParts() {
        var h = Holding()
        XCTAssertEqual(Outskirts.hqParts(h), 0)
        h.offices = [.nyc: 1, .ist: 2]
        XCTAssertEqual(Outskirts.hqParts(h), 2)
        h.research = 2
        XCTAssertEqual(Outskirts.hqParts(h), 4)
        // v137: six offices and four R&D levels grow it to ten, no further
        h.research = 9
        XCTAssertEqual(Outskirts.hqParts(h), Outskirts.maxHQParts)
    }
}
