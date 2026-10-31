import SwiftUI
import BalloonBaronCore

// v125–v125.5: the contract places outside town (port of the prototype's `ctrGround`, `ctrSpotItems`, `busGround/Items`,
// `shipGround/Items`, `trainGround/Items`, `coach`, `cruiseShip`, `felucca`, `steamTrain`, `ctrXferItems`).
// Each region's place lies on its own road out of town, past the edge of every default view. Near town the road stays
// the town's dirt road. Albuquerque: the Route 66 highway ends at a coach terminal; Luxor: a cruise pier on the Nile;
// Bristol: a small station with a red steam train. The vehicle stands there while a job of yours runs; empty otherwise.

/// Where each region's place is, and how the jeeps go (`CTR` spot/shift and `CTR_KINDS`).
struct ContractPlace {
    /// Layout point of the place, and the shift that moves the whole layout out of every default view.
    var spot: (Double, Double)
    var shift: (Double, Double)
    /// Ground kept clear of the outer scenery, and the tap area (layout coordinates: x0, y0, x1, y1).
    var free: [(Double, Double, Double, Double)]
    var tap: (Double, Double, Double, Double)
    /// The road from the jeep stops in front of your office to the place (town coordinates, before the shift).
    var town: [(Double, Double)]

    static func of(_ r: RegionID) -> ContractPlace? {
        switch r {
        case .abq: ContractPlace(spot: (12.2, 24.4), shift: (0, 12), free: [(3, 17.5, 19, 33)], tap: (8.4, 18.6, 14.6, 26.5), town: [(8, 14.95), (8, 22)])
        case .lux: ContractPlace(spot: (30, -10.4), shift: (0, 0), free: [(23.5, -12.5, 37, -6.5), (29.5, -9, 31.8, 8.6)], tap: (26, -13.8, 34.5, -8.4),
                                 town: [(8, 14.95), (8, 8), (24, 8)])
        case .bri: ContractPlace(spot: (-11, 6.4), shift: (0, 0), free: [(-20, 3, -5.6, 10.6)], tap: (-18, 3.8, -6.4, 9.8), town: [(8, 14.95), (8, 8), (-6, 8)])
        // v126: NAV · Nevşehir Airport at the end of the east road
        case .cap: ContractPlace(spot: (30, 3), shift: (0, 0), free: [(19.5, -2.5, 48, 9.6)], tap: (23.5, -0.2, 36.5, 7.6), town: [(8, 14.95), (8, 8), (23.5, 8)])
        }
    }

    /// The place's point in town coordinates.
    var center: (Double, Double) { (spot.0 + shift.0, spot.1 + shift.1) }

    /// The outer scenery keeps clear of the place (`ctrSpotFree`).
    func isFree(_ gx: Double, _ gy: Double) -> Bool {
        let x = gx - shift.0, y = gy - shift.1
        return !free.contains { x > $0.0 && x < $0.2 && y > $0.1 && y < $0.3 }
    }

    /// The tap area on screen (`ctrTapHit`).
    func hit(_ p: CGPoint, _ v: TownViewport) -> Bool {
        let (a, b, c, d) = tap, s = shift
        let pts = [TownGeo.iso(a + s.0, b + s.1), TownGeo.iso(c + s.0, b + s.1), TownGeo.iso(c + s.0, d + s.1), TownGeo.iso(a + s.0, d + s.1)].map(v.screen)
        return TownGeo.inPoly(p, pts)
    }
}

/// What happens at the place now, in painter time: when a job's vehicle pulled in, when a finished job's vehicle left,
/// the first offer's scene. Kept outside the game (like the prototype's `arrT` / `t1`); only the main thread uses it.
final class ContractTown {
    static let shared = ContractTown()
    var arriveT: [Int: Double] = [:]
    var departT: Double?
    /// The first offer's scene is on: the offer's vehicle comes in at `cineArrive`.
    var cine = false
    var cineArrive: Double?
    /// An arrival or departure waiting to be written to the game (outside the canvas's drawing).
    var pending = false
    var humLevel = 0.0
}

/// A vehicle at the place: its owner's color, and when it is pulling in (`t0`) or leaving (`t1`).
struct ContractVehicle { var color: String; var t0: Double?; var t1: Double? }

extension ContractKind {
    /// The region whose texts this vehicle's contracts use.
    var region: String {
        switch self {
        case .bus: "abq"
        case .ship: "lux"
        case .train: "bri"
        case .plane: "cap"
        }
    }

    /// The sound engine's index for its arrival and its hum.
    var sound: Int {
        switch self {
        case .bus: 0
        case .ship: 1
        case .train: 2
        case .plane: 3
        }
    }

    /// How long its arrival and its departure take (`CTR_KINDS[kind].arrDur / depDur`): v126.1 the coaches drive in and
    /// out on curves; v126 the plane's landing and take-off.
    var arrDur: Double {
        switch self {
        case .bus: 8.6
        case .plane: 13.5
        case .ship, .train: 8
        }
    }

    var depDur: Double {
        switch self {
        case .bus: 12.2
        case .plane: 14
        case .ship, .train: 9
        }
    }
}

enum ContractGeo {
    static let bays = [9.2, 10.2, 11.2], bayGY = 22.5
    static func easeIO3(_ k: Double) -> Double { k < 0.5 ? 4 * k * k * k : 1 - pow(-2 * k + 2, 3) / 2 }
    static func clamp01(_ x: Double) -> Double { min(max(x, 0), 1) }

    /// Vehicles at the place now (`ctrVehicles`): your running jobs' (once arrived), a finished job's waiting to leave,
    /// and in the first offer's scene the offer's. v126.1: the arrival plays only while `arriveT ≤ t < arriveT + arrDur`;
    /// after a restart (no time kept) the vehicle simply stands there.
    static func vehicles(_ s: GameState, _ t: Double) -> [ContractVehicle] {
        guard let K = s.contractConfig, let C = s.local.contracts else { return [] }
        let T = ContractTown.shared, bus = K.kind == .bus
        let room = bus ? bays.count : 1
        func many(_ n: Int) -> Int { bus ? min(max(Int((Double(n) / 50).rounded(.up)), 1), 3) : 1 }
        var out: [ContractVehicle] = []
        for k in s.contractParked {
            let t0 = T.arriveT[k.id].flatMap { a in t >= a && t - a < K.kind.arrDur ? a : nil }
            for _ in 0..<many(k.n) where out.count < room { out.append(ContractVehicle(color: k.owner.color, t0: t0, t1: nil)) }
        }
        if let dp = C.depart, s.day >= dp.from, !(T.departT.map { t - $0 > K.kind.depDur } ?? false) {
            for _ in 0..<many(dp.n) where out.count < room { out.append(ContractVehicle(color: dp.owner.color, t0: nil, t1: T.departT)) }
        }
        if T.cine, let o = C.offer, out.isEmpty {
            for _ in 0..<many(o.n) { out.append(ContractVehicle(color: o.owner.color, t0: T.cineArrive, t1: nil)) }
        }
        return out
    }

    /// The passengers change into jeeps on a morning a job of yours flies, and in the first offer's scene (`ctrXferOn`).
    static func jeepsOn(_ s: GameState) -> Bool {
        if let k = s.contractToday, !s.contractOff(k) { return true }
        return ContractTown.shared.cine && s.local.contracts?.offer != nil
    }
}

