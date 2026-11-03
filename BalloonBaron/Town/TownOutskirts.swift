import SwiftUI
import BalloonBaronCore

// v135 / v135.1: the outskirts grow with the company (prototype `outLayout`, `outGround`, `outskirtsItems`,
// `outskirtsExtent`, `outBusy`, `OUT_DAWN`, `chaseVan`, `lyingEnvelope`, `dustPuffs`, `toaster`, `quadBike`, `rider`,
// `rvCaravan`, `dovecoteRock`, `farmHouse`, `mesaRock`, `viewKnoll`, `outTrackTree`). Only on the two flanks the home
// screen doesn't show (|gx − gy| ≥ `Outskirts.calm`): farm tracks meander out from the main roads, plots along them;
// the nearest become launch fields as the fleet grows, the rest carry each region's own land. The fields in use this
// morning lay out envelopes one at a time from dawn, inflate them and send them up; chase crews drive out to landings
// beside their track and toast. The layout (core `OutskirtsLayout`) and its ground are built once and cached; things off
// screen are skipped and at most `Outskirts.maxBalloons` balloons are drawn.

/// The outskirts' layouts and ground, built once (per region; the ground per field count, winter and Fiesta) in world
/// coordinates and only filled each frame. Main thread only, like the Canvas.
enum OutskirtsStatic {
    private static var layouts: [RegionID: OutskirtsLayout] = [:]
    private static var grounds: [String: OutskirtsGround] = [:]
    private static var busyMasks: [RegionID: [Int: Bool]] = [:]

    static func layout(_ r: RegionID) -> OutskirtsLayout {
        if let L = layouts[r] { return L }
        let place = ContractPlace.of(r)
        let L = OutskirtsLayout(region: r) { x, y in place?.isFree(x, y) ?? true }
        layouts[r] = L
        return L
    }

    static func ground(_ key: String, build: () -> OutskirtsGround) -> OutskirtsGround {
        if let g = grounds[key] { return g }
        if grounds.count > 16 { grounds = [:] }
        let g = build()
        grounds[key] = g
        return g
    }

    /// Whether an outer landmark (by its index) stands on ground the outskirts use.
    static func busy(_ r: RegionID, _ i: Int, _ gx: Double, _ gy: Double) -> Bool {
        if let b = busyMasks[r]?[i] { return b }
        let b = layout(r).busy(gx, gy)
        busyMasks[r, default: [:]][i] = b
        return b
    }
}

/// The outskirts' ground: one path per fill colour and per stroke style.
struct OutskirtsGround {
    var fills: [(Color, Path)] = []
    var strokes: [(Color, StrokeStyle, Path)] = []
}

/// A colour from "#rrggbb" or "rgba(r,g,b,a)".
private func outColor(_ s: String) -> Color {
    if s.hasPrefix("rgba(") {
        let v = s.dropFirst(5).dropLast().split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
        return Color(red: v[0] / 255, green: v[1] / 255, blue: v[2] / 255).opacity(v.count > 3 ? v[3] : 1)
    }
    return Color(hex: s)
}

private func gp(_ p: GridPoint) -> CGPoint { TownGeo.iso(p.x, p.y) }

extension TownPainter {
    var outskirts: OutskirtsLayout { OutskirtsStatic.layout(s.region) }
    /// Daytime out there: nobody flies at night.
    private var outDay: Bool { (night?.k ?? 0) <= 0 }
    private var dark: Bool { (night?.k ?? 0) > 0 }

    // MARK: Ground

    /// The ground of the outskirts (prototype `outskirtsGround`), drawn on the flat layer under everything.
    mutating func outskirtsGround() {
        let nf = s.outskirtsFields, winter = s.local.winter != nil, fiesta = s.local.fiesta != nil
        let key = "\(s.region.rawValue):\(nf):\(winter):\(fiesta)"
        let L = outskirts, reg = s.region, look = outerLook
        let g = OutskirtsStatic.ground(key) { Self.buildGround(L, reg, nf, winter, look) }
        for (col, p) in g.fills { c.fill(p, with: .color(col)) }
        for (col, st, p) in g.strokes { c.stroke(p, with: .color(col), style: st) }
    }