extension TownPainter {
    private func q(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> [CGPoint] {
        [iso(x0, y0), iso(x1, y0), iso(x1, y1), iso(x0, y1)]
    }
    private mutating func quad(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: String) { poly(q(x0, y0, x1, y1), hex(col)) }
    private mutating func quad(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Color) { poly(q(x0, y0, x1, y1), col) }

    /// Plastered blocks (the prototype's `TUFF.smooth`), keeping the region's brick look.
    private mutating func smooth(_ f: (inout TownPainter) -> Void) {
        let keep = tuffOverride
        var t = tuff
        t.smooth = true
        tuffOverride = t
        f(&self)
        tuffOverride = keep
    }

    private mutating func sign(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, color: Color, angle: CGFloat = 0, weight: String = "BarlowCondensed-ExtraBold") {
        var g = c
        g.translateBy(x: x, y: y)
        if angle != 0 { g.rotate(by: .radians(Double(angle))) }
        g.draw(Text(s).font(.custom(weight, fixedSize: size)).foregroundColor(color), at: .zero, anchor: .center)
    }

    // MARK: Entry points

    /// The flat ground of the place, drawn with the outer decor (`ctrGround`).
    mutating func contractGround() {
        guard let K = s.contractConfig, let P = ContractPlace.of(s.region) else { return }
        let keep = c
        c.translateBy(x: CGFloat(P.shift.0 - P.shift.1) * TownGeo.TW / 2, y: CGFloat(P.shift.0 + P.shift.1) * TownGeo.TH / 2)
        switch K.kind {
        case .bus: busGround()
        case .ship: shipGround()
        case .train: trainGround()
        case .plane: airGround()
        }
        c = keep
    }

    /// Everything standing at the place (`ctrSpotItems`), shifted out of town, with the ground point for the haze.
    func contractItems() -> [TownItem] {
        guard let K = s.contractConfig, let P = ContractPlace.of(s.region) else { return [] }
        var items: [TownItem] = []
        let add: (Double, Double, Double?, @escaping (inout TownPainter) -> Void) -> Void = { gx, gy, dep, f in
            items.append(TownItem(depth: dep ?? gx + gy, at: (gx, gy), draw: f))
        }
        switch K.kind {
        case .bus: busItems(add)
        case .ship: shipItems(add)
        case .train: trainItems(add)
        case .plane: airItems(add)
        }
        if ContractGeo.jeepsOn(s) && !ContractGeo.vehicles(s, t).isEmpty { jeepItems(add, K.kind) }
        let (sx, sy) = P.shift
        if sx == 0 && sy == 0 { return items }
        let dx = CGFloat(sx - sy) * TownGeo.TW / 2, dy = CGFloat(sx + sy) * TownGeo.TH / 2
        return items.map { it in
            TownItem(depth: it.depth + sx + sy, at: it.at.map { ($0.0 + sx, $0.1 + sy) }, draw: { p in
                let keep = p.c
                p.c.translateBy(x: dx, y: dy)
                it.draw(&p)
                p.c = keep
            })
        }
    }

    // MARK: Albuquerque: the coach terminal

    /// Route 66 shield on a pole: the black-capped US shield, or the brown "historic" one.
    private mutating func routeShield(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat, hist: Bool) {
        rect(x - 1.5 * k, y - 64 * k, 3 * k, 64 * k, hex("#6a6a70"))
        var g = c
        g.translateBy(x: x, y: y - 76 * k)
        g.scaleBy(x: k, y: k)
        var sh = Path()
        sh.move(to: pt(-15, -14)); sh.addQuadCurve(to: pt(0, -14), control: pt(-8, -18)); sh.addQuadCurve(to: pt(15, -14), control: pt(8, -18))
        sh.addLine(to: pt(15, 2)); sh.addQuadCurve(to: pt(0, 18), control: pt(14, 12)); sh.addQuadCurve(to: pt(-15, 2), control: pt(-14, 12)); sh.closeSubpath()
        g.fill(sh, with: .color(hex(hist ? "#7a4a24" : "#fdfaf0")))
        g.stroke(sh, with: .color(hex(hist ? "#f4ead0" : "#1a1a1a")), lineWidth: 2.4)
        let ink = hex(hist ? "#f4ead0" : "#1a1a1a"), f = "BarlowCondensed-ExtraBold"
        if hist {
            g.draw(Text("HISTORIC").font(.custom(f, fixedSize: 5)).foregroundColor(ink), at: pt(0, -9), anchor: .center)
            g.draw(Text("ROUTE").font(.custom(f, fixedSize: 5)).foregroundColor(ink), at: pt(0, -3.5), anchor: .center)
            g.draw(Text("66").font(.custom(f, fixedSize: 14)).foregroundColor(ink), at: pt(0, 7), anchor: .center)
        } else {
            g.fill(Path(CGRect(x: -14, y: -12, width: 28, height: 6)), with: .color(ink))
            g.draw(Text("U S").font(.custom(f, fixedSize: 5)).foregroundColor(hex("#fdfaf0")), at: pt(0, -9), anchor: .center)
            g.draw(Text("66").font(.custom(f, fixedSize: 17)).foregroundColor(ink), at: pt(0, 5), anchor: .center)
        }
    }

    /// A tour coach. (gx, gy) is the middle of its front bumper, `hd` its heading in grid space (−π/2: nose towards town,
    /// along −gy, as it stands in a bay). v126.1: drawn turned any way, so it can drive along curves: of its four sides
    /// the two facing the viewer (+gx +gy) are drawn: the right side with the door near the front, the left side, the
    /// rear (tail lights, rear window, grille) or the front (windscreen, headlights); idling, it shivers and puffs.
    mutating func coach(_ gx: Double, _ gy: Double, _ col: String, idle: Bool, hd: Double = -.pi / 2) {
        let w = 0.46, d = 1.6, hh: CGFloat = 34, z: CGFloat = 5 + (idle ? CGFloat(sin(t * 38 + gx)) * 0.5 : 0)
        let fx = cos(hd), fy = sin(hd), rx = -fy, ry = fx
        func g(_ a: Double, _ b: Double) -> CGPoint { iso(gx + a * fx + b * rx, gy + a * fy + b * ry) } // a forward, b to the right
        let A = g(0, -w / 2), B = g(0, w / 2), C = g(-d, w / 2), D = g(-d, -w / 2)
        do { let m = g(-d / 2, 0); blobShadow(m.x + 10, m.y + 4, 30 + 22 * CGFloat(abs(fy)), 14 + 4 * CGFloat(abs(fx)), 0.25) }
        let body = "#efe6d2"
        func L(_ p: CGPoint) -> CGPoint { upp(p, z) }
        func shade(_ ny: Double) -> Color { mix(body, "#000000", 0.12 * max(0, ny)) }
        func r(_ g: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: Color) { g.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(col)) }
        func side(_ f: inout GraphicsContext, right: Bool) { // u: 0 at the rear, 1 at the front
            r(&f, 0, 0.2, 1, 0.12, hex(col)); r(&f, 0, 0.32, 1, 0.03, mix(col, "#000000", 0.25))
            r(&f, 0.04, 0.5, right ? 0.8 : 0.92, 0.36, hex("#2a3a50"))
            for i in 0..<6 { r(&f, 0.07 + CGFloat(i) * 0.13, 0.78, 0.05, 0.06, Color.white.opacity(0.18)) }
            for i in 1..<7 { r(&f, 0.04 + CGFloat(i) * 0.133, 0.5, 0.012, 0.36, hex(body)) }
            if right { r(&f, 0.87, 0.06, 0.1, 0.8, hex("#2a3a50")); r(&f, 0.918, 0.06, 0.006, 0.8, Color.white.opacity(0.25)) } // the door
            r(&f, 0, 0, 1, 0.05, hex("#c0c6cc"))
        }
        func wheels(_ p: CGPoint, _ q: CGPoint) {
            for u in [0.2, 0.84] as [CGFloat] { let c = lp(p, q, u); ellipse(c.x, c.y - 6, 7, 7, hex("#1f1c22")); ellipse(c.x, c.y - 6, 3, 3, hex("#a8a8b0")) }
        }
        func seen(_ nx: Double, _ ny: Double) -> Bool { nx + ny > 1e-6 }
        if seen(rx, ry) { // the right side
            wheels(C, B)
            poly([L(C), L(B), upp(B, z + hh), upp(C, z + hh)], shade(ry))
            var f = face(L(C), L(B), hh); side(&f, right: true)
        }
        if seen(-rx, -ry) { // the left side
            wheels(D, A)
            poly([L(D), L(A), upp(A, z + hh), upp(D, z + hh)], shade(-ry))
            var f = face(L(D), L(A), hh); side(&f, right: false)
        }
        if seen(-fx, -fy) { // the rear
            let c = lp(D, C, 0.5); ellipse(c.x - 6, c.y - 6, 4, 6, hex("#1f1c22"))
            poly([L(D), L(C), upp(C, z + hh), upp(D, z + hh)], shade(-fy))
            var e = face(L(D), L(C), hh)
            r(&e, 0.15, 0.62, 0.7, 0.26, hex("#2a3a50")); r(&e, 0, 0.2, 1, 0.12, hex(col))
            r(&e, 0.06, 0.1, 0.1, 0.16, hex("#e5432f")); r(&e, 0.84, 0.1, 0.1, 0.16, hex("#e5432f"))
            for i in 0..<5 { r(&e, 0.3, 0.4 + CGFloat(i) * 0.035, 0.4, 0.015, hex("#c8c0b0")) }
        }
        if seen(fx, fy) { // the front
            poly([L(A), L(B), upp(B, z + hh), upp(A, z + hh)], shade(fy))
            var e = face(L(A), L(B), hh)
            r(&e, 0.08, 0.42, 0.84, 0.48, hex("#1e2a3c")); r(&e, 0, 0.2, 1, 0.12, hex(col))
            r(&e, 0.08, 0.08, 0.14, 0.07, hex("#fff6c8")); r(&e, 0.78, 0.08, 0.14, 0.07, hex("#fff6c8"))
        }
        let a = upp(A, z + hh), b = upp(B, z + hh), cc = upp(C, z + hh), dd = upp(D, z + hh)
        poly([a, b, cc, dd], hex("#f8f2e4"))
        poly([lp(a, dd, 0.3), lp(b, cc, 0.3), lp(b, cc, 0.55), lp(a, dd, 0.55)], hex("#d8d2c4"))
        if idle {
            let p = upp(lp(D, C, 0.85), z + 2)
            for i in 0..<4 {
                let ph = CGFloat((t * 0.9 + Double(i) / 4).truncatingRemainder(dividingBy: 1))
                ellipse(p.x - 4 - ph * 16, p.y + 2 - ph * 26, 3 + ph * 9, 3 + ph * 7, hex("#9a9aa4").opacity(Double((1 - ph) * 0.35)))
            }
        }
    }

    private mutating func busGround() {
        let A = 20.9, E = 58.0 // the highway ends at the terminal: asphalt from the lot outwards only
        quad(7.45, A, 8.55, E, "#5e5a62"); quad(7.45, A, 7.55, E, "#e8e0d0"); quad(8.45, A, 8.55, E, "#e8e0d0")
        var y = A + 1.2
        while y < E { quad(7.97, y, 8.03, y + 0.45, "#ffd23a"); y += 0.9 }
        quad(7.45, A, 8.55, A + 0.14, "#f4f0e6")
        // the shuttle stand: packed dirt by the road where the jeeps wait
        quad(8.4, 18.7, 11.6, 20.75, "#c48a62")
        var R = rng(8)
        var specks = Path()
        for _ in 0..<50 { let p = iso(8.5 + R.next() * 3, 18.8 + R.next() * 1.9); specks.addRect(CGRect(x: p.x, y: p.y, width: 4, height: 2)) }
        c.fill(specks, with: .color(rgba(90, 60, 40, 0.3)))
        quad(8.55, 20.9, 14.6, 26.4, "#6c6870"); quad(8.55, 20.9, 14.6, 21.0, "#d8d0c0"); quad(8.55, 26.3, 14.6, 26.4, "#d8d0c0")
        for x in ContractGeo.bays { quad(x - 0.43, 21.3, x - 0.4, 24.6, "#f4f0e6"); quad(x + 0.4, 21.3, x + 0.43, 24.6, "#f4f0e6") }
        quad(9.3, 25.1, 12.2, 25.5, "#e8b23a")
        let p = iso(11.6, 25.9)
        var g = c
        g.translateBy(x: p.x, y: p.y)
        g.concatenate(CGAffineTransform(a: 1, b: 0.5, c: -1, d: 0.5, tx: 0, ty: 0))
        g.draw(Text("BUS ONLY").font(.custom("BarlowCondensed-ExtraBold", fixedSize: 26)).foregroundColor(Color.white.opacity(0.75)), at: pt(0, -8), anchor: .center)
    }

    private func busItems(_ add: (Double, Double, Double?, @escaping (inout TownPainter) -> Void) -> Void) {
        add(13.2, 23.8, 12.9 + 1.6 + 21.3 + 4.9 - 0.5) { p in
            p.smooth { p in
                let f = p.block(12.9, 21.3, 1.6, 4.9, 38, lit: "#e9c9a0", shade: "#c49a72", top: "#d8b68c", courses: false)
                var a = p.face(f.D, f.C, 38)
                a.fill(Path(CGRect(x: 0, y: 0.82, width: 1, height: 0.1)), with: .color(p.hex("#2a8a9a")))
                a.fill(Path(CGRect(x: 0.3, y: 0, width: 0.4, height: 0.55)), with: .color(p.hex("#3a2a24")))
                a.fill(Path(CGRect(x: 0.34, y: 0.06, width: 0.32, height: 0.45)), with: .color(p.hex("#7ab8c8")))
                var b = p.face(f.C, f.B, 38)
                b.fill(Path(CGRect(x: 0, y: 0.82, width: 1, height: 0.1)), with: .color(p.hex("#2a8a9a")))
                for i in 0..<6 {
                    let x = 0.06 + CGFloat(i) * 0.16
                    b.fill(Path(CGRect(x: x, y: 0.25, width: 0.1, height: 0.38)), with: .color(p.hex("#3a4a5a")))
                    b.fill(Path(CGRect(x: x, y: 0.5, width: 0.1, height: 0.13)), with: .color(p.rgba(255, 240, 200, 0.35)))
                }
                let s0 = p.upp(p.lp(f.C, f.B, 0.2), 38), s1 = p.upp(p.lp(f.C, f.B, 0.8), 38)
                p.rect(s0.x - 1, s0.y - 20, 2, 20, p.hex("#5a5a60")); p.rect(s1.x - 1, s1.y - 20, 2, 20, p.hex("#5a5a60"))
                var sg = p.face(p.upp(s0, 18), p.upp(s1, 18), 26)
                sg.fill(Path(CGRect(x: 0, y: 0, width: 1, height: 1)), with: .color(p.hex("#c0392b")))
                sg.fill(Path(CGRect(x: 0, y: 0.86, width: 1, height: 0.14)), with: .color(p.hex("#ffd23a")))
                sg.fill(Path(CGRect(x: 0, y: 0, width: 1, height: 0.1)), with: .color(p.hex("#ffd23a")))
                let m = p.lp(p.upp(s0, 31), p.upp(s1, 31), 0.5), ang = atan2(s0.y - s1.y, s0.x - s1.x) + .pi
                p.sign("TOUR COACH TERMINAL", m.x, m.y, size: 15, color: p.hex("#fff6dc"), angle: ang)
            }
        }
        add(11.2, 23.6, 12.9 + 25.4 - 0.2) { p in
            for gy in [21.4, 23.2, 25] { let q = p.iso(12.75, gy); p.rect(q.x - 2, q.y - 64, 4, 64, p.hex("#8a8a90")) }
            let r = [p.iso(12.0, 21.2), p.iso(12.9, 21.2), p.iso(12.9, 25.4), p.iso(12.0, 25.4)].map { p.upp($0, 64) }
            p.poly(r, p.hex("#2aa0a8")); p.poly([r[3], r[2], p.upp(r[2], -5), p.upp(r[3], -5)], p.hex("#1f7f88"))
        }
        add(11.7, 19.2, nil) { p in // the shuttle stand's sign
            let q = p.iso(11.7, 19.2)
            p.rect(q.x - 2, q.y - 46, 4, 46, p.hex("#6a4a2a"))
            let box = Path(roundedRect: CGRect(x: q.x - 30, y: q.y - 66, width: 60, height: 24), cornerRadius: 5)
            p.c.fill(box, with: .color(p.hex("#fff1d6"))); p.c.stroke(box, with: .color(p.hex("#c0392b")), lineWidth: 2)
            p.sign("BALLOON", q.x, q.y - 59, size: 11, color: p.hex("#2b2350")); p.sign("SHUTTLE", q.x, q.y - 49, size: 11, color: p.hex("#2b2350"))
        }
        add(8.75, 27.4, nil) { p in let q = p.iso(8.75, 27.4); p.routeShield(q.x, q.y, 1.25, hist: false) }
        add(8.75, 33, nil) { p in let q = p.iso(8.75, 33); p.routeShield(q.x, q.y, 1.25, hist: true) }
        add(7.1, 24, nil) { p in // the billboard
            let a = p.iso(7.1, 23.2), b = p.iso(7.1, 24.8)
            for q in [a, b] { p.rect(q.x - 2, q.y - 70, 4, 70, p.hex("#5a4a3a")) }
            var f = p.face(p.upp(a, 50), p.upp(b, 50), 44)
            f.fill(Path(CGRect(x: 0, y: 0, width: 1, height: 1)), with: .color(p.hex("#fff1d6")))
            f.fill(Path(CGRect(x: 0, y: 0, width: 1, height: 0.2)), with: .color(p.hex("#e08a1e")))
            f.fill(Path(CGRect(x: 0, y: 0.8, width: 1, height: 0.2)), with: .color(p.hex("#2a8a9a")))
            let m = p.lp(p.upp(a, 72), p.upp(b, 72), 0.5), ang = atan2(a.y - b.y, a.x - b.x)
            p.sign("ROUTE 66", m.x, m.y - 4, size: 19, color: p.hex("#c0392b"), angle: ang)
            var g = p.c
            g.translateBy(x: m.x, y: m.y); g.rotate(by: .radians(Double(ang)))
            g.draw(Text("TOUR COACHES · LAST STOP").font(.custom("BarlowCondensed-Bold", fixedSize: 10)).foregroundColor(p.hex("#2b2350")), at: p.pt(0, 11), anchor: .center)
        }
        add(14.1, 27.9, nil) { p in // the diner
            p.smooth { p in
                let f = p.block(13.2, 27.3, 1.8, 1.2, 26, lit: "#f4f0e6", shade: "#d0c8b8", top: "#e04a3a", courses: false)
                var a = p.face(f.D, f.C, 26)
                a.fill(Path(CGRect(x: 0, y: 0.78, width: 1, height: 0.22)), with: .color(p.hex("#e04a3a")))
                a.fill(Path(CGRect(x: 0.08, y: 0.3, width: 0.84, height: 0.36)), with: .color(p.hex("#7ab8c8")))
                for i in 1..<6 { a.fill(Path(CGRect(x: 0.08 + CGFloat(i) * 0.14, y: 0.3, width: 0.02, height: 0.36)), with: .color(p.hex("#f4f0e6"))) }
                var b = p.face(f.C, f.B, 26)
                b.fill(Path(CGRect(x: 0, y: 0.78, width: 1, height: 0.22)), with: .color(p.hex("#e04a3a")))
                b.fill(Path(CGRect(x: 0.35, y: 0, width: 0.3, height: 0.62)), with: .color(p.hex("#3a2a24")))
                let q = p.upp(p.iso(13.4, 28.5), 26)
                p.rect(q.x - 1.5, q.y - 34, 3, 34, p.hex("#5a5a60"))
                let on = p.night != nil || sin(p.t * 2.2) > -0.7
                let box = Path(roundedRect: CGRect(x: q.x - 26, y: q.y - 56, width: 52, height: 24), cornerRadius: 8)
                p.c.fill(box, with: .color(p.hex("#1f2a44"))); p.c.stroke(box, with: .color(p.hex(on ? "#ff6fa8" : "#7a4a6a")), lineWidth: 2)
                p.sign("66 DINER", q.x, q.y - 44, size: 15, color: p.hex(on ? "#ffd23a" : "#8a7a4a"))
            }
        }
        for (gx, gy, w, hh) in [(4.2, 20.5, 210.0, 120.0), (5.6, 18.6, 150, 80), (16.4, 20.2, 230, 140), (17.6, 23.4, 160, 90), (17.4, 30.4, 200, 110), (6.2, 31.4, 180, 100)] {
            add(gx, gy, nil) { p in let q = p.iso(gx, gy); p.butte(q.x, q.y, CGFloat(w), CGFloat(hh), "#d98a78", "#9a5050") }
        }
        for (gx, gy, k) in [(12.4, 27.4, 0), (12.6, 29.4, 1), (14.9, 22.1, 2), (6.6, 21.6, 1), (6.4, 26.5, 0), (15.2, 26.2, 2), (11.8, 29.8, 1), (15.6, 29.2, 0),
                            (9.2, 30.6, 2), (13.2, 31.2, 0), (16.8, 27.6, 1)] {
            add(gx, gy, nil) { p in
                let q = p.iso(gx, gy)
                if k == 0 { p.yucca(q.x, q.y, 1.1) } else if k == 1 { p.cholla(q.x, q.y, 1) } else { p.roundTree(q.x, q.y, 0.6, "#7a8a50") }
            }
        }
        let T = t, bays = ContractGeo.bays
        for (i, v) in ContractGeo.vehicles(s, T).enumerated() {
            let bx = bays[bays.count - 1 - i]
            var gx = bx, gy = ContractGeo.bayGY, hd = -Double.pi / 2, al = 1.0
            if let t0 = v.t0 { // v126.1: in from the highway, round into the bay
                let q = CoachPath.pose(bx, i, T - t0 - Double(i) * 0.9, leaving: false)
                (gx, gy, hd) = (q.p.0, q.p.1, q.hd)
            }
            if let t1 = v.t1 { // out of the bay forwards, round onto the highway, away
                let u = T - t1 - Double(i) * 2.4, q = CoachPath.pose(bx, i, u, leaving: true)
                (gx, gy, hd) = (q.p.0, q.p.1, q.hd)
                al = 1 - ContractGeo.clamp01((u - 5.6) / 1.4)
            }
            let mx = gx - cos(hd) * CoachPath.length / 2, my = gy - sin(hd) * CoachPath.length / 2
            let x = gx, y = gy, h = hd, col = v.color, a = al
            add(mx, my, mx + my + 0.4) { p in
                let keep = p.c
                p.c.opacity *= a
                p.coach(x, y, col, idle: true, hd: h)
                p.c = keep
            }
        }
    }

    // MARK: Luxor: the cruise pier