    private static func buildGround(_ L: OutskirtsLayout, _ reg: RegionID, _ nf: Int, _ winter: Bool, _ look: OuterLook) -> OutskirtsGround {
        var fills: [String: Path] = [:], fillOrder: [String] = []
        var strokes: [String: (String, CGFloat, [CGFloat], Path)] = [:], strokeOrder: [String] = []
        func win(_ c: String) -> String { winter && c.hasPrefix("#") ? hexMix(c, "#f4f6fa", 0.62) : c }
        func P(_ fill: String, _ add: (inout Path) -> Void) {
            let c = win(fill)
            if fills[c] == nil { fills[c] = Path(); fillOrder.append(c) }
            add(&fills[c]!)
        }
        func St(_ col: String, _ lw: CGFloat, _ dash: [CGFloat] = [], _ add: (inout Path) -> Void) {
            let c = win(col), k = "\(c)|\(lw)|\(dash)"
            if strokes[k] == nil { strokes[k] = (c, lw, dash, Path()); strokeOrder.append(k) }
            add(&strokes[k]!.3)
        }
        func poly(_ path: inout Path, _ pts: [GridPoint]) {
            for (i, p) in pts.enumerated() { if i == 0 { path.move(to: gp(p)) } else { path.addLine(to: gp(p)) } }
        }
        func line(_ path: inout Path, _ a: GridPoint, _ b: GridPoint) { path.move(to: gp(a)); path.addLine(to: gp(b)) }
        func lerp(_ p: CGPoint, _ q: CGPoint, _ k: CGFloat) -> CGPoint { CGPoint(x: p.x + (q.x - p.x) * k, y: p.y + (q.y - p.y) * k) }
        /// A plot's outline with its corners rounded off; k shrinks it toward its middle.
        func rpoly(_ path: inout Path, _ c: OutskirtsLayout.Site, _ k: Double = 1, _ rk: CGFloat = 0.24) {
            let pts = c.poly.map { TownGeo.iso(c.cx + ($0.x - c.cx) * k, c.cy + ($0.y - c.cy) * k) }, n = pts.count
            for i in 0..<n {
                let p = pts[i], a = lerp(p, pts[(i + n - 1) % n], rk), b = lerp(p, pts[(i + 1) % n], rk)
                if i == 0 { path.move(to: a) } else { path.addLine(to: a) }
                path.addQuadCurve(to: b, control: p)
            }
            path.closeSubpath()
        }
        func rows(_ path: inout Path, _ c: OutskirtsLayout.Site, _ n: Int, _ inset: Double = 0.14) {
            for r in 0..<n {
                let b = -c.d / 2 + inset + (Double(r) + 0.5) * (c.d - inset * 2) / Double(n)
                line(&path, c.at(-c.w / 2 + inset, b), c.at(c.w / 2 - inset, b))
            }
        }
        func blob(_ path: inout Path, _ p: GridPoint, _ rx: CGFloat, _ ry: CGFloat) {
            let q = gp(p); path.addEllipse(in: CGRect(x: q.x - rx, y: q.y - ry, width: rx * 2, height: ry * 2))
        }
        let bri = reg == .bri
        // the farm tracks: a dusty verge, the track, a strip of weeds between the wheel ruts; the loops a fainter path
        let tcol = bri ? "#b4b58e" : look.road
        for T in L.tracks {
            St(hexMix(tcol, bri ? "#8ab85a" : "#ffffff", 0.25), 24) { poly(&$0, T.P) }
            St(tcol, 14) { poly(&$0, T.P) }
            St(bri ? "rgba(110,150,70,.55)" : "rgba(150,140,90,.3)", 3) { poly(&$0, T.P) }
        }
        for l in L.loops { St(hexMix(tcol, bri ? "#8ab85a" : "#9a7a5a", bri ? 0.3 : 0.12), 7) { poly(&$0, l.P) } }
        // the launch fields: a mown meadow, each a slightly different green, mowing stripes, a worn patch in the middle
        let fieldCol = bri ? "#97c266" : reg == .lux ? "#a2bd68" : reg == .abq ? "#b4b673" : "#b2b671"
        for (i, c) in L.fields.enumerated() where i < nf {
            let fc = hexMix(fieldCol, look.road, [0, 0.14, 0.26][c.seed % 3])
            P(fc) { rpoly(&$0, c, 1, 0.32) }
            P(hexMix(fc, look.road, 0.45)) { rpoly(&$0, c, 0.5, 0.5) }
            St("rgba(255,250,225,.16)", 5) { rows(&$0, c, 3, 0.3) }
        }
        for c in L.decor {
            switch c.kind {
            case .vine:
                P(reg == .cap ? "#dcbf90" : "#cdb07a") { rpoly(&$0, c) }
                St("#6f8a3a", 4, [6, 4]) { rows(&$0, c, max(5, Int((c.d / 0.26).rounded()))) }
            case .orchard: P(reg == .cap ? "#cdc28a" : "#bcc27e") { rpoly(&$0, c) }
            case .crops, .cane:
                P(c.kind == .cane ? "#93b05c" : bri ? "#cbc276" : "#a0c06a") { rpoly(&$0, c) }
                St("rgba(60,100,40,.3)", 1.5) { rows(&$0, c, max(6, Int((c.d / 0.2).rounded())), 0.08) }
            case .pasture:
                P("#9fcb6c") { rpoly(&$0, c, 1.06, 0.1) }
                var pts = c.poly.map { GridPoint(c.cx + ($0.x - c.cx) * 1.06, c.cy + ($0.y - c.cy) * 1.06) }
                pts.append(pts[0])
                St("#b8ad94", 6) { poly(&$0, pts) }
                St("#8a7f68", 2, [3, 5]) { poly(&$0, pts) }
            case .scrub:
                var R = Mulberry32(seed: UInt32(truncatingIfNeeded: c.seed))
                for _ in 0..<24 {
                    let p = c.at((R.next() - 0.5) * c.w, (R.next() - 0.5) * c.d)
                    let col = R.next() < 0.5 ? "#8f9c6c" : "#a3a97a"
                    let rx = CGFloat(5 + R.next() * 6), ry = CGFloat(3 + R.next() * 2)
                    P(col) { blob(&$0, p, rx, ry) }
                }
            case .rv:
                P("#d8c4a4") { rpoly(&$0, c, 0.9) }
                St("rgba(110,80,50,.22)", 1.5) { rows(&$0, c, 3, 0.3) }
            case .farm: P(bri ? "#a8cc78" : hexMix(look.road, "#ffffff", 0.1)) { rpoly(&$0, c, 0.62, 0.4) }
            case .palms:
                P(reg == .lux ? "#a8bc72" : "#b8b07a") { blob(&$0, GridPoint(c.cx, c.cy), CGFloat(c.w + c.d) * 26, CGFloat(c.w + c.d) * 11) }
            case .rival:
                P(hexMix(look.field, "#d8c8a0", 0.2)) { rpoly(&$0, c) }
                P(hexMix(look.field, look.road, 0.5)) { rpoly(&$0, c, 0.45, 0.5) }
            case .view, .mesa, .dovecote, nil: break
            }
        }
        var g = OutskirtsGround()
        g.fills = fillOrder.map { (outColor($0), fills[$0]!) }
        g.strokes = strokeOrder.map { k in
            let s = strokes[k]!
            return (outColor(s.0), StrokeStyle(lineWidth: s.1, lineCap: .round, lineJoin: .round, dash: s.2), s.3)
        }
        return g
    }

    // MARK: Things out there

    /// The orchard tree (an apricot in Cappadocia, with its fruit).
    mutating func outTree(_ x: CGFloat, _ y: CGFloat, cap: Bool, _ k: CGFloat) {
        roundTree(x, y, 0.55 * k, "#7a9a44")
        if cap { for i in 0..<4 { ellipse(x + (-5 + CGFloat((i * 7) % 11)) * k, y + (-17 - CGFloat((i * 5) % 9)) * k, 1.8 * k, 1.8 * k, hex("#f0a040")) } }
    }

    /// Trees along the tracks: poplars and apricots, junipers, date palms, oaks.
    mutating func outTrackTree(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat, _ kind: Int) {
        switch s.region {
        case .lux: palm(x, y, 0.55 * k, tt: t + Double(x) * 0.01)
        case .bri: oakTree(x, y, (kind == 1 ? 0.55 : 0.7) * k)
        case .abq: roundTree(x, y, (kind == 1 ? 0.5 : 0.62) * k, kind == 1 ? "#6a8a48" : "#4f6e3a")
        case .cap:
            if kind == 1 { roundTree(x, y, 0.6 * k, "#86a24c"); return }
            rect(x - 1.2 * k, y - 12 * k, 2.4 * k, 12 * k, hex("#6a4a2a"))
            let g = grad([(hex("#9cbc5a"), 0), (hex("#5e8a3a"), 1)])
            c.fill(Path(ellipseIn: CGRect(x: x - 6.5 * k, y: y - 60 * k, width: 13 * k, height: 52 * k)),
                   with: .linearGradient(g, startPoint: pt(x - 7 * k, 0), endPoint: pt(x + 7 * k, 0))) // a poplar
        }
    }

    /// A vehicle as three flat faces.
    @discardableResult
    mutating func vbox(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, _ lit: String, _ shade: String, _ top: String, lift: CGFloat = 0) -> (Box, CGFloat) {
        let (A0, B0, C0, D0) = corners(gx, gy, w, d)
        let A = upp(A0, lift), B = upp(B0, lift), C = upp(C0, lift), D = upp(D0, lift)
        poly([D, C, upp(C, h), upp(D, h)], hex(lit))
        poly([C, B, upp(B, h), upp(C, h)], hex(shade))
        poly([upp(A, h), upp(B, h), upp(C, h), upp(D, h)], hex(top))
        return (Box(A: A, B: B, C: C, D: D, a: upp(A, h), b: upp(B, h), c: upp(C, h), d: upp(D, h)), h)
    }

    private mutating func vEdge(_ f: Box, _ h: CGFloat) {
        var p = Path()
        p.move(to: f.D); p.addLine(to: f.C); p.addLine(to: f.B); p.addLine(to: f.b); p.addLine(to: f.a); p.addLine(to: f.d); p.closeSubpath()
        c.stroke(p, with: .color(rgba(50, 40, 40, 0.35)), lineWidth: 1)
    }