    /// A three-deck Nile cruise ship moored along gx: white hull with a dark band, rows of cabin windows, a sun deck under
    /// an awning, the company's funnel; it bobs on the river.
    mutating func cruiseShip(_ x0: Double, _ y0: Double, _ col: String) {
        let L = 5.0, Wd = 1.1, bob = CGFloat(sin(t * 1.3)) * 2
        let keep = c
        c.translateBy(x: 0, y: bob)
        smooth { p in
            func r(_ g: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: Color) { g.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(col)) }
            let hull = p.block(x0, y0, L, Wd, 16, lit: "#f6f4ee", shade: "#d8d4c8", top: "#c8a878", courses: false)
            var a = p.face(hull.D, hull.C, 16)
            r(&a, 0, 0, 1, 0.32, p.hex("#1f3a5a")); r(&a, 0, 0.34, 1, 0.08, p.hex(col))
            for i in 0..<18 { r(&a, 0.03 + CGFloat(i) * 0.053, 0.58, 0.02, 0.16, p.hex("#3a4a5a")) }
            for i in 0..<4 { r(&a, 0.06 + CGFloat(i) * 0.02, 0.12, 0.012, 0.14, p.hex("#f6f4ee")) }
            var b = p.face(hull.C, hull.B, 16)
            r(&b, 0, 0, 1, 0.32, p.hex("#1f3a5a")); r(&b, 0, 0.34, 1, 0.08, p.hex(col))
            let k2 = p.c
            p.c.translateBy(x: 0, y: -16)
            let d2 = p.block(x0 + 0.3, y0 + 0.1, L - 0.7, Wd - 0.2, 14, lit: "#fbfaf6", shade: "#dedad0", top: "#e8e2d4", courses: false)
            var e = p.face(d2.D, d2.C, 14)
            for i in 0..<14 { r(&e, 0.03 + CGFloat(i) * 0.07, 0.3, 0.045, 0.45, p.hex("#2a4a6a")) }
            var e2 = p.face(d2.C, d2.B, 14)
            r(&e2, 0.15, 0.3, 0.7, 0.45, p.hex("#2a4a6a"))
            p.c.translateBy(x: 0, y: -14)
            let d3 = p.block(x0 + 0.9, y0 + 0.2, L - 2.2, Wd - 0.4, 12, lit: "#fbfaf6", shade: "#dedad0", top: "#e8e2d4", courses: false)
            var e3 = p.face(d3.D, d3.C, 12)
            for i in 0..<8 { r(&e3, 0.04 + CGFloat(i) * 0.12, 0.3, 0.07, 0.45, p.hex("#2a4a6a")) }
            // sun deck awning and the funnel
            let aw = [p.iso(x0 + 0.6, y0 + 0.1), p.iso(x0 + 1.8, y0 + 0.1), p.iso(x0 + 1.8, y0 + Wd - 0.1), p.iso(x0 + 0.6, y0 + Wd - 0.1)].map { p.upp($0, 30) }
            for q in aw { p.rect(q.x - 1, q.y, 2, 18, p.hex("#8a8a90")) }
            p.poly(aw, p.hex("#e8b23a")); p.poly([aw[3], aw[2], p.upp(aw[2], -4), p.upp(aw[3], -4)], p.hex("#c8902a"))
            let f = p.iso(x0 + 3.2, y0 + 0.55)
            p.rect(f.x - 7, f.y - 40, 14, 22, p.hex(col)); p.rect(f.x - 7, f.y - 44, 14, 5, p.hex("#1a1a24"))
            for i in 0..<3 {
                let ph = CGFloat((p.t * 0.4 + Double(i) / 3).truncatingRemainder(dividingBy: 1))
                p.ellipse(f.x + ph * 14, f.y - 48 - ph * 24, 3 + ph * 6, 3 + ph * 5, p.rgba(170, 170, 180, Double(0.4 * (1 - ph))))
            }
            let fl = p.iso(x0 + L - 0.2, y0 + 0.5)
            p.rect(fl.x, fl.y - 46, 2, 22, p.hex("#5a5a60"))
            p.rect(fl.x + 2, fl.y - 46, 12, 4, p.hex("#c0392b")); p.rect(fl.x + 2, fl.y - 42, 12, 4, .white); p.rect(fl.x + 2, fl.y - 38, 12, 4, p.hex("#1a1a1a"))
            p.c = k2
        }
        c = keep
    }

    mutating func felucca(_ x: CGFloat, _ y: CGFloat, _ i: Double) {
        let b = CGFloat(sin(t * 1.1 + i)) * 1.5
        poly([pt(x - 18, y + b), pt(x + 18, y + b), pt(x + 12, y + 6 + b), pt(x - 12, y + 6 + b)], hex("#6a4a2a"))
        line(pt(x, y + b), pt(x, y - 34 + b), hex("#4a3a2a"), 1.5)
        poly([pt(x, y - 34 + b), pt(x + 16, y - 4 + b), pt(x - 2, y - 4 + b)], hex("#fbf6ea"))
    }

    private mutating func shipGround() {
        quad(30.25, -8.6, 30.95, 7.65, outerLook.road) // the dirt track from the pier to the east road
        quad(28.4, -9.95, 32.6, -8.5, "#d4b47e")
        var R = rng(12)
        var specks = Path()
        for _ in 0..<40 { let p = iso(28.5 + R.next() * 4, -9.9 + R.next() * 1.3); specks.addRect(CGRect(x: p.x, y: p.y, width: 4, height: 2)) }
        c.fill(specks, with: .color(rgba(110, 80, 40, 0.25)))
        quad(25.5, -11.3, 35, -10.6, "#d8c08e"); quad(25.5, -11.3, 35, -11.15, "#a88a5a") // the stone quay
        quad(30.5, -12.4, 31.5, -10.6, "#9a6a3a") // the wooden pier
        var y = -12.3
        while y < -10.6 { quad(30.5, y, 31.5, y + 0.03, "#7a4a24"); y += 0.22 }
        var ripples = Path()
        for i in 0..<9 {
            let ph = (t * 0.3 + Double(i) / 9).truncatingRemainder(dividingBy: 1), p = iso(26 + Double(i) * 1.1, -13.5 + ph * 0.2)
            ripples.move(to: pt(p.x - 14, p.y)); ripples.addLine(to: pt(p.x + 14, p.y))
        }
        c.stroke(ripples, with: .color(Color.white.opacity(0.35)), lineWidth: 2)
    }

    private func shipItems(_ add: (Double, Double, Double?, @escaping (inout TownPainter) -> Void) -> Void) {
        add(32.9, -9.9, nil) { p in // the ticket kiosk with its striped awning
            p.smooth { p in _ = p.block(32.5, -10.3, 0.9, 0.7, 22, lit: "#f2e8d4", shade: "#d2c4a4", top: "#e8dcc0", courses: false) }
            let a = [p.iso(32.4, -10.4), p.iso(33.5, -10.4), p.iso(33.5, -9.5), p.iso(32.4, -9.5)].map { p.upp($0, 24) }
            p.poly(a, p.hex("#1f6f8b")); p.poly([a[3], a[2], p.upp(a[2], -5), p.upp(a[3], -5)], p.hex("#e8c47a"))
        }
        add(29.6, -10.2, nil) { p in // the pier sign
            let q = p.iso(29.6, -10.2)
            p.rect(q.x - 30, q.y - 50, 3, 50, p.hex("#5a4a3a")); p.rect(q.x + 28, q.y - 50, 3, 50, p.hex("#5a4a3a"))
            p.c.fill(Path(roundedRect: CGRect(x: q.x - 36, y: q.y - 70, width: 72, height: 24), cornerRadius: 4), with: .color(p.hex("#1f6f8b")))
            p.sign("LUXOR CRUISE PIER", q.x, q.y - 58, size: 11, color: p.hex("#e8c47a"))
        }
        for (gx, gy, k) in [(26.4, -9.9, 1.0), (27.5, -9.7, 0.9), (34.1, -9.8, 1.05), (35.2, -9.5, 0.9), (27.2, -7.2, 0.8), (33.8, -7.4, 0.9)] {
            add(gx, gy, nil) { p in let q = p.iso(gx, gy); p.palm(q.x, q.y, CGFloat(k), tt: p.t + gx) }
        }
        for x in [27.0, 29, 33, 35] {
            add(x, -10.9, nil) { p in let q = p.iso(x, -10.9); p.rect(q.x - 2, q.y - 22, 4, 22, p.hex("#4a3a2a")); p.ellipse(q.x, q.y - 24, 5, 5, p.hex("#ffd27a")) }
        }
        let T = t
        for (x, i) in [(23.8, 0.0), (36.4, 1)] {
            let gx = x + sin(T * 0.1 + i) * 0.4
            add(gx, -12.6, nil) { p in let q = p.iso(gx, -12.6); p.felucca(q.x, q.y, i) }
        }
        if let v = ContractGeo.vehicles(s, T).first {
            var dx = 0.0, al = 1.0
            if let t0 = v.t0 { dx = 9 * (1 - ContractGeo.easeIO3(ContractGeo.clamp01((T - t0) / 4.2))) }
            if let t1 = v.t1 { // casts off and sails away down the Nile
                let e = ContractGeo.clamp01((T - t1) / 6)
                dx = 14 * e * e
                al = 1 - ContractGeo.clamp01((e - 0.7) / 0.3)
            }
            let col = v.color, d = dx, a = al
            add(27.3 + d + 2.5, -12.8, 27.3 + d - 13.4 + 1.6) { p in
                let keep = p.c
                p.c.opacity *= a
                p.cruiseShip(27.3 + d, -13.4, col)
                p.c = keep
            }
        }
    }

    // MARK: Bristol: the station and its red steam train

    mutating func steamTrain(_ x0: Double, _ y0: Double, _ col: String, moving: Bool) {
        smooth { p in
            func r(_ g: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: Color) { g.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(col)) }
            for cx in [x0, x0 + 4.2] { // two carriages
                let f = p.block(cx, y0, 4.1, 0.62, 30, lit: "#8a1f26", shade: "#6a161c", top: "#5a5a62", courses: false)
                var a = p.face(f.D, f.C, 30)
                r(&a, 0, 0.5, 1, 0.34, p.hex("#efe2c4"))
                for i in 0..<8 { r(&a, 0.05 + CGFloat(i) * 0.118, 0.55, 0.07, 0.24, p.hex("#2a3040")) }
                r(&a, 0, 0.45, 1, 0.02, p.hex("#c9a040")); r(&a, 0.47, 0.1, 0.06, 0.3, p.hex("#c9a040"))
                for u in [0.12, 0.25, 0.75, 0.88] as [CGFloat] { let q = p.lp(f.D, f.C, u); p.ellipse(q.x, q.y - 2, 5, 5, p.hex("#1a1a1e")) }
            }
            let tx = x0 + 8.4 // the tender
            let tf = p.block(tx, y0 + 0.02, 0.95, 0.58, 22, lit: col, shade: p.hexMix(col, "#000000", 0.3), top: "#1a1a1e", courses: false)
            do { let q = p.lp(tf.a, tf.c, 0.5); p.ellipse(q.x, q.y - 2, 14, 5, p.hex("#2a2a2e")) }
            let ex = tx + 1.0 // the engine: cab, boiler, smokebox, chimney, big wheels
            _ = p.block(ex, y0 + 0.05, 2.4, 0.52, 8, lit: "#1a1a1e", shade: "#121214", top: "#2a2a2e", courses: false)
            let k2 = p.c
            p.c.translateBy(x: 0, y: -8)
            let cab = p.block(ex, y0 + 0.02, 0.7, 0.58, 30, lit: col, shade: p.hexMix(col, "#000000", 0.3), top: "#2a2a2e", courses: false)
            var cf = p.face(cab.D, cab.C, 30)
            r(&cf, 0.2, 0.45, 0.6, 0.35, p.hex("#2a3040"))
            let boil = p.block(ex + 0.7, y0 + 0.1, 1.55, 0.42, 20, lit: col, shade: p.hexMix(col, "#000000", 0.3), top: p.hexMix(col, "#ffffff", 0.15), courses: false)
            var bf = p.face(boil.D, boil.C, 20)
            for u in [0.25, 0.55, 0.85] as [CGFloat] { r(&bf, u, 0, 0.025, 1, p.hex("#c9a040")) }
            var sb = p.face(boil.C, boil.B, 20)
            sb.fill(Path(ellipseIn: CGRect(x: 0.05, y: 0, width: 0.9, height: 1)), with: .color(p.hex("#1a1a1e")))
            sb.fill(Path(ellipseIn: CGRect(x: 0.42, y: 0.4, width: 0.16, height: 0.2)), with: .color(p.hex("#c9a040")))
            let ch = p.upp(p.iso(ex + 2.05, y0 + 0.32), 20)
            p.rect(ch.x - 5, ch.y - 16, 10, 16, p.hex("#1a1a1e")); p.rect(ch.x - 7, ch.y - 19, 14, 4, p.hex("#1a1a1e"))
            let dome = p.upp(p.iso(ex + 1.4, y0 + 0.32), 20)
            p.ellipse(dome.x, dome.y - 3, 6, 5, p.hex("#c9a040"))
            p.c = k2
            for u in [0.3, 0.55, 0.8] as [CGFloat] {
                let q = p.lp(p.iso(ex, y0 + 0.62), p.iso(ex + 2.4, y0 + 0.62), u)
                p.ellipse(q.x, q.y - 9, 10, 10, p.hex("#1a1a1e")); p.ellipse(q.x, q.y - 9, 7, 7, p.hex(col)); p.ellipse(q.x, q.y - 9, 2.5, 2.5, p.hex("#c9a040"))
            }
            // smoke from the chimney, faster while moving; steam at the wheels
            let sm = p.upp(p.iso(ex + 2.05, y0 + 0.32), 46), shade = moving ? 80.0 : 120.0
            for i in 0..<6 {
                let ph = CGFloat((p.t * (moving ? 1.6 : 0.55) + Double(i) / 6).truncatingRemainder(dividingBy: 1))
                p.ellipse(sm.x - ph * 40, sm.y - ph * 60, 6 + ph * 16, 5 + ph * 12, p.rgba(shade, shade, shade + 8, Double(0.55 * (1 - ph))))
            }
            let w = p.iso(ex + 0.4, y0 + 0.7)
            for i in 0..<3 {
                let ph = CGFloat((p.t * 0.8 + Double(i) / 3).truncatingRemainder(dividingBy: 1))
                p.ellipse(w.x - 6 - ph * 10, w.y - 4 - ph * 6, 4 + ph * 6, 3 + ph * 4, Color.white.opacity(Double(0.5 * (1 - ph))))
            }
        }
    }

    private mutating func trainGround() {
        quad(-30, 5.75, -6.6, 6.75, "#8a8278") // ballast; the rails run off into the far haze
        var x = -30.0
        var sleepers = Path()
        while x < -6.8 { sleepers.addLines(q(x, 5.85, x + 0.12, 6.65)); sleepers.closeSubpath(); x += 0.3 }
        c.fill(sleepers, with: .color(hex("#5a4030")))
        quad(-30, 6.02, -6.7, 6.08, "#6a6a72"); quad(-30, 6.42, -6.7, 6.48, "#6a6a72")
        quad(-14.6, 6.8, -7.2, 7.55, "#b8b0a0"); quad(-14.6, 6.8, -7.2, 6.88, "#e8c440") // the platform with its yellow line
        quad(-11.2, 8.45, -7.6, 9.75, "#9a968e")
        var R = rng(14)
        var specks = Path()
        for _ in 0..<40 { let p = iso(-11.1 + R.next() * 3.4, 8.5 + R.next() * 1.2); specks.addRect(CGRect(x: p.x, y: p.y, width: 4, height: 2)) }
        c.fill(specks, with: .color(rgba(60, 60, 60, 0.25)))
    }

    private func trainItems(_ add: (Double, Double, Double?, @escaping (inout TownPainter) -> Void) -> Void) {
        add(-12, 4.9, -13.6 + 3.4 + 4.2 + 1.3 - 0.5) { p in // the station: red brick, slate roof, a clock
            p.smooth { p in
                let f = p.block(-13.6, 4.2, 3.4, 1.3, 34, lit: "#a8503a", shade: "#86402e", top: "#5e6874", courses: false)
                var a = p.face(f.D, f.C, 34)
                for i in 0..<5 {
                    a.fill(Path(CGRect(x: 0.08 + CGFloat(i) * 0.18, y: 0.3, width: 0.09, height: 0.4)), with: .color(p.hex("#f4efe4")))
                    a.fill(Path(CGRect(x: 0.095 + CGFloat(i) * 0.18, y: 0.33, width: 0.06, height: 0.34)), with: .color(p.hex("#2a3040")))
                }
                p.gableRoof(-13.6, 4.2, 3.4, 1.3, 34, 20, "#5e6874", eave: 0.1)
                let cl = p.upp(p.lp(f.D, f.C, 0.5), 52)
                p.ellipse(cl.x, cl.y, 9, 9, p.hex("#f6f2e4"))
                var hands = Path()
                hands.addEllipse(in: CGRect(x: cl.x - 9, y: cl.y - 9, width: 18, height: 18))
                hands.move(to: cl); hands.addLine(to: p.pt(cl.x, cl.y - 6)); hands.move(to: cl); hands.addLine(to: p.pt(cl.x + 4, cl.y + 1))
                p.c.stroke(hands, with: .color(p.hex("#1a1a1e")), lineWidth: 1.5)
            }
        }
        // v125.5: the canopy is drawn after the whole train (in front of its front end), so the train passes under it
        add(-10.4, 7.2, -7.2 + 6.6 + 0.15) { p in // the platform canopy and the name board
            for x in [-13.4, -11.4, -9.4] { let q = p.iso(x, 7.35); p.rect(q.x - 2, q.y - 56, 4, 56, p.hex("#2a5a3a")) }
            let r = [p.iso(-13.9, 6.85), p.iso(-8.9, 6.85), p.iso(-8.9, 7.55), p.iso(-13.9, 7.55)].map { p.upp($0, 56) }
            p.poly(r, p.hex("#f2ead6")); p.poly([r[3], r[2], p.upp(r[2], -6), p.upp(r[3], -6)], p.hex("#2a5a3a"))
            let q = p.iso(-14.1, 7.3)
            p.rect(q.x - 30, q.y - 44, 2, 44, p.hex("#2a5a3a")); p.rect(q.x + 28, q.y - 44, 2, 44, p.hex("#2a5a3a"))
            let box = Path(roundedRect: CGRect(x: q.x - 34, y: q.y - 60, width: 68, height: 18), cornerRadius: 3)
            p.c.fill(box, with: .color(p.hex("#f6f2e4"))); p.c.stroke(box, with: .color(p.hex("#2a5a3a")), lineWidth: 2)
            p.sign("AVONSIDE", q.x, q.y - 51, size: 12, color: p.hex("#2a2a2e"))
        }
        add(-6.7, 6.25, nil) { p in // the buffer stop
            let q = p.iso(-6.7, 6.25)
            p.rect(q.x - 14, q.y - 18, 28, 8, p.hex("#c0392b"))
            p.rect(q.x - 10, q.y - 17, 6, 6, p.hex("#f6f2e4")); p.rect(q.x + 4, q.y - 17, 6, 6, p.hex("#f6f2e4"))
            p.rect(q.x - 12, q.y - 10, 3, 10, p.hex("#3a3a40")); p.rect(q.x + 9, q.y - 10, 3, 10, p.hex("#3a3a40"))
        }
        for x in [-14.2, -7.6] {
            add(x, 7.5, nil) { p in let q = p.iso(x, 7.5); p.rect(q.x - 1.5, q.y - 44, 3, 44, p.hex("#2a2a2e")); p.ellipse(q.x, q.y - 46, 5, 6, p.hex("#ffe2a0")) }
        }
        for (x, y) in [(-15.5, 3.6), (-9.0, 3.8), (-17, 5.2), (-12.4, 9.9), (-9.4, 10.2)] {
            add(x, y, nil) { p in let q = p.iso(x, y); p.oakTree(q.x, q.y, 0.9) }
        }
        add(-10.8, 9.9, nil) { p in let q = p.iso(-10.8, 9.9); p.hedge(q.x, q.y, 60) }
        let T = t
        if let v = ContractGeo.vehicles(s, T).first {
            var dx = 0.0, moving = false, al = 1.0
            if let t0 = v.t0 { let k = ContractGeo.clamp01((T - t0) / 4.6); dx = -14 * (1 - (1 - pow(1 - k, 3))); moving = k < 1 }
            if let t1 = v.t1 { // pulls out, back the way it came
                let e = ContractGeo.clamp01((T - t1 - 0.6) / 5)
                dx = -18 * e * e
                moving = true
                al = 1 - ContractGeo.clamp01((e - 0.75) / 0.25)
            }
            let x0 = -19.4 + dx, mv = moving, a = al
            add(x0 + 6, 6.3, x0 + 11.8 + 6.6) { p in
                let keep = p.c
                p.c.opacity *= a
                p.steamTrain(x0, 5.95, "#a8232c", moving: mv)
                p.c = keep
            }
        }
    }

    // MARK: v126 Cappadocia: NAV · Nevşehir Airport and the charter plane

    /// East of town on the east road: the runway runs along gx (gy ≈ 1), two taxiways lead to the apron, where the plane
    /// stands nose west; the terminal and the control tower stand by the road; a fenced dirt stand in front of the apron
    /// is where the jeeps wait. All of it lies at gx − gy ≥ 18, off every default view (`AIR`, `airGround`, `airItems`).
    private mutating func airGround() {
        let A = AirGeo.self, x0 = A.rwy.0, x1 = A.rwy.1
        quad(23.8, 2.3, 32.4, 5.55, "#bdb8ac") // the apron, concrete slabs
        var slabs = Path()
        var x = 24.6
        while x < 32.4 { slabs.move(to: iso(x, 2.3)); slabs.addLine(to: iso(x, 5.55)); x += 0.8 }
        var y = 3.1
        while y < 5.55 { slabs.move(to: iso(23.8, y)); slabs.addLine(to: iso(32.4, y)); y += 0.8 }
        c.stroke(slabs, with: .color(rgba(120, 112, 100, 0.35)), lineWidth: 1.2)
        quad(A.inX - 0.4, 1.6, A.inX + 0.4, 2.35, "#6a6870"); quad(A.outX - 0.4, 1.6, A.outX + 0.4, 2.35, "#6a6870") // taxiways
        quad(x0, 0.25, x1, 1.75, "#5c5a62"); quad(x0, 0.32, x1, 0.38, "#f2efe6"); quad(x0, 1.62, x1, 1.68, "#f2efe6") // the runway
        x = x0 + 2.2
        var marks = Path()
        while x < x1 - 2 { marks.addLines(q(x, 0.97, x + 0.5, 1.03)); marks.closeSubpath(); x += 1 }
        for xe in [x0 + 0.2, x1 - 0.9] {
            var yy = 0.45
            while yy < 1.55 { marks.addLines(q(xe, yy, xe + 0.7, yy + 0.08)); marks.closeSubpath(); yy += 0.17 }
        }
        c.fill(marks, with: .color(hex("#f2efe6")))
        for (gx, txt, r) in [(x0 + 1.4, "27", 1.0), (x1 - 1.4, "09", -1.0)] {
            let p = iso(gx, 1)
            var g = c
            g.translateBy(x: p.x, y: p.y)
            g.concatenate(CGAffineTransform(a: 1, b: 0.5, c: -1, d: 0.5, tx: 0, ty: 0))
            g.rotate(by: .radians(r * .pi / 2))
            g.draw(Text(txt).font(.custom("BarlowCondensed-ExtraBold", fixedSize: 30)).foregroundColor(rgba(242, 239, 230, 0.9)), at: pt(0, 0), anchor: .center)
        }
        // yellow taxi lines: runway exit, the stand's lead-in line, the way out
        func yl(_ pts: [(Double, Double)]) {
            var l = Path()
            l.move(to: iso(pts[0].0, pts[0].1))
            for g in pts.dropFirst() { l.addLine(to: iso(g.0, g.1)) }
            c.stroke(l, with: .color(hex("#f0c83a")), lineWidth: 2.4)
        }
        let (sx, sy) = A.stand
        yl([(A.inX, 1.1), (A.inX, sy), (sx - 1.8, sy)]); yl([(sx - 1.8, sy), (A.outX, sy), (A.outX, 1.1)])
        quad(sx + 1.1, sy - 0.5, sx + 1.18, sy + 0.5, "#f0c83a") // the stop bar
        quad(sx - 1.95, sy - 0.45, sx - 1.87, sy + 0.45, "#e8e4da")
        // landside: the jeep stand (packed dirt off the road) and the drop-off in front of the terminal
        quad(24.8, 5.85, 29.9, 7.65, "#c9986a")
        var R = rng(31)
        var specks = Path()
        for _ in 0..<46 { let p = iso(24.9 + R.next() * 4.9, 5.9 + R.next() * 1.7); specks.addRect(CGRect(x: p.x, y: p.y, width: 4, height: 2)) }
        c.fill(specks, with: .color(rgba(90, 60, 40, 0.28)))
        quad(29.9, 7.08, 34.4, 7.65, "#8a8690"); quad(29.9, 7.08, 34.4, 7.14, "#e8e4da")
    }

    private func airItems(_ add: (Double, Double, Double?, @escaping (inout TownPainter) -> Void) -> Void) {
        add(32, 6.3, 30.2 + 3.6 + 5.6 + 1.45 - 0.4) { p in // the terminal: tuff walls, a glass front, the name board
            p.smooth { p in
                let hh: CGFloat = 34
                let f = p.block(30.2, 5.6, 3.6, 1.45, hh, lit: "#f0d8b4", shade: "#d0b08a", top: "#e4cca8", courses: false)
                var a = p.face(f.D, f.C, hh)
                func r(_ g: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: Color) { g.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(col)) }
                r(&a, 0.06, 0.08, 0.88, 0.66, p.hex("#5e8ea8"))
                for i in 0..<9 { r(&a, 0.08 + CGFloat(i) * 0.1, 0.5, 0.03, 0.2, Color.white.opacity(0.22)) }
                for i in 1..<9 { r(&a, 0.06 + CGFloat(i) * 0.098, 0.08, 0.012, 0.66, p.hex("#f0d8b4")) }
                r(&a, 0.17, 0.08, 0.14, 0.46, p.hex("#2a3a4a")); r(&a, 0, 0.8, 1, 0.06, p.hex("#c0392b"))
                var b = p.face(f.C, f.B, hh)
                r(&b, 0.15, 0.3, 0.7, 0.4, p.hex("#5e8ea8")); r(&b, 0, 0.8, 1, 0.06, p.hex("#c0392b"))
                let s0 = p.upp(p.lp(f.D, f.C, 0.12), hh), s1 = p.upp(p.lp(f.D, f.C, 0.88), hh)
                p.rect(s0.x - 1, s0.y - 14, 2, 14, p.hex("#5a5a60")); p.rect(s1.x - 1, s1.y - 14, 2, 14, p.hex("#5a5a60"))
                var sg = p.face(p.upp(s0, 12), p.upp(s1, 12), 24)
                r(&sg, 0, 0, 1, 1, p.hex("#1f4a6a")); r(&sg, 0, 0, 1, 0.1, p.hex("#ffc23d"))
                let m = p.lp(p.upp(s0, 24), p.upp(s1, 24), 0.5), ang = atan2(s1.y - s0.y, s1.x - s0.x)
                p.sign("NAV · Nevşehir Airport", m.x, m.y, size: 15, color: .white, angle: ang)
            }
        }
        add(35.4, 5, 35.0 + 0.7 + 4.6 + 0.7 - 0.3) { p in // the control tower
            p.smooth { p in
                let sh = p.block(35.15, 4.75, 0.4, 0.4, 112, lit: "#ecd2ac", shade: "#c8a882", top: "#d8bc94", courses: false)
                var a = p.face(sh.D, sh.C, 112)
                for i in 0..<5 { a.fill(Path(CGRect(x: 0.35, y: 0.12 + CGFloat(i) * 0.16, width: 0.3, height: 0.05)), with: .color(p.hex("#3a4a5a"))) }
                let keep = p.c
                p.c.translateBy(x: 0, y: -112)
                let cab = p.block(34.8, 4.4, 1.1, 1.1, 22, lit: "#7ab0c8", shade: "#5a8aa4", top: "#3a4a5a", courses: false)
                var cf = p.face(cab.D, cab.C, 22)
                for i in 0..<4 { cf.fill(Path(CGRect(x: 0.05 + CGFloat(i) * 0.25, y: 0.2, width: 0.03, height: 0.7)), with: .color(Color.white.opacity(0.3))) }
                cf.fill(Path(CGRect(x: 0, y: 0, width: 1, height: 0.14)), with: .color(p.hex("#e8e4da")))
                var cb = p.face(cab.C, cab.B, 22)
                cb.fill(Path(CGRect(x: 0, y: 0, width: 1, height: 0.14)), with: .color(p.hex("#e8e4da")))
                let r = [p.iso(34.74, 4.34), p.iso(35.96, 4.34), p.iso(35.96, 5.56), p.iso(34.74, 5.56)].map { p.upp($0, 24) }
                p.poly([r[3], r[2], p.upp(r[2], -3), p.upp(r[3], -3)], p.hex("#6a7480")); p.poly(r, p.hex("#8a949e"))
                let an = p.upp(p.iso(35.35, 4.95), 26)
                p.rect(an.x - 1, an.y - 22, 2, 22, p.hex("#5a5a60"))
                p.ellipse(an.x, an.y - 24, 3, 3, p.hex(p.night != nil || p.t.truncatingRemainder(dividingBy: 1.4) < 0.7 ? "#ff4a3a" : "#7a2a24"))
                p.c = keep
            }
        }
        add(22.6, 2.6, nil) { p in // the windsock by the runway, swinging with the wind
            let q = p.iso(22.6, 2.6)
            p.rect(q.x - 1.5, q.y - 58, 3, 58, p.hex("#8a8a90"))
            let sway = CGFloat(sin(p.t * 2.3)) * 3, dx: CGFloat = 30, k = 0.85 + 0.15 * CGFloat(sin(p.t * 3.1))
            for i in 0..<5 {
                let fi = CGFloat(i)
                let x0 = q.x + fi * dx * k / 5, x1 = q.x + (fi + 1) * dx * k / 5, r0 = 6 - fi * 0.8, r1 = 6 - (fi + 1) * 0.8
                let y0 = q.y - 56 + fi * (1 + sway * 0.2), y1 = q.y - 56 + (fi + 1) * (1 + sway * 0.2)
                p.poly([p.pt(x0, y0 - r0), p.pt(x1, y1 - r1), p.pt(x1, y1 + r1), p.pt(x0, y0 + r0)], p.hex(i % 2 == 1 ? "#f6f2ea" : "#ff6a2a"))
            }
        }
        add(27, 5.7, 23.8 + 5.7 + 4.5) { p in // the fence between the apron and the jeep stand
            var x = 23.8
            while x <= 30.1 { let q = p.iso(x, 5.7); p.rect(q.x - 1, q.y - 16, 2, 16, p.hex("#6a6a72")); x += 0.45 }
            let a = p.iso(23.8, 5.7), b = p.iso(30.1, 5.7)
            var w = Path()
            w.move(to: p.pt(a.x, a.y - 15)); w.addLine(to: p.pt(b.x, b.y - 15))
            w.move(to: p.pt(a.x, a.y - 7)); w.addLine(to: p.pt(b.x, b.y - 7))
            p.c.stroke(w, with: .color(p.rgba(90, 90, 100, 0.65)), lineWidth: 1.2)
        }
        add(29.6, 6.2, nil) { p in // the jeep stand's sign (translated: `sign.shuttle`, two lines)
            let q = p.iso(29.6, 6.2)
            p.rect(q.x - 2, q.y - 46, 4, 46, p.hex("#6a4a2a"))
            let box = Path(roundedRect: CGRect(x: q.x - 30, y: q.y - 66, width: 60, height: 24), cornerRadius: 5)
            p.c.fill(box, with: .color(p.hex("#fff1d6"))); p.c.stroke(box, with: .color(p.hex("#c0392b")), lineWidth: 2)
            let lines = loc("sign.shuttle").components(separatedBy: "\n")
            for (i, l) in lines.prefix(2).enumerated() {
                let y = lines.count > 1 ? q.y - 59 + CGFloat(i) * 10 : q.y - 54
                p.c.draw(Text(l).font(.custom("BarlowCondensed-ExtraBold", fixedSize: 11)).foregroundColor(p.hex("#2b2350")), at: p.pt(q.x, y), anchor: .center)
            }
        }
        add(23.6, 7.3, nil) { p in // the way sign at the road: "NAV", a small plane and an arrow drawn in code
            let q = p.iso(23.6, 7.3)
            p.rect(q.x - 1.5, q.y - 50, 3, 50, p.hex("#5a5a60"))
            p.c.fill(Path(roundedRect: CGRect(x: q.x - 34, y: q.y - 68, width: 68, height: 22), cornerRadius: 4), with: .color(p.hex("#1f4a6a")))
            p.sign("NAV", q.x + 2, q.y - 57, size: 13, color: .white)
            var plane = Path()
            plane.move(to: p.pt(7, 0)); plane.addLine(to: p.pt(-6, -1.3)); plane.addLine(to: p.pt(-6, 1.3)); plane.closeSubpath()
            plane.move(to: p.pt(1.5, 0)); plane.addLine(to: p.pt(-2, -6.5)); plane.addLine(to: p.pt(-3.6, -6.5)); plane.addLine(to: p.pt(-2, 0))
            plane.addLine(to: p.pt(-3.6, 6.5)); plane.addLine(to: p.pt(-2, 6.5)); plane.closeSubpath()
            plane.move(to: p.pt(-5, 0)); plane.addLine(to: p.pt(-7, -3)); plane.addLine(to: p.pt(-7.8, -3)); plane.addLine(to: p.pt(-7.2, 0))
            plane.addLine(to: p.pt(-7.8, 3)); plane.addLine(to: p.pt(-7, 3)); plane.closeSubpath()
            var g = p.c
            g.translateBy(x: q.x - 20, y: q.y - 57)
            g.rotate(by: .radians(-0.5))
            g.fill(plane, with: .color(.white))
            var arrow = Path()
            arrow.move(to: p.pt(q.x + 16, q.y - 57)); arrow.addLine(to: p.pt(q.x + 26, q.y - 57))
            arrow.move(to: p.pt(q.x + 22, q.y - 61)); arrow.addLine(to: p.pt(q.x + 26, q.y - 57)); arrow.addLine(to: p.pt(q.x + 22, q.y - 53))
            p.c.stroke(arrow, with: .color(.white), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        for (gx, gy, k) in [(21.4, 4.2, 0), (22.4, 5.8, 1), (33.6, 2.2, 1), (37.6, 3.4, 0), (38.6, 6.2, 1), (21.2, 6.6, 1), (36.8, 7.1, 1)] {
            add(gx, gy, nil) { p in // fairy chimneys and poplars round the field
                let q = p.iso(gx, gy)
                if k == 1 { p.roundTree(q.x, q.y, 0.55, "#7a8a50") } else {
                    ScenePainter.chimney(&p.c, q.x, q.y, 50, 120, body: Color(hex: "#efc79e"), shade: Color(hex: "#c69068"), cap: Color(hex: "#6a4430"))
                }
            }
        }
        // the plane: landing, parked, or leaving
        let T = t, vs = ContractGeo.vehicles(s, T)
        if let v = vs.first {
            let leaving = v.t1 != nil, u: Double? = leaving ? T - v.t1! : v.t0.map { T - $0 }
            if leaving || u == nil || u! >= 0 {
                let pose = AirGeo.planePose(u, leaving: leaving)
                let al = leaving ? 1 - ContractGeo.clamp01(((u ?? 0) - 11.5) / 2) : ContractGeo.clamp01((u ?? 9) / 0.8)
                let parked = u == nil || (!leaving && u! > 13), col = v.color
                add(pose.gx, pose.gy, pose.gx + pose.gy + 1.2 + Double(pose.alt) / 60) { p in
                    let keep = p.c
                    p.c.opacity *= al
                    p.charterPlane(pose.gx, pose.gy, pose.hd, pose.alt, col, prop: parked ? 0 : pose.prop, stairs: parked)
                    p.c = keep
                }
            }
        }
        // passengers from the plane's stairs into the terminal while a group is here
        if ContractGeo.jeepsOn(s) && vs.contains(where: { $0.t0 == nil && $0.t1 == nil }) {
            let cols = ["#ff5e3a", "#14a39a", "#ffc23d", "#9b7be0", "#5aa9e6", "#ff6fa8"], path = [(26.45, 4.6), (26.45, 5.2), (30.6, 5.2), (30.6, 5.55)]
            let L = CoachPath.len(path)
            for i in 0..<6 {
                let k = (T * 0.12 + Double(i) / 6).truncatingRemainder(dividingBy: 1), pos = CollectScene.walk(path, k * L).p
                add(pos.0, pos.1, nil) { p in let q = p.iso(pos.0, pos.1); p.person(q.x, q.y, cols[i], p.t, Double(i)) }
            }
        }
    }

    /// A twin-turboprop in the game's style (`charterPlane`): white tube with the agency's cheatline and tail, high wing,
    /// two engines with propellers, T-tail, gear. `hd`: heading in grid space (0 = +gx); `alt`: height in px; `prop`:
    /// 0 still … 1 a spinning disc. Local coordinates: a along the nose (tiles), b to the side (tiles), z up (px).
    mutating func charterPlane(_ gx: Double, _ gy: Double, _ hd: Double, _ alt: CGFloat, _ col: String, prop: Double, stairs: Bool) {
        let fx = cos(hd), fy = sin(hd), rx = -fy, ry = fx, Z0 = 16 + alt
        func G(_ a: Double, _ b: Double) -> CGPoint { iso(gx + a * fx + b * rx, gy + a * fy + b * ry) }
        func P(_ a: Double, _ b: Double, _ z: CGFloat) -> CGPoint { upp(G(a, b), z + Z0) }
        // the shadow on the ground: smaller and fainter with height
        do {
            let k = min(max(1 - alt / 320, 0.15), 1)
            let sh: [(Double, Double)] = [(1.5, 0), (0.3, 0.2), (0.15, 1.55), (-0.15, 1.55), (-0.3, 0.2), (-1.4, 0.12), (-1.55, 0.5), (-1.62, 0.5), (-1.55, 0),
                                          (-1.62, -0.5), (-1.55, -0.5), (-1.4, -0.12), (-0.3, -0.2), (-0.15, -1.55), (0.15, -1.55), (0.3, -0.2)]
            poly(sh.map { let p = G($0.0, $0.1); return pt(p.x + alt * 0.25, p.y + alt * 0.1) }, hex("#3a2a1a").opacity(Double(0.2 * k)))
        }
        if alt < 60 { // the gear
            for (a, b) in [(1.0, 0.0), (-0.1, 0.3), (-0.1, -0.3)] {
                let top = P(a, b, -2), bot = P(a, b, -16)
                line(top, bot, hex("#4a4a50"), 2)
                ellipse(bot.x, bot.y + 1, 4, 4, hex("#1f1c22"))
            }
        }
        // the fuselage: sections from tail to nose, outline offset across the screen direction
        let sec: [(Double, CGFloat, CGFloat)] = [(-1.62, 3, 13), (-1.3, 7, 8), (-0.9, 10.5, 3), (-0.4, 12, 0), (0.6, 12, 0), (1.1, 11, 0), (1.38, 8, -1), (1.52, 4, -3)]
        let cs = sec.map { (c: P($0.0, 0, $0.2), R: $0.1) }
        func nrm(_ i: Int) -> CGPoint {
            let p = cs[max(0, i - 1)].c, q = cs[min(cs.count - 1, i + 1)].c
            var dx = q.x - p.x, dy = q.y - p.y
            let l = max(hypot(dx, dy), 1e-9)
            dx /= l; dy /= l
            var nx = -dy, ny = dx
            if ny > 0 { nx = -nx; ny = -ny }
            return pt(nx, ny)
        }
        func edge(_ k: CGFloat) -> [CGPoint] {
            cs.indices.map { i in let n = nrm(i), r = cs[i].R * (1 + abs(n.x) * 0.25); return pt(cs[i].c.x + n.x * r * k, cs[i].c.y + n.y * r * k) }
        }
        func band(_ k0: CGFloat, _ k1: CGFloat, _ c: Color) { poly(edge(k0) + edge(k1).reversed(), c) }
        poly(edge(1) + edge(-1).reversed(), hex("#f6f5f0"))
        band(-0.15, -1, hex("#dcdad2")); band(0.95, 0.55, .white)
        band(0.05, -0.22, hex(col)); band(-0.22, -0.32, mix(col, "#000000", 0.3))
        var a = -1.05
        while a <= 0.95 { let p = P(a, 0, 4); ellipse(p.x, p.y, 2.1, 2.4, hex("#2a3a50")); a += 0.17 } // the windows
        do { let p = P(1.3, 0, 5), q = P(1.42, 0, 3); poly([pt(p.x, p.y - 3), pt(q.x, q.y - 2), pt(q.x, q.y + 2), pt(p.x, p.y + 3)], hex("#1e2a3c")) } // cockpit
        do { let p = P(0.92, 0, -2); rect(p.x - 1, p.y - 9, 2, 12, hex("#c8c8c4")) } // the front door's outline
        for b in [-0.62, 0.62] { // the engines
            var n1 = Path(); n1.move(to: P(-0.15, b, 6)); n1.addLine(to: P(0.5, b, 4))
            c.stroke(n1, with: .color(hex("#e4e4e0")), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            var n2 = Path(); n2.move(to: P(-0.1, b, 1)); n2.addLine(to: P(0.45, b, 0))
            c.stroke(n2, with: .color(hex("#bcbcb8")), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
        // the high wing
        let wing = [(0.28, 0.15), (0.14, 1.6), (-0.06, 1.6), (-0.2, 0.15), (-0.2, -0.15), (-0.06, -1.6), (0.14, -1.6), (0.28, -0.15)].map { P($0.0, $0.1, 11) }
        poly(wing.map { pt($0.x, $0.y + 3) }, hex("#bdbbb4")); poly(wing, hex("#f2f1ec")); outline(wing, hex("#c8c6c0"), 1)
        var tips = Path()
        tips.move(to: P(-0.06, 1.6, 11)); tips.addLine(to: P(0.14, 1.6, 11)); tips.move(to: P(-0.06, -1.6, 11)); tips.addLine(to: P(0.14, -1.6, 11))
        c.stroke(tips, with: .color(hex(col)), lineWidth: 3)
        // propellers: a blurred disc when turning fast, blades when slow
        for b in [-0.62, 0.62] {
            let ctr = P(0.53, b, 4)
            func ring(_ th: Double) -> CGPoint { P(0.54, b + 0.2 * cos(th), 4 + 13 * CGFloat(sin(th))) }
            if prop > 0.5 { poly((0..<18).map { ring(Double($0) / 18 * .pi * 2) }, hex("#6a6a74").opacity(0.3 * prop)) }
            if prop < 0.9 {
                let ang = t * prop * 30 + b * 2
                var bl = Path()
                for k in 0..<3 { bl.move(to: ctr); bl.addLine(to: ring(ang + Double(k) * .pi * 2 / 3)) }
                c.stroke(bl, with: .color(hex("#5a5a64")), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            ellipse(ctr.x, ctr.y, 3, 3, hex(col))
        }
        // the fin and the T-tail in the agency's colour
        poly([P(-1.0, 0, 10), P(-1.42, 0, 46), P(-1.62, 0, 46), P(-1.6, 0, 14)], hex(col))
        poly([P(-1.36, 0, 38), P(-1.42, 0, 46), P(-1.62, 0, 46), P(-1.6, 0, 38)], mix(col, "#ffffff", 0.35))
        poly([P(-1.38, 0.62, 46), P(-1.38, -0.62, 46), P(-1.62, -0.62, 47), P(-1.62, 0.62, 47)], hex("#f0efea"))
        if stairs { // boarding stairs at the rear door when parked
            let d = P(-0.95, -0.32, -2), g = G(-0.95, -0.75)
            poly([pt(d.x - 3, d.y), pt(d.x + 3, d.y), pt(g.x + 5, g.y), pt(g.x - 5, g.y)], hex("#d8d4c8"))
            var st = Path()
            for k in 1..<5 { let p = lp(d, g, CGFloat(k) / 5); st.move(to: pt(p.x - 4, p.y)); st.addLine(to: pt(p.x + 4, p.y)) }
            c.stroke(st, with: .color(hex("#8a8a90")), lineWidth: 1)
        }
        if (t * 1.2).truncatingRemainder(dividingBy: 1) < 0.12 { let p = P(-0.2, 0, 13); ellipse(p.x, p.y - 12, 3, 3, hex("#ff3a2a")) } // beacon
    }

    // MARK: The jeeps

    /// Passengers walk from the vehicle to three jeeps, the jeeps drive off along the dirt road and fade out well before
    /// the default view; an 11-second loop while the morning lasts (`ctrXferItems`).
    private func jeepItems(_ add: (Double, Double, Double?, @escaping (inout TownPainter) -> Void) -> Void, _ kind: ContractKind) {
        let P = 11.0, ph = t.truncatingRemainder(dividingBy: P), tt = t
        let cols = ["#ff5e3a", "#14a39a", "#ffc23d", "#9b7be0", "#5aa9e6", "#ff6fa8", "#2b2350"]
        let bays = ContractGeo.bays
        let stops: [(Double, Double)]
        let doors: (Int) -> (Double, Double)
        let via: ((Double, Double)) -> [(Double, Double)]
        let road: ((Double, Double)) -> [(Double, Double)]
        switch kind {
        case .bus:
            stops = [(9.3, 19.7), (10.25, 19.7), (11.2, 19.7)]
            doors = { i in (bays[bays.count - 1 - (i % 3)] + 0.3, ContractGeo.bayGY + 0.2) }
            via = { d in [(d.0, 20.8)] }
            road = { s in [s, (8, s.1), (8, 11.6)] }
        case .ship:
            stops = [(29, -9.2), (29.8, -9.2), (31.8, -9.2)]
            doors = { _ in (31, -12.1) }
            via = { _ in [(31, -10.8), (31, -9.8)] }
            road = { s in [s, (30.6, s.1), (30.6, 8), (24.2, 8)] }
        case .train:
            stops = [(-10.6, 9.1), (-9.6, 9.1), (-8.6, 9.1)]
            doors = { i in (-15.6 + Double(i % 3) * 2.2, 6.75) }
            via = { d in [(d.0, 7.3), (d.0 + 0.3, 8)] }
            road = { s in [s, (s.0, 8), (-5.6, 8)] }
        case .plane: // from the terminal's front door to the dirt stand, then the east road
            stops = [(25.7, 6.55), (26.7, 6.55), (27.7, 6.55)]
            doors = { i in (30.75 + Double(i % 2) * 0.5, 7.1) }
            via = { d in [(d.0, 7.35), (28.6, 7.35)] }
            road = { s in [s, (s.0, 8), (23, 8)] }
        }
        func length(_ pts: [(Double, Double)]) -> Double { zip(pts, pts.dropFirst()).reduce(0) { $0 + hypot($1.1.0 - $1.0.0, $1.1.1 - $1.0.1) } }
        var boarded = [0, 0, 0]
        for i in 0..<12 {
            let j = i % 3, s0 = 0.25 * Double(i), d = doors(i)
            let path = [d] + via(d) + [(stops[j].0, stops[j].1 + 0.3)]
            let k = (ph - s0) / 2.4
            if k >= 1 { boarded[j] += 1; continue }
            if k < 0 { continue }
            let pos = CollectScene.walk(path, k * length(path)).p
            add(pos.0, pos.1, nil) { p in let q = p.iso(pos.0, pos.1); p.person(q.x, q.y, cols[i % 7], tt, Double(i)) }
        }
        for j in 0..<3 {
            let path = road(stops[j]), len = length(path)
            let lv = 4.4 + Double(j) * 0.7, dist = ph > lv ? pow(ph - lv, 1.35) * 2.4 : 0
            if dist >= len { continue }
            // v126.1: waiting at the stop it already faces the way it will drive off
            let r = CollectScene.walk(path, dist), pos = r.p, alongX = abs(r.dir.0) > abs(r.dir.1)
            let a = min(ContractGeo.clamp01(ph / 0.5), ContractGeo.clamp01((len - dist) / 1.6)), n = min(CollectScene.jeepSeats, boarded[j])
            add(pos.0, pos.1, pos.0 + pos.1 + 0.3) { p in
                let keep = p.c
                p.c.opacity *= a
                p.jeep(pos.0, pos.1, alongX, tt, n)
                p.c = keep
            }
        }
    }

    func hexMix(_ a: String, _ b: String, _ k: Double) -> String {
        func comps(_ h: String) -> [Double] {
            let s = h.dropFirst()
            return stride(from: 0, to: 6, by: 2).map { i in
                Double(Int(s[s.index(s.startIndex, offsetBy: i)..<s.index(s.startIndex, offsetBy: i + 2)], radix: 16) ?? 0)
            }
        }
        let x = comps(a), y = comps(b)
        return "#" + (0..<3).map { String(format: "%02x", Int((x[$0] + (y[$0] - x[$0]) * k).rounded())) }.joined()
    }
}

private func lerpD(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }

/// v126: the airport's layout (`AIR`): the runway's ends and line, the stand, the taxiways in and out.
enum AirGeo {
    static let rwy = (20.6, 46.0), rwyY = 1.0, stand = (27.4, 3.8), inX = 31.0, outX = 24.6

    static func ease3(_ k: Double) -> Double { 1 - pow(1 - ContractGeo.clamp01(k), 3) }

    /// A point along the path and the heading 0.45 tiles further on (`pathAt`).
    static func pathAt(_ pts: [(Double, Double)], _ s: Double) -> (p: (Double, Double), hd: Double) {
        let r = CollectScene.walk(pts, s), r2 = CollectScene.walk(pts, s + 0.45)
        let dx = r2.p.0 - r.p.0, dy = r2.p.1 - r.p.1
        return (r.p, hypot(dx, dy) > 1e-3 ? atan2(dy, dx) : atan2(r.dir.1, r.dir.0))
    }

    /// Where the plane is (`planePose`): parked (u nil), or landing (13.5 s: gliding in from the east from 300 px,
    /// touchdown at gx 40, slowing to gx 31, the taxiway to the stand) or taking off (14 s: west along the apron, the
    /// gx 24.6 taxiway onto the runway, the take-off run east, airborne at gx 38, climbing away).
    static func planePose(_ u: Double?, leaving: Bool) -> (gx: Double, gy: Double, hd: Double, alt: CGFloat, prop: Double) {
        let (sx, sy) = stand, y = rwyY
        guard let u else { return (sx, sy, .pi, 0, 0) }
        if !leaving {
            if u < 4.5 { let k = u / 4.5; return (lerpD(62, 40, k), y, .pi, CGFloat(300 * pow(1 - k, 1.25)), 1) }
            if u < 8.5 { let k = ease3((u - 4.5) / 4); return (lerpD(40, inX, k), y, .pi, 0, 1) }
            let pts = [(inX, y), (inX, sy), (sx, sy)], L = CoachPath.len(pts), k = CollectScene.easeIO(ContractGeo.clamp01((u - 8.5) / 4.5)), r = pathAt(pts, k * L)
            return (r.p.0, r.p.1, k >= 0.999 ? .pi : r.hd, 0, 1 - ContractGeo.clamp01((u - 12) / 1.5) * 0.8)
        }
        if u < 4.5 {
            let pts = [(sx, sy), (outX, sy), (outX, y), (outX + 1.4, y)], L = CoachPath.len(pts), k = CollectScene.easeIO(ContractGeo.clamp01(u / 4.5)), r = pathAt(pts, k * L)
            return (r.p.0, r.p.1, k >= 0.999 ? 0 : r.hd, 0, 0.7 + 0.3 * ContractGeo.clamp01(u))
        }
        if u < 9 { let k = pow((u - 4.5) / 4.5, 2); return (lerpD(outX + 1.4, 38, k), y, 0, 0, 1) }
        let k = ContractGeo.clamp01((u - 9) / 4.5)
        return (lerpD(38, 62, k), y, 0, CGFloat(300 * pow(k, 1.3)), 1)
    }
}

/// v126.1: the coaches drive like buses (`smoothPath`, `pathPt`, `coachInPath`, `coachOutPath`, `coachPose`). A path is
/// a polyline smoothed into curves (Chaikin); the bus's front bumper runs along it and its body trails along the same
/// path, so the heading follows the way it drives.
enum CoachPath {
    static let length = 1.6

    static func smooth(_ p0: [(Double, Double)], _ n: Int = 4) -> [(Double, Double)] {
        var pts = p0
        for _ in 0..<n {
            var o = [pts[0]]
            for i in 0..<(pts.count - 1) {
                let p = pts[i], q = pts[i + 1]
                o.append((p.0 * 0.75 + q.0 * 0.25, p.1 * 0.75 + q.1 * 0.25))
                o.append((p.0 * 0.25 + q.0 * 0.75, p.1 * 0.25 + q.1 * 0.75))
            }
            o.append(pts[pts.count - 1])
            pts = o
        }
        return pts
    }

    /// A point s along the path; before its start it carries on straight back along the first stretch, past its end
    /// along the last.
    static func point(_ pts: [(Double, Double)], _ s0: Double) -> (Double, Double) {
        var s = s0
        if s <= 0 {
            let a = pts[0], b = pts[1], l = max(hypot(b.0 - a.0, b.1 - a.1), 1e-9)
            return (a.0 + (b.0 - a.0) / l * s, a.1 + (b.1 - a.1) / l * s)
        }
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i], l = hypot(b.0 - a.0, b.1 - a.1)
            if s <= l { let k = s / max(l, 1e-9); return (a.0 + (b.0 - a.0) * k, a.1 + (b.1 - a.1) * k) }
            s -= l
        }
        let a = pts[pts.count - 2], b = pts[pts.count - 1], l = max(hypot(b.0 - a.0, b.1 - a.1), 1e-9)
        return (b.0 + (b.0 - a.0) / l * s, b.1 + (b.1 - a.1) / l * s)
    }

    static func len(_ pts: [(Double, Double)]) -> Double { zip(pts, pts.dropFirst()).reduce(0) { $0 + hypot($1.1.0 - $1.0.0, $1.1.1 - $1.0.1) } }

    /// Bay bx: in from far down the highway (gx 8, coming up −gy), right into the aisle behind the bays (gy ≈ 25.6),
    /// left into the bay, stop with the nose at the bay line.
    static func inPath(_ bx: Double, _ i: Int) -> [(Double, Double)] {
        let by = ContractGeo.bayGY
        return smooth([(8, 46 + Double(i) * 2.4), (8, 27.6), (8, 26.5), (8.75, 25.65), (max(9.05, bx - 0.9), 25.65), (bx, 24.75), (bx, by + 0.6), (bx, by)])
    }

    /// Leaving: pull forwards out of the bay, left along the lot's far edge in front of the other coaches' noses
    /// (gy ≈ 21.3), left again onto the highway and away down it (+gy).
    static func outPath(_ bx: Double) -> [(Double, Double)] {
        smooth([(bx, ContractGeo.bayGY), (bx, 21.75), (max(8.95, bx - 0.5), 21.3), (8.75, 21.3), (8.1, 21.75), (8, 22.6), (8, 26), (8, 52)])
    }

    /// Where coach i is at time u: its front bumper and heading. In: 6 s, slowing down; out: 7 s, speeding up.
    static func pose(_ bx: Double, _ i: Int, _ u: Double, leaving: Bool) -> (p: (Double, Double), hd: Double) {
        func at(_ pts: [(Double, Double)], _ s: Double) -> (p: (Double, Double), hd: Double) {
            let f = point(pts, s), r = point(pts, s - length)
            return (f, atan2(f.1 - r.1, f.0 - r.0))
        }
        if !leaving {
            let P = inPath(bx, i), k = ContractGeo.clamp01(u / 6)
            return at(P, len(P) * (1 - pow(1 - k, 2.6)))
        }
        let O = outPath(bx), k = ContractGeo.clamp01(u / 7)
        return at(O, len(O) * 0.6 * k * k)
    }
}