    /// The chase van: white, a stripe in your colours, a roof rack, a trailer with the basket once loaded (v135.1: a
    /// third bigger, with a soft outline). Returns the two parts with their depths.
    func chaseVan(_ gx: Double, _ gy: Double, _ dir: GridPoint, loaded: Bool, moving: Bool) -> [(Double, (inout TownPainter) -> Void)] {
        let ax = abs(dir.x) > abs(dir.y), sgRaw = ax ? dir.x : dir.y, sg: Double = sgRaw > 0 ? 1 : sgRaw < 0 ? -1 : 1
        let col = s.colors.first ?? "#ff5e3a", tt = t
        let bob = moving ? CGFloat(sin(tt * 18)) * 0.6 : 0, vw = ax ? 0.84 : 0.42, vd = ax ? 0.42 : 0.84, H: CGFloat = 24
        let tr = ax ? (gx - sg * 0.84, gy) : (gx, gy - sg * 0.84), tw = ax ? 0.54 : 0.4, td = ax ? 0.4 : 0.54
        let trailer: (inout TownPainter) -> Void = { p in
            let q = TownGeo.iso(tr.0, tr.1)
            p.blobShadow(q.x + 8, q.y + 4, 21, 8, 0.18)
            let (f, h) = p.vbox(tr.0 - tw / 2, tr.1 - td / 2, tw, td, 7, "#7a7068", "#5a524c", "#8a8078", lift: 5)
            p.vEdge(f, h)
            if loaded {
                p.vbox(tr.0 - 0.15, tr.1 - 0.15, 0.3, 0.3, 13, "#a8763e", "#7a522a", "#c08a50", lift: 12)
                p.ellipse(q.x, q.y - 30, 12, 6.5, p.mix(col, "#ffffff", 0.15))
                p.ellipse(q.x - 3, q.y - 32, 5, 2.5, Color.white.opacity(0.35))
            }
            for w in [f.D, f.C] { p.ellipse(w.x, w.y + 1, 3.4, 3.4, p.hex("#2a1e18")) }
        }
        let van: (inout TownPainter) -> Void = { p in
            let q = TownGeo.iso(gx, gy)
            p.blobShadow(q.x + 10, q.y + 5, 30, 10, 0.2)
            for u in [0.2, 0.8] {
                let w = TownGeo.iso(gx + (ax ? (u - 0.5) * vw : -vw / 2), gy + (ax ? vd / 2 : (u - 0.5) * vd))
                p.ellipse(w.x, w.y - 2.5, 4.2, 4, p.hex("#2a1e18")); p.ellipse(w.x, w.y - 2.5, 1.6, 1.5, p.hex("#9a948a"))
            }
            let (f, h) = p.vbox(gx - vw / 2, gy - vd / 2, vw, vd, H, "#fbfaf6", "#d6d4ce", "#eeece6", lift: 5 + bob)
            p.vEdge(f, h)
            for (a0, b0) in [(f.D, f.C), (f.C, f.B)] {
                let a = p.upp(a0, 5 + bob + 9), b = p.upp(b0, 5 + bob + 9)
                p.poly([a, b, p.pt(b.x, b.y - 4), p.pt(a.x, a.y - 4)], p.hex(col))
            }
            // the windscreen on the face toward the camera when it drives toward it
            let front: (CGPoint, CGPoint)? = ax ? (sg > 0 ? (f.C, f.B) : nil) : (sg > 0 ? (f.D, f.C) : nil)
            if let fr = front {
                let a = p.upp(p.lp(fr.0, fr.1, 0.1), 5 + bob + 16), b = p.upp(p.lp(fr.0, fr.1, 0.9), 5 + bob + 16)
                p.poly([a, b, p.pt(b.x, b.y - 8), p.pt(a.x, a.y - 8)], p.hex("#5a7a96"))
            } else {
                let sd = ax ? (f.D, f.C) : (f.C, f.B)
                for k: CGFloat in [0.12, 0.4, 0.68] {
                    let a = p.upp(p.lp(sd.0, sd.1, k), 5 + bob + 16), b = p.upp(p.lp(sd.0, sd.1, k + 0.2), 5 + bob + 16)
                    p.poly([a, b, p.pt(b.x, b.y - 7), p.pt(a.x, a.y - 7)], p.hex("#6a8aa6"))
                }
            }
            // a roof rack
            let r0 = p.lp(p.upp(f.A, H), p.upp(f.C, H), 0.25), r1 = p.lp(p.upp(f.A, H), p.upp(f.C, H), 0.75)
            p.line(p.pt(r0.x, r0.y - 3), p.pt(r1.x, r1.y - 3), p.hex("#8a8680"), 1.6)
        }
        return [(tr.0 + tr.1, trailer), (gx + gy, van)]
    }

    /// Dust kicked up behind a vehicle on a dirt track: a few soft puffs, fading.
    mutating func dustPuffs(_ path: [GridPoint], _ s0: Double, _ back: Double) {
        let tone: (Double, Double, Double) = s.region == .bri ? (210, 205, 190) : s.region == .abq ? (225, 180, 140) : (232, 206, 166)
        for k in 1...4 {
            let q = gp(OutskirtsLayout.walk(path, max(0, s0 + back * Double(k) * 0.3)).p), kk = CGFloat(k)
            let r = 4 + kk * 3.2 + CGFloat(sin(t * 3 + Double(k))) * 0.8
            ellipse(q.x + kk * 2, q.y - 5 - kk * 2.4, r, r * 0.7, rgba(tone.0, tone.1, tone.2, 0.4 - Double(k) * 0.08))
        }
    }

    /// An envelope lying on the ground (k 1 full, 0 packed away), turned with its field, colours softened toward the ground.
    mutating func lyingEnvelope(_ gx: Double, _ gy: Double, _ k: Double, _ c1: String, _ c2: String, _ ang: Double) {
        if k <= 0.02 { return }
        let p = TownGeo.iso(gx, gy), ground = s.region == .bri ? "#d8e4c8" : "#efe4d0"
        var g = c
        g.concatenate(CGAffineTransform(a: TownGeo.TW / 2, b: TownGeo.TH / 2, c: -TownGeo.TW / 2, d: TownGeo.TH / 2, tx: p.x, ty: p.y))
        g.rotate(by: .radians(ang))
        let len = CGFloat(0.3 + 0.14 * min(1, k * 1.4)), wid = CGFloat(0.17 * (0.3 + 0.7 * k))
        g.fill(Path(ellipseIn: CGRect(x: 0.03 - len, y: 0.03 - wid * 1.1, width: len * 2, height: wid * 2.2)), with: .color(rgba(90, 45, 20, 0.1)))
        // a teardrop: the round crown at -len, the mouth narrowing to the basket at +len
        var body = Path()
        body.move(to: pt(-len, 0))
        body.addCurve(to: pt(len, -wid * 0.28), control1: pt(-len, -wid * 1.3), control2: pt(len * 0.1, -wid * 1.05))
        body.addLine(to: pt(len, wid * 0.28))
        body.addCurve(to: pt(-len, 0), control1: pt(len * 0.1, wid * 1.05), control2: pt(-len, wid * 1.3))
        body.closeSubpath()
        g.fill(body, with: .color(mix(c1, ground, 0.38)))
        var inner = g
        inner.clip(to: body)
        var seams = Path()
        for u: CGFloat in [-0.45, 0, 0.45] {
            seams.move(to: pt(-len, u * wid * 0.5)); seams.addQuadCurve(to: pt(len, u * wid * 0.6), control: pt(0, u * wid * 1.5))
        }
        inner.stroke(seams, with: .color(mix(c2, ground, 0.3)), lineWidth: 0.022)
        inner.fill(Path(CGRect(x: -len, y: -wid, width: len * 2, height: wid * 0.45)), with: .color(Color.white.opacity(0.2)))
        g.fill(Path(CGRect(x: len * 0.96, y: -0.05, width: 0.09, height: 0.1)), with: .color(hex("#8a5a30")))
        g.fill(Path(CGRect(x: len * 0.96 + 0.05, y: -0.05, width: 0.04, height: 0.1)), with: .color(hex("#6a4220")))
    }

    /// Someone holding up a glass: the arm raised, a glint now and then; s scales the figure.
    mutating func toaster(_ x: CGFloat, _ y: CGFloat, _ col: String, _ tt: Double, _ ph: Double, _ sc: CGFloat = 1) {
        if sc != 1 {
            let keep = c
            c.translateBy(x: x, y: y); c.scaleBy(x: sc, y: sc)
            toaster(0, 0, col, tt, ph)
            c = keep
            return
        }
        person(x, y, col, 0, ph)
        let up = CGFloat((sin(tt * 1.3 + ph) + 1) / 2)
        line(pt(x + 2.5, y - 11), pt(x + 5, y - 15 - up * 5), hex(col), 1.8)
        rect(x + 4, y - 19 - up * 5, 2.2, 3.4, hex("#fff2c0"))
        if (tt * 0.7 + ph).truncatingRemainder(dividingBy: 3) < 0.12 {
            rect(x + 4.5, y - 23 - up * 5, 1.4, 1.4, Color.white.opacity(0.95)); rect(x + 7, y - 21 - up * 5, 1.4, 1.4, Color.white.opacity(0.95))
        }
    }

    mutating func quadBike(_ x: CGFloat, _ y: CGFloat, _ col: String, _ ph: Double, _ dx: CGFloat) {
        let b = CGFloat(sin(t * 14 + ph)) * 0.6
        ellipse(x + 4, y + 1, 9, 3, rgba(90, 45, 20, 0.18))
        ellipse(x - 5, y - 2, 3, 3, hex("#2a1e18")); ellipse(x + 5, y - 2, 3, 3, hex("#2a1e18"))
        rect(x - 7, y - 8 + b, 14, 5, hex(col))
        ellipse(x - dx, y - 17 + b, 2.6, 2.6, hex("#3a2418"))
        rect(x - 2.5 - dx, y - 15 + b, 5, 7, hex("#e8e2d4"))
        var helmet = Path()
        helmet.addArc(center: pt(x - dx, y - 18.5 + b), radius: 2.8, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
        c.fill(helmet, with: .color(hex("#ff5e3a")))
    }

    mutating func rider(_ x: CGFloat, _ y: CGFloat, _ ph: Double, _ dx: CGFloat, _ coat: String) {
        let sw = CGFloat(sin(t * 4 + ph)), hc = ["#7a4a2a", "#3a2a20", "#c09060", "#f2ece0"][Int(floor(ph)) % 4]
        ellipse(x + 4, y + 1, 11, 3, rgba(90, 45, 20, 0.18))
        for (o, k) in [(CGFloat(-6), CGFloat(1)), (-3, -1), (4, 1), (7, -1)] {
            line(pt(x + o * dx, y - 7), pt(x + o * dx + sw * k * 1.5, y), mix(hc, "#000000", 0.25), 2)
        }
        ellipse(x, y - 10, 9, 4.5, hex(hc))
        line(pt(x + 7 * dx, y - 11), pt(x + 11 * dx, y - 17), hex(hc), 3.4)
        ellipse(x + 12 * dx, y - 17, 3.4, 2.2, hex(hc))
        var tail = Path()
        tail.move(to: pt(x - 9 * dx, y - 11)); tail.addQuadCurve(to: pt(x - 11 * dx, y - 3), control: pt(x - 12 * dx, y - 8))
        c.stroke(tail, with: .color(mix(hc, "#000000", 0.45)), lineWidth: 1.6)
        rect(x - 2.5, y - 21, 5, 8, hex(coat))
        ellipse(x, y - 24, 2.8, 2.8, hex("#3a2418"))
    }

    mutating func rvCaravan(_ x: CGFloat, _ y: CGFloat, _ col: String, lit: Bool) {
        ellipse(x + 8, y + 2, 22, 6, rgba(90, 45, 20, 0.16))
        c.fill(Path(roundedRect: CGRect(x: x - 16, y: y - 17, width: 32, height: 15), cornerRadius: 4), with: .color(hex("#f6f2ea")))
        rect(x + 10, y - 17, 6, 15, hex("#d8d2c6"))
        rect(x - 16, y - 9, 32, 2.5, hex(col))
        rect(x - 11, y - 14, 6, 4, hex(lit ? "#ffd27a" : "#6a8aa6")); rect(x - 1, y - 14, 6, 4, hex(lit ? "#ffd27a" : "#6a8aa6"))
        ellipse(x - 8, y - 2, 2.6, 2.6, hex("#2a1e18")); ellipse(x + 6, y - 2, 2.6, 2.6, hex("#2a1e18"))
        if lit { nightLite(x - 4, y - 12, 26, (255, 200, 120), 0.8) }
    }

    /// Two fairy chimneys with dovecotes: rows of small dark doorways framed in white paint.
    mutating func dovecoteRock(_ x: CGFloat, _ y: CGFloat) {
        ScenePainter.chimney(&c, x - 26, y + 6, 70, 120, body: hex("#efc79e"), shade: hex("#c69068"), cap: hex("#6a4430"))
        ScenePainter.chimney(&c, x + 20, y + 10, 84, 150, body: hex("#f3cfa6"), shade: hex("#c8936a"), cap: hex("#6a4430"))
        for (dx, dy) in [(CGFloat(14), CGFloat(-62)), (24, -78), (10, -96), (28, -100), (-30, -48), (-22, -66)] {
            func door(_ r: CGFloat, _ top: CGFloat, _ col: String) {
                var p = Path()
                p.addArc(center: pt(x + dx, y + dy + top), radius: r, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
                p.addLine(to: pt(x + dx + r, y + dy + 6)); p.addLine(to: pt(x + dx - r, y + dy + 6)); p.closeSubpath()
                c.fill(p, with: .color(hex(col)))
            }
            door(5.4, 0, "#fbf3e4"); door(3, 1, "#3a2418")
        }
    }

    mutating func farmHouse(_ gx: Double, _ gy: Double) {
        let reg = s.region, f = block(gx, gy, 0.9, 0.7, 34, courses: reg == .bri)
        opening(f.D, f.C, 34, 0.3, 0, 0.2, 0.6, door: true)
        opening(f.D, f.C, 34, 0.72, 0.35, 0.18, 0.35, lit: dark)
        opening(f.C, f.B, 34, 0.5, 0.35, 0.25, 0.35)
        if reg == .cap || reg == .bri { gableRoof(gx, gy, 0.9, 0.7, 34, 14, "#b4623e") } else { flatRoof(gx, gy, 0.9, 0.7, 34, dome: reg == .lux) }
        let tp = iso(gx + 1.25, gy + 0.3)
        switch reg {
        case .lux: palm(tp.x, tp.y, 0.8)
        case .bri: oakTree(tp.x, tp.y, 0.9)
        default: roundTree(tp.x, tp.y, 0.9, reg == .abq ? "#9aa84a" : "#7aa04a")
        }
    }

    /// v135.1: a mesa of layered sandstone: a scree slope, cliffs banded in red, cream and rust strata cut by gullies, a
    /// pale caprock, the shaded side turned right, fallen boulders, a lone eroded spire beside it. w and h in pixels.
    mutating func mesaRock(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ seed: Int, spire: Bool = true,
                           lit: String = "#cf7a4c", shade: String = "#8e4a2c") {
        var R = Mulberry32(seed: UInt32(truncatingIfNeeded: seed))
        let cap = TownPainter.hexMix(lit, "#f4d0a8", 0.45), N = 8
        let rx = w * 0.44, ry = w * 0.21
        var jit: [CGFloat] = [], an: [Double] = []
        for i in 0..<N { jit.append(0.78 + CGFloat(R.next()) * 0.26); an.append((Double(i) + (R.next() - 0.5) * 0.5) / Double(N) * .pi * 2) }
        jit[Int(floor(R.next() * Double(N)))] *= 0.78 // one bay bitten deep out of the rim
        func ring(_ k: CGFloat, _ dy: CGFloat) -> [CGPoint] {
            (0..<N).map { i in pt(x + CGFloat(cos(an[i])) * rx * jit[i] * k, y - dy + CGFloat(sin(an[i])) * ry * jit[i] * k) }
        }
        let top = ring(1, h), mid = ring(1.07, h * 0.3), base = ring(1.38, 0)
        if spire { mesaRock(x + w * 0.44, y - h * 0.1, w * 0.15, h * 0.82, seed + 7, spire: false, lit: lit, shade: shade) }
        let bands: [(CGFloat, CGFloat, Color)] = [(0.14, 0.22, rgba(255, 232, 196, 0.2)), (0.34, 0.4, rgba(110, 40, 20, 0.16)),
                                                  (0.52, 0.62, rgba(255, 222, 180, 0.16)), (0.76, 0.82, rgba(110, 40, 20, 0.14))]
        let order = (0..<N).sorted { sin(an[$0]) < sin(an[$1]) }
        for i in order {
            let i2 = (i + 1) % N, a1 = i2 != 0 ? an[i2] : an[0] + .pi * 2, am = (an[i] + a1) / 2
            if sin(am) < -0.1 { continue }
            let k = min(max((cos(am) + 1) / 2, 0), 1), sk = k * k * (3 - 2 * k)
            let colHex = TownPainter.hexMix(lit, shade, sk)
            poly([mid[i], mid[i2], base[i2], base[i]], mix(colHex, "#e2b088", 0.42)) // scree
            poly([top[i], top[i2], mid[i2], mid[i]], hex(colHex))
            for (f0, f1, col) in bands { poly([lp(top[i], mid[i], f0), lp(top[i2], mid[i2], f0), lp(top[i2], mid[i2], f1), lp(top[i], mid[i], f1)], col) }
            poly([top[i], top[i2], lp(top[i2], mid[i2], 0.08), lp(top[i], mid[i], 0.08)], rgba(60, 20, 10, 0.22)) // under the caprock's lip
            if R.next() < 0.8 {
                let u = 0.2 + CGFloat(R.next()) * 0.6, p0 = lp(top[i], top[i2], u)
                let p1 = lp(mid[i], mid[i2], u + (CGFloat(R.next()) - 0.5) * 0.2)
                line(p0, lp(p0, p1, 0.6 + CGFloat(R.next()) * 0.4), rgba(70, 25, 12, 0.26), 1.2)
            }
        }
        poly(top, hex(cap))
        poly([top[0], top[1], top[2], pt(x + rx * 0.1, y - h)], rgba(150, 70, 40, 0.12))
        var rim = Path(), first = true
        for i in 0..<N where cos(an[i]) < 0.2 && sin(an[i]) > -0.2 {
            if first { rim.move(to: top[i]); first = false } else { rim.addLine(to: top[i]) }
        }
        c.stroke(rim, with: .color(rgba(255, 238, 210, 0.5)), lineWidth: 1.6)
        for i in 0..<6 {
            let a = Double.pi * (0.1 + R.next() * 0.8), bx = x + CGFloat(cos(a)) * rx * 1.3, by = y - 2 + CGFloat(sin(a)) * ry * 1.25
            let r = 1.8 + CGFloat(R.next()) * 2.6
            ellipse(bx, by - r * 0.5, r * 1.3, r, i % 2 == 1 ? mix(lit, "#e2b088", 0.3) : hex(shade))
        }
    }

    /// v135.1: the sunrise knoll: a low rise with an uneven crest, a worn path up and rocks. Returns its top and size.
    @discardableResult
    mutating func viewKnoll(_ c0: OutskirtsLayout.Site) -> (top: CGPoint, rx: CGFloat, ry: CGFloat) {
        let reg = s.region, p = iso(c0.cx, c0.cy), rx = CGFloat(c0.w + c0.d) * 30, ry = rx * 0.36, hh = 16 + CGFloat(c0.w) * 4
        let hc = reg == .bri ? ["#6e9a4a", "#8cbc60", "#9cca6c"] : reg == .abq ? ["#a8643e", "#cc8e64", "#d89c70"]
            : reg == .lux ? ["#b89a6a", "#d8bc8a", "#e4c898"] : ["#b88458", "#dcb088", "#e8c09a"]
        var R = Mulberry32(seed: UInt32(truncatingIfNeeded: c0.seed))
        var wob: [CGFloat] = []
        for _ in 0..<14 { wob.append(0.9 + CGFloat(R.next()) * 0.14) }
        func ring(_ k: CGFloat, _ lift: CGFloat) -> [CGPoint] {
            (0..<14).map { i in let a = Double(i) / 14 * .pi * 2; return pt(p.x + CGFloat(cos(a)) * rx * k * wob[i], p.y - lift + CGFloat(sin(a)) * ry * k * wob[i]) }
        }
        ellipse(p.x + 12, p.y + 8, rx * 1.05, ry * 1.1, rgba(90, 45, 20, 0.12))
        poly(ring(1, 0), hex(hc[0])); poly(ring(0.86, hh * 0.55), hex(hc[1])); poly(ring(0.62, hh), hex(hc[2]))
        var path = Path()
        path.move(to: pt(p.x + rx * 0.9, p.y + ry * 0.4))
        path.addQuadCurve(to: pt(p.x + rx * 0.2, p.y - hh), control: pt(p.x + rx * 0.45, p.y + ry * 0.1 - hh * 0.5))
        c.stroke(path, with: .color(mix(hc[2], "#ffffff", 0.35)), style: StrokeStyle(lineWidth: 3, dash: [5, 4]))
        for _ in 0..<6 {
            let a = R.next() * .pi * 2, k = 0.5 + CGFloat(R.next()) * 0.45
            let q = pt(p.x + CGFloat(cos(a)) * rx * k, p.y - hh * (1 - k) + CGFloat(sin(a)) * ry * k)
            let w = 3 + CGFloat(R.next()) * 3, h2 = 2 + CGFloat(R.next()) * 1.6
            ellipse(q.x, q.y - 2, w, h2, mix(hc[0], "#5a4030", 0.4))
        }
        return (pt(p.x, p.y - hh), rx, ry)
    }

    // MARK: Scene items

    /// Everything that stands or moves out there, depth-sorted with the town (prototype `outskirtsItems`).
    func outskirtsItems() -> [TownItem] {
        let L = outskirts, nf = s.outskirtsFields, nc = Outskirts.crews(fields: nf), reg = s.region, day = outDay, tt = t
        var items: [TownItem] = []
        // skip what's off screen
        let x0 = -v.ox / v.z - 220, x1 = (size.width - v.ox) / v.z + 220, y0 = -v.oy / v.z - 120, y1 = (size.height - v.oy) / v.z + 720
        func seen(_ gx: Double, _ gy: Double) -> Bool { let p = TownGeo.iso(gx, gy); return p.x > x0 && p.x < x1 && p.y > y0 && p.y < y1 }
        func add(_ gx: Double, _ gy: Double, depth: Double? = nil, shadow: ((inout TownPainter) -> Void)? = nil, _ draw: @escaping (inout TownPainter) -> Void) {
            if seen(gx, gy) { items.append(TownItem(depth: depth ?? gx + gy, at: (gx, gy), shadow: shadow, draw: draw)) }
        }
        // your colours in a few variations, mixed with the fleet's own designs
        let my = s.colors.count > 1 ? s.colors : (s.colors + ["#ffc23d", "#ff5e3a"]), fleet = s.local.balloons
        func cols(_ i: Int) -> ([String], Design?) {
            if !fleet.isEmpty, let d = s.design(of: fleet[(i * 7) % fleet.count]) { return (d.colors, d) }
            switch i % 4 {
            case 0: return ([my[0], my[1]], nil)
            case 1: return ([my[1], my[0]], nil)
            case 2: return ([my[0], "#fbf6ec"], nil)
            default: return ([TownPainter.hexMix(my[0], "#ffffff", 0.3), my[1]], nil)
            }
        }
        var nb = 0
        let since = tt - dawn
        // your fields: the ones in use this morning lay out two or three envelopes one by one, inflate them, send them up
        if day {
            for (i, c) in L.fields.prefix(nf).enumerated() {
                let kit = c.at(-c.w / 2 + 0.3, c.d / 2 - 0.22)
                add(kit.x, kit.y) { p in let q = gp(kit); p.propane(q.x, q.y); p.propane(q.x + 11, q.y + 5) }
                if !Outskirts.inUse(i, fields: nf, day: s.day) { continue }
                var hr = Mulberry32(seed: UInt32(truncatingIfNeeded: i * 31 + 5))
                let h0 = hr.next(), n = 2 + (h0 < 0.4 ? 1 : 0), sp = min(0.82, c.w / (Double(n) + 0.3)), ang = atan2(c.uy, c.ux)
                for j in 0..<n {
                    let at = c.at((Double(j) - Double(n - 1) / 2) * sp, (j % 2 == 1 ? 0.16 : -0.1) * c.d), gx = at.x, gy = at.y
                    let cc = cols(i * 3 + j), P = 60.0
                    let u = since - Double(i) * 0.9 - Double(j) * 2.6 - h0 * 4, ph = u < 0 ? -1 : u.truncatingRemainder(dividingBy: P) / P
                    if ph < 0.16 {
                        if ph >= 0.05 { add(gx, gy) { p in p.lyingEnvelope(gx, gy, 1, cc.0[0], cc.0[1], ang) } }
                        continue
                    }
                    let inf = ph < 0.42, k = inf ? 0.3 + 0.7 * (ph - 0.16) / 0.26 : 1
                    let alt = CGFloat(inf ? 0 : pow((ph - 0.42) / 0.58, 1.5) * 640), a = ph > 0.9 ? (1 - ph) * 10 : 1
                    if !inf { nb += 1; if nb > Outskirts.maxBalloons { continue } }
                    let burn = inf ? ph > 0.3 && (tt * 3 + Double(j)).truncatingRemainder(dividingBy: 1) < 0.5 : (tt + Double(i + j)).truncatingRemainder(dividingBy: 3) < 0.4
                    add(gx, gy, shadow: { p in
                        let q = TownGeo.iso(gx, gy), f = CGFloat(k) * (1 - alt / 900)
                        p.blobShadow(q.x + 20 + alt * 0.12, q.y + 6, 24 * f, 8 * f, inf ? 0.18 : 0.1)
                    }) { p in
                        let q = TownGeo.iso(gx, gy)
                        if inf && k < 0.6 { p.lyingEnvelope(gx, gy, 1 - (k - 0.3) / 0.3, cc.0[0], cc.0[1], ang) }
                        p.balloon(q.x + alt * 0.12, q.y - alt, 30 * CGFloat(k), cc.0, burn: burn, alpha: a, design: k > 0.95 ? cc.1 : nil)
                    }
                }
            }
            if nf == 0, let c = L.fields.first {
                add(c.cx, c.cy) { p in let q = TownGeo.iso(c.cx, c.cy); p.propane(q.x, q.y); p.propane(q.x + 11, q.y + 5); p.crate(q.x - 20, q.y - 6) }
            }
            // rival fields far out: their balloons in their colours
            let rc = s.local.rivals.map { $0.colors } + [["#14a39a", "#e8fff9"], ["#9b7be0", "#f2ebff"]]
            for (i, c) in L.decor.filter({ $0.kind == .rival }).enumerated() {
                for j in 0..<2 {
                    let ph = (tt * 0.04 + Double(i) * 0.37 + Double(j) * 0.5).truncatingRemainder(dividingBy: 1)
                    let at = c.at((Double(j) - 0.5) * min(1, c.w * 0.4), 0), gx = at.x, gy = at.y, cc = rc[(i * 2 + j) % rc.count]
                    let inf = ph < 0.5, k = inf ? 0.35 + 0.65 * ph / 0.5 : 1, alt = CGFloat(inf ? 0 : pow((ph - 0.5) / 0.5, 1.6) * 560)
                    if !inf { nb += 1; if nb > Outskirts.maxBalloons { continue } }
                    let burn = inf ? ph > 0.3 && (tt * 3).truncatingRemainder(dividingBy: 1) < 0.5 : (tt + Double(i)).truncatingRemainder(dividingBy: 3) < 0.4
                    add(gx, gy, shadow: { p in let q = TownGeo.iso(gx, gy); p.blobShadow(q.x + 18, q.y + 6, 22 * CGFloat(k), 7 * CGFloat(k), inf ? 0.16 : 0.08) }) { p in
                        let q = TownGeo.iso(gx, gy)
                        p.balloon(q.x, q.y - alt, 30 * 0.93 * CGFloat(k), cc, burn: burn, alpha: ph > 0.9 ? (1 - ph) * 10 : 1)
                    }
                }
            }
            // the chase crews: out along their track to the landing spot, a toast, and back
            for (ci, K) in L.crews.prefix(nc).enumerated() {
                let P = 56.0, u = (tt + Double(ci) * 14.5 + 9).truncatingRemainder(dividingBy: P), path = K.path, len = K.len
                func ease(_ k: Double) -> Double { k < 0.5 ? 2 * k * k : 1 - pow(-2 * k + 2, 2) / 2 }
                let sAlong = u < 1 ? 0 : u < 11 ? ease((u - 1) / 10) * len : u < 35 ? len : u < 45 ? (1 - ease((u - 35) / 10)) * len : 0
                let at = OutskirtsLayout.walk(path, sAlong), back = u >= 35
                let dir = back ? GridPoint(-at.dir.x, -at.dir.y) : at.dir, a = u < 1 ? u : u > 45 ? max(0, 46 - u) : 1
                let moving = (u > 1 && u < 11) || (u > 35 && u < 45)
                if a > 0 && seen(at.p.x, at.p.y) {
                    for (dp, fn) in chaseVan(at.p.x, at.p.y, dir, loaded: u > 33, moving: moving) {
                        items.append(TownItem(depth: dp + 0.3, at: (at.p.x, at.p.y), draw: { p in let keep = p.c; p.c.opacity *= a; fn(&p); p.c = keep }))
                    }
                    if moving {
                        items.append(TownItem(depth: at.p.x + at.p.y - 0.6, at: (at.p.x, at.p.y), draw: { p in
                            let keep = p.c; p.c.opacity *= a; p.dustPuffs(path, sAlong, back ? 1 : -1); p.c = keep
                        }))
                    }
                }
                let lx = K.spot.x, ly = K.spot.y, cc = cols(ci * 5 + 1), ea = atan2(K.dir.y, K.dir.x)
                if u > 2 && u < 13 { // coming down beside the track, drifting in on the wind
                    let k = (u - 2) / 11, alt = CGFloat(440 * pow(1 - k, 1.7)), drift = (1 - k) * 1.6
                    let burn = (tt * 2 + Double(ci)).truncatingRemainder(dividingBy: 2) < 0.25
                    add(lx - drift, ly, shadow: { p in
                        let q = TownGeo.iso(lx - drift, ly), f = CGFloat(0.5 + k * 0.5)
                        p.blobShadow(q.x + 18, q.y + 6, 22 * f, 8 * f, 0.08 + k * 0.1)
                    }) { p in let q = TownGeo.iso(lx - drift, ly); p.balloon(q.x, q.y - alt, 30, cc.0, burn: burn, design: cc.1) }
                } else if u >= 13 && u < 34 { // down: the envelope tips over and sighs flat; the passengers toast
                    let k = u < 17 ? (u - 13) / 4 : 1, pk = u > 30 ? 1 - (u - 30) / 4 : 1, ex = lx + cos(ea) * 0.5, ey = ly + sin(ea) * 0.5
                    add(lx, ly, depth: lx + ly - 0.2) { p in
                        let q = TownGeo.iso(lx, ly), kk = CGFloat(k)
                        if k < 1 { p.balloon(q.x + kk * 26, q.y + kk * 4, 30 * (1 - kk * 0.7), cc.0, alpha: 1 - k) }
                        p.lyingEnvelope(ex, ey, k * pk, cc.0[0], cc.0[1], ea)
                    }
                    if u > 15 && u < 33 {
                        let tb = (lx - cos(ea) * 0.42 + 0.1, ly - sin(ea) * 0.42 + 0.25)
                        add(tb.0, tb.1) { p in // a folding table with a white cloth and the bottle
                            let q = TownGeo.iso(tb.0, tb.1)
                            p.rect(q.x - 7, q.y - 9, 1.6, 9, p.hex("#8a6a48")); p.rect(q.x + 6, q.y - 9, 1.6, 9, p.hex("#8a6a48"))
                            p.rect(q.x - 9, q.y - 12, 18, 4, p.hex("#fbf8f0"))
                            p.rect(q.x - 2, q.y - 20, 3.4, 8, p.hex("#2e5a3a")); p.rect(q.x - 1.6, q.y - 22, 2.6, 2.5, p.hex("#e8c860"))
                        }
                        let shirts = ["#ff5e3a", "#5aa9e6", "#ffc23d", "#14a39a", "#2b2350"]
                        for i in 0..<5 {
                            let gx = tb.0 + 0.05 + Double(i % 3) * 0.26 - 0.3 + (i > 2 ? 0.12 : 0), gy = tb.1 + 0.3 + (i > 2 ? 0.22 : 0)
                            add(gx, gy) { p in let q = TownGeo.iso(gx, gy); p.toaster(q.x, q.y, shirts[i], tt, Double(i) * 1.3, 1.25) }
                        }
                    }
                }
            }
        }
        // the decor
        for c in L.decor {
            var Rr = Mulberry32(seed: UInt32(truncatingIfNeeded: c.seed + 3))
            switch c.kind {
            case .orchard:
                let nr = max(2, Int((c.d / 0.62).rounded())), nc2 = max(3, Int((c.w / 0.6).rounded()))
                for r in 0..<nr {
                    for q in 0..<nc2 {
                        let miss = Rr.next() < 0.08, ja = (Rr.next() - 0.5) * 0.12, jb = (Rr.next() - 0.5) * 0.12
                        if miss { continue }
                        let a = (Double(q) - Double(nc2 - 1) / 2) * (c.w - 0.4) / Double(max(1, nc2 - 1)) + Double(r % 2) * 0.12 + ja
                        let b = (Double(r) - Double(nr - 1) / 2) * (c.d - 0.45) / Double(max(1, nr - 1)) + jb
                        let at = c.at(a, b), sc = CGFloat(0.85 + Rr.next() * 0.3)
                        add(at.x, at.y, shadow: { p in let w = gp(at); p.blobShadow(w.x + 8, w.y + 3, 10 * sc, 3.5 * sc, 0.14) }) { p in
                            let w = gp(at); p.outTree(w.x, w.y, cap: reg == .cap, sc)
                        }
                    }
                }
            case .cane:
                let nr = max(4, Int((c.d / 0.4).rounded()))
                for r in 0..<nr {
                    let b = -c.d / 2 + 0.15 + (Double(r) + 0.5) * (c.d - 0.3) / Double(nr), A = c.at(-c.w / 2 + 0.12, b), B = c.at(c.w / 2 - 0.12, b)
                    add((A.x + B.x) / 2, (A.y + B.y) / 2) { p in
                        let a = gp(A), b2 = gp(B)
                        var cane = Path()
                        cane.move(to: a)
                        for k in 0...10 {
                            let q = p.lp(a, b2, CGFloat(k) / 10)
                            cane.addLine(to: p.pt(q.x + CGFloat(sin(tt * 1.2 + Double(k + r))) * 1.2, q.y - 22 - CGFloat(k % 2) * 5))
                        }
                        cane.addLine(to: b2); cane.closeSubpath()
                        p.c.fill(cane, with: .color(p.hex("#5f8a3a"))); p.c.stroke(cane, with: .color(p.hex("#7aa84a")), lineWidth: 1)
                    }
                }
            case .palms:
                for (da, db, sc) in [(-0.32, -0.2, 1.0), (0.05, -0.32, 0.85), (0.34, 0.12, 1.1), (-0.05, 0.3, 0.9), (0.4, -0.3, 0.8)] {
                    let at = c.at(da * c.w, db * c.d)
                    add(at.x, at.y, shadow: { p in let w = gp(at); p.blobShadow(w.x + 14, w.y + 4, 16, 5, 0.12) }) { p in
                        let w = gp(at); p.palm(w.x, w.y, CGFloat(sc), tt: tt + da)
                    }
                }
            case .farm:
                let fx = c.cx - 0.45, fy = c.cy - 0.35
                add(fx, fy, depth: fx + 1.1 + fy + 0.7, shadow: { p in p.boxShadow(fx, fy, 0.9, 0.7, 40, 0.16) }) { p in p.farmHouse(fx, fy) }
            case .dovecote:
                add(c.cx, c.cy, shadow: { p in let q = TownGeo.iso(c.cx, c.cy); p.blobShadow(q.x + 50, q.y + 12, 60, 14, 0.14) }) { p in
                    let q = TownGeo.iso(c.cx, c.cy); p.dovecoteRock(q.x, q.y)
                }
                if day {
                    add(c.cx, c.cy, depth: 999) { p in
                        let q = TownGeo.iso(c.cx, c.cy); var d = DecorPainter(c: p.c); d.pigeons(CGPoint(x: q.x, y: q.y - 150), tt * 0.8, 0.32)
                    }
                }
            case .mesa:
                let mw = CGFloat(c.w + c.d) * 46, mh = 46 + CGFloat(c.d) * 22, seed = c.seed
                add(c.cx, c.cy, shadow: { p in let q = TownGeo.iso(c.cx, c.cy); p.blobShadow(q.x + mw * 0.28, q.y + 10, mw * 0.55, mw * 0.1, 0.14) }) { p in
                    let q = TownGeo.iso(c.cx, c.cy)
                    p.mesaRock(q.x, q.y, mw, mh, seed)
                    p.yucca(q.x - mw * 0.62, q.y + 12, 0.8); p.yucca(q.x + mw * 0.58, q.y + 12, 0.7)
                }
            case .scrub:
                for _ in 0..<5 {
                    let at = c.at((Rr.next() - 0.5) * c.w * 0.85, (Rr.next() - 0.5) * c.d * 0.8), ch = Rr.next() < 0.5, sc = CGFloat(0.6 + Rr.next() * 0.25)
                    add(at.x, at.y) { p in let w = gp(at); if ch { p.cholla(w.x, w.y, sc) } else { p.yucca(w.x, w.y, sc) } }
                }
            case .pasture:
                let n = 5 + c.seed % 3
                add(c.cx, c.cy) { p in let q = TownGeo.iso(c.cx + sin(tt * 0.05 + c.cx) * 0.3, c.cy); p.sheepFlock(q.x, q.y, n, tt * 0.5 + c.cx) }
                for (a, b) in [(-0.55, -0.55), (0.55, 0.55)] {
                    let at = c.at(a * c.w, b * c.d)
                    add(at.x, at.y) { p in let w = gp(at); p.oakTree(w.x, w.y, 0.7) }
                }
            case .crops:
                if reg == .lux && day { // the farmer and his donkey along the field's edge
                    let k = (sin(tt * 0.05 + c.cx) + 1) / 2, at = c.at((k - 0.5) * (c.w - 0.4), c.d / 2 + 0.25)
                    let dx: CGFloat = cos(tt * 0.05 + c.cx) * (c.ux - c.uy) > 0 ? 1 : -1
                    add(at.x, at.y) { p in
                        let q = gp(at), gray = p.hex("#8a8078")
                        p.ellipse(q.x - 10 * dx, q.y - 8, 7, 4, gray)
                        p.rect(q.x - 10 * dx + 4 * dx - 1, q.y - 15, 3, 7, gray)
                        for o: CGFloat in [-4, 3] { p.rect(q.x - 10 * dx + o, q.y - 5, 1.5, 5, p.hex("#5a5048")) }
                        p.person(q.x, q.y, "#f2ece0", tt * 0.3, 1)
                        var cap = Path()
                        cap.addArc(center: p.pt(q.x, q.y - 18.5), radius: 3.4, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
                        p.c.fill(cap, with: .color(p.hex("#f6f2ea")))
                    }
                }
            case .rv:
                let fiesta = s.local.fiesta != nil, n = fiesta ? 9 : 3, rcol = ["#ff5e3a", "#14a39a", "#9b7be0", "#ffc23d", "#5aa9e6"], lit = dark
                for i in 0..<n {
                    let a = Double(i % 3 - 1) * min(0.85, c.w * 0.3)
                    let b = Double(i / 3 - 1) * min(0.6, c.d * 0.3) + (n == 3 ? 0.6 * min(0.6, c.d * 0.3) : 0)
                    let at = c.at(a, b)
                    add(at.x, at.y) { p in let w = gp(at); p.rvCaravan(w.x, w.y, rcol[i % 5], lit: lit) }
                }
                if fiesta && dark {
                    let A = c.at(-c.w / 2 + 0.2, -c.d / 2 + 0.15), B = c.at(c.w / 2 - 0.2, -c.d / 2 + 0.15)
                    add(c.cx, c.cy) { p in
                        for i in 0...8 {
                            let f = Double(i) / 8, q = TownGeo.iso(A.x + (B.x - A.x) * f, A.y + (B.y - A.y) * f)
                            p.ellipse(q.x, q.y - 20 - CGFloat(sin(f * .pi)) * 4, 1.6, 1.6, p.hex("#ffe29a"))
                            p.nightLite(q.x, q.y - 20, 14, (255, 210, 130), 0.5)
                        }
                    }
                }
            case .view:
                add(c.cx, c.cy, depth: c.cx + c.cy - c.r) { p in
                    let k = p.viewKnoll(c)
                    guard day else { return }
                    let top = k.top
                    let tc = ["#ffc23d", "#14a39a", "#e04a3a", "#9b7be0", "#2b2350", "#ff8a3d"]
                    for i in 0..<9 {
                        let q = p.pt(top.x - 54 + CGFloat(i) * 13 + CGFloat(i % 2) * 4, top.y + 2 + CGFloat(i % 3) * 5)
                        if i % 3 == 1 { p.toaster(q.x, q.y, ["#ff6fa8", "#5aa9e6", "#ffc23d"][i % 3], tt * 0.6, Double(i)) }
                        else { p.tourist(q.x, q.y, tc[i % 6], hat: i % 2 == 1 ? "#f4e4c0" : nil, camera: i % 4 == 0, tt * 0.05, Double(i)) }
                    }
                    for (dx, col) in [(k.rx * 0.62, "#e8e2d8"), (k.rx * 0.84, "#c0392b")] {
                        let q = p.pt(top.x + dx, top.y + k.ry * 0.9 + 18)
                        p.ellipse(q.x + 6, q.y + 2, 14, 4, p.rgba(90, 45, 20, 0.18))
                        p.c.fill(Path(roundedRect: CGRect(x: q.x - 11, y: q.y - 10, width: 22, height: 9), cornerRadius: 3), with: .color(p.hex(col)))
                        p.rect(q.x - 6, q.y - 14, 11, 5, p.hex("#6a8aa6"))
                        p.ellipse(q.x - 6, q.y - 1, 2.4, 2.4, p.hex("#2a1e18")); p.ellipse(q.x + 6, q.y - 1, 2.4, 2.4, p.hex("#2a1e18"))
                    }
                }
            case .vine, .rival, nil: break
            }
        }
        // trees along the tracks
        for tr in L.trees {
            let k = CGFloat(tr.k), kind = tr.kind
            add(tr.x, tr.y, shadow: { p in let q = TownGeo.iso(tr.x, tr.y); p.blobShadow(q.x + 10 * k, q.y + 3, 11 * k, 3.5 * k, 0.13) }) { p in
                let q = TownGeo.iso(tr.x, tr.y); p.outTrackTree(q.x, q.y, k, kind)
            }
        }
        // the ATV tour and the riders, slowly round their loops
        if day {
            for (li, l) in L.loops.enumerated() {
                let atv = li == 0 && reg != .bri && reg != .lux, n = atv ? 5 : 3, sp = atv ? 0.45 : 0.16
                for i in 0..<n {
                    let raw = tt * sp - Double(i) * (atv ? 0.55 : 0.5) + Double(li) * 3
                    let sAlong = (raw.truncatingRemainder(dividingBy: l.len) + l.len).truncatingRemainder(dividingBy: l.len)
                    let r = OutskirtsLayout.walk(l.P, sAlong), gx = r.p.x, gy = r.p.y
                    let dd = r.dir.x - r.dir.y, dxs: CGFloat = dd > 0 ? 1 : dd < 0 ? -1 : 1
                    add(gx, gy) { p in
                        let q = TownGeo.iso(gx, gy)
                        if atv {
                            p.quadBike(q.x, q.y, i == 0 ? "#2b2350" : ["#ff5e3a", "#ffc23d", "#14a39a", "#5aa9e6"][i % 4], Double(i), dxs)
                            for k in 1..<4 {
                                let b = gp(OutskirtsLayout.walk(l.P, max(0, sAlong - Double(k) * 0.12)).p), kk = CGFloat(k)
                                p.ellipse(b.x, b.y - 4 - kk * 2, 3 + kk * 2.2, 3 + kk * 2.2, p.rgba(230, 200, 160, 0.32 - Double(k) * 0.08))
                            }
                        } else {
                            p.rider(q.x, q.y, Double(i + li * 2), dxs, ["#c0392b", "#2b5a7a", "#e8c070"][i % 3])
                        }
                    }
                }
            }
        }
        // Luxor: a felucca tacking slowly on the Nile, out on the right flank
        if reg == .lux && day {
            let k = (sin(tt * 0.025) + 1) / 2, gx = 11 + k * 9, gy = -12.3
            add(gx, gy) { p in
                let q = TownGeo.iso(gx, gy), dir: CGFloat = cos(tt * 0.025) > 0 ? 1 : -1
                p.ellipse(q.x, q.y, 22, 4, Color.white.opacity(0.25))
                p.poly([p.pt(q.x - 20, q.y - 6), p.pt(q.x + 20, q.y - 6), p.pt(q.x + 13, q.y), p.pt(q.x - 14, q.y)], p.hex("#7a5030"))
                p.line(p.pt(q.x - 2, q.y - 6), p.pt(q.x - 2, q.y - 44), p.hex("#5a3a20"), 1.6)
                var sail = Path()
                sail.move(to: p.pt(q.x - 2 + dir * 22, q.y - 58))
                sail.addQuadCurve(to: p.pt(q.x - 2 - dir * 20, q.y - 9), control: p.pt(q.x + dir * 14, q.y - 30))
                sail.addLine(to: p.pt(q.x - 2, q.y - 10)); sail.closeSubpath()
                p.c.fill(sail, with: .color(p.hex("#fbf8f0")))
                p.poly([p.pt(q.x - 2, q.y - 44), p.pt(q.x - 2, q.y - 10), p.pt(q.x - 2 - dir * 20, q.y - 9)], p.rgba(160, 140, 110, 0.2))
            }
        }
        return items
    }
}
