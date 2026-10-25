import SwiftUI
import BalloonBaronCore

/// Where the town is on screen: zoom and the screen position of world (0, 0).
struct TownViewport {
    var z: CGFloat
    var ox: CGFloat
    var oy: CGFloat
    /// A horizon set by the camera (the night's big sky) instead of the one the town's position gives.
    var hzFix: CGFloat? = nil
    /// Draw no building names (tap targets still come back).
    var noLabels = false
    /// Zoomed in, the horizon never comes down past where the home screen had it, so the sky doesn't grow.
    var hzCap: CGFloat? = nil

    func screen(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * z + ox, y: p.y * z + oy) }
}

/// Tap targets the painter leaves behind, in the canvas's coordinates.
struct TownHits {
    struct Building {
        var b: TownBuilding
        var pts: [CGPoint]
        var box: CGRect
        var depth: Double
    }
    struct Zone {
        var zone: TownZone
        var pts: [CGPoint]
    }
    var buildings: [Building] = []
    var zones: [Zone] = []
    /// The launch field and the balloons standing on it (v110): a tap there opens your balloons.
    var field: [[CGPoint]] = []

    func onField(_ p: CGPoint) -> Bool { field.contains { TownGeo.inPoly(p, $0) } }

    /// The zone written under the finger (only while zoomed out), else the front-most building.
    func hit(_ p: CGPoint) -> (zone: TownZone?, building: TownBuilding?) {
        if let z = zones.first(where: { TownGeo.inPoly(p, $0.pts) }) { return (z.zone, nil) }
        // A footprint under the finger wins first (front-most first); only then the boxes round the name tags.
        let list = buildings.sorted { $0.depth > $1.depth }
        let b = list.first(where: { TownGeo.inPoly(p, $0.pts) }) ?? list.first(where: { $0.box.contains(p) })
        return (nil, b?.b)
    }
}

/// Isometric grid math shared by the painter and the views.
enum TownGeo {
    static let TW: CGFloat = 128, TH: CGFloat = 64
    /// Building names appear from this zoom; below it the zones written in the sand do the talking.
    static let labelZoom: CGFloat = 0.55

    static func iso(_ gx: Double, _ gy: Double) -> CGPoint {
        CGPoint(x: CGFloat(gx - gy) * TW / 2, y: CGFloat(gx + gy) * TH / 2)
    }

    static func inPoly(_ p: CGPoint, _ pts: [CGPoint]) -> Bool {
        var c = false
        var j = pts.count - 1
        for i in pts.indices {
            let a = pts[i], b = pts[j]
            if (a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { c.toggle() }
            j = i
        }
        return c
    }

    /// Horizon on screen: a little above the town's far corner, never below 60 % of the height.
    static func horizon(_ v: TownViewport, height h: CGFloat) -> CGFloat {
        if let f = v.hzFix { return f }
        return min(h * 0.6, v.oy + iso(-7, -7).y * v.z, v.hzCap ?? .infinity)
    }
}

/// One thing standing on the ground, drawn back to front.
struct TownItem {
    var depth: Double
    /// Ground point, for things outside the town that fade into the haze.
    var at: (Double, Double)?
    var shadow: ((inout TownPainter) -> Void)?
    var draw: (inout TownPainter) -> Void
}

/// A stone box's corners at the ground (A–D) and at the top (a–d).
struct Box {
    var A: CGPoint, B: CGPoint, C: CGPoint, D: CGPoint
    var a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint
}

/// Port of the prototype's company town drawing (`renderTown`): sunrise backdrop, the valley, the walled town
/// with its buildings and four hotels of rising grandeur, zones written in the sand, and building labels.
/// Light comes from the left: faces toward +gy are lit, faces toward +gx are in shade, shadows fall right.
struct TownPainter {
    var c: GraphicsContext
    let s: GameState
    let t: Double
    let v: TownViewport
    let size: CGSize
    /// Set while the night falls between two days.
    var night: TownNight? = nil
    /// Windows and doors drawn this frame, lit again over the dark.
    var windows: [NightWindow] = []
    /// Passengers queueing at your office and the jeeps, while they gather.
    var collect: CollectScene? = nil
    /// Pilots on strike outside your office (a morning event).
    var strike = false

    static let tuffLit = "#f1d6b0", tuffShade = "#b9825c", tuffTop = "#f8e4c4"
    static let sunShadow = CGSize(width: 0.55, height: 0.2)

    /// Wall stone of the town, per region: Cappadocia's tuff, Albuquerque's smooth adobe, Luxor's mudbrick and limewash.
    struct Tuff {
        var lit: String, shade: String, top: String
        var line: Color
        /// Plastered smooth: no stone courses.
        var smooth = false
    }

    static func tuff(_ r: RegionID) -> Tuff {
        switch r {
        case .cap: return Tuff(lit: tuffLit, shade: tuffShade, top: tuffTop, line: Color(red: 110 / 255, green: 60 / 255, blue: 30 / 255).opacity(0.16))
        case .abq: return Tuff(lit: "#dfa676", shade: "#a6653e", top: "#d79a68", line: Color(red: 120 / 255, green: 60 / 255, blue: 25 / 255).opacity(0.10), smooth: true)
        case .lux: return Tuff(lit: "#f3e8d2", shade: "#c4ab80", top: "#ece0c4", line: Color(red: 130 / 255, green: 100 / 255, blue: 60 / 255).opacity(0.14))
        }
    }

    var tuff: Tuff { Self.tuff(s.region) }

    // MARK: Entry point

    /// Draws everything and returns the tap targets.
    static func render(_ ctx: inout GraphicsContext, state: GameState, time: Double, viewport: TownViewport, size: CGSize,
                       night: TownNight? = nil, collect: CollectScene? = nil, strike: Bool = false) -> TownHits {
        var p = TownPainter(c: ctx, s: state, t: time, v: viewport, size: size, night: night, collect: collect, strike: strike)
        return p.renderAll()
    }

    mutating func renderAll() -> TownHits {
        let w = size.width, h = size.height
        let screen = c
        backdrop(w, h)
        let hz = ground(w, h)
        // Flat things on the ground, clipped at the horizon.
        var flat = screen
        flat.clip(to: Path(CGRect(x: 0, y: hz, width: w, height: max(0, h - hz))))
        flat.concatenate(worldTransform)
        c = flat
        outerDecor()
        let E = [iso(-0.5, -0.5), iso(15.5, -0.5), iso(15.5, 15.5), iso(-0.5, 15.5)]
        poly(E, rgba(240, 210, 165, 0.55))
        townDecor()
        zoneText()
        c = screen
        haze(w, h)
        var world = screen
        world.concatenate(worldTransform)
        c = world
        let bs = Town.buildings(s)
        let vz = v.z, voy = v.oy
        let fade: (TownItem) -> TownItem? = { it in
            guard let at = it.at else { return it }
            let sy = TownGeo.iso(at.0, at.1).y * vz + voy
            let a = min(max((sy - hz) / (h * 0.1), 0), 1)
            if a <= 0 { return nil }
            var out = it
            out.draw = { p in
                let keep = p.c
                p.c.opacity = Double(a)
                it.draw(&p)
                p.c = keep
            }
            return out
        }
        let scen = scenery() + outerScenery().compactMap(fade) + townWall()
        let sky = skyBalloons()
        for b in bs { buildingShadow(b) }
        for it in scen { it.shadow?(&self) }
        for f in sky.shadows { f(&self) }
        var items = bs.map { b in TownItem(depth: b.gx + b.w + b.gy + b.d - 0.5, draw: { p in p.building(b) }) }
        items += scen
        if let sc = collect { items += collectItems(sc) }
        if strike { items += strikers() }
        for it in items.sorted(by: { $0.depth < $1.depth }) { it.draw(&self) }
        for f in sky.balloons { f(&self) }
        if night != nil { nightLayer(screen: screen, world: world, hz: hz) }
        if let n = night, n.sunrise > 0 { sunriseLayer(screen: screen, hz: hz, amount: n.sunrise) }
        c = screen
        if s.local.winter != nil { snowfall(w, h) }
        return labels(bs)
    }

    private var worldTransform: CGAffineTransform {
        CGAffineTransform(a: v.z, b: 0, c: 0, d: v.z, tx: v.ox, ty: v.oy)
    }

    // MARK: Helpers

    func iso(_ gx: Double, _ gy: Double) -> CGPoint { TownGeo.iso(gx, gy) }
    func lp(_ p: CGPoint, _ q: CGPoint, _ k: CGFloat) -> CGPoint { CGPoint(x: p.x + (q.x - p.x) * k, y: p.y + (q.y - p.y) * k) }
    func upp(_ p: CGPoint, _ h: CGFloat) -> CGPoint { CGPoint(x: p.x, y: p.y - h) }
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    func hex(_ h: String) -> Color { Color(hex: h) }
    func mix(_ a: String, _ b: String, _ k: Double) -> Color { ScenePainter.mix(a, b, k) }
    func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255).opacity(a)
    }

    func path(_ pts: [CGPoint]) -> Path {
        var p = Path()
        guard let f = pts.first else { return p }
        p.move(to: f)
        for q in pts.dropFirst() { p.addLine(to: q) }
        p.closeSubpath()
        return p
    }

    mutating func poly(_ pts: [CGPoint], _ col: Color) { c.fill(path(pts), with: .color(col)) }
    mutating func polyShade(_ pts: [CGPoint], _ sh: GraphicsContext.Shading) { c.fill(path(pts), with: sh) }
    mutating func outline(_ pts: [CGPoint], _ col: Color, _ lw: CGFloat) {
        c.stroke(path(pts), with: .color(col), lineWidth: lw)
    }
    mutating func line(_ a: CGPoint, _ b: CGPoint, _ col: Color, _ lw: CGFloat) {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        c.stroke(p, with: .color(col), lineWidth: lw)
    }
    mutating func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: Color) {
        c.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(col))
    }
    mutating func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ col: Color) {
        c.fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), with: .color(col))
    }
    func grad(_ stops: [(Color, CGFloat)]) -> Gradient {
        Gradient(stops: stops.map { Gradient.Stop(color: $0.0, location: $0.1) })
    }
    /// Additive glow, like canvas 'lighter'.
    mutating func glow(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ col: Color, _ a: Double) {
        var g = c
        g.blendMode = .plusLighter
        let gr = grad([(col.opacity(a), 0), (col.opacity(0), 1)])
        g.fill(Path(CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
               with: .radialGradient(gr, center: pt(x, y), startRadius: 0, endRadius: r))
    }
    mutating func text(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, color: Color, font: String = "BarlowCondensed-ExtraBold") {
        c.draw(Text(s).font(.custom(font, fixedSize: size)).foregroundColor(color), at: pt(x, y), anchor: .center)
    }

    func rng(_ seed: Double) -> Mulberry32 { Mulberry32(seed: UInt32(truncatingIfNeeded: Int(seed.rounded()))) }

    /// Draw on a face: unit square mapped onto the parallelogram p→q (bottom edge) raised by h.
    func face(_ p: CGPoint, _ q: CGPoint, _ h: CGFloat) -> GraphicsContext {
        var f = c
        f.concatenate(CGAffineTransform(a: q.x - p.x, b: q.y - p.y, c: 0, d: -h, tx: p.x, ty: p.y))
        return f
    }

    // MARK: Stone

    /// A textured stone wall: base color, stone courses, specks and darkening near the ground.
    mutating func stoneWall(_ p: CGPoint, _ q: CGPoint, _ h: CGFloat, _ col: String, seed: Double, courses coursesIn: Bool) {
        let T = tuff
        let courses = coursesIn && !T.smooth // adobe is plastered smooth
        let wall = path([p, q, upp(q, h), upp(p, h)])
        c.fill(wall, with: .color(hex(col)))
        var w = c
        w.clip(to: wall)
        var R = rng(seed)
        let len = hypot(q.x - p.x, q.y - p.y)
        if courses && len > 1 {
            var lines = Path()
            var y: CGFloat = 14, row = 0
            while y < h {
                lines.move(to: pt(p.x, p.y - y)); lines.addLine(to: pt(q.x, q.y - y))
                var u = CGFloat(row % 2) * 0.5 / max(1, len / 26)
                while u < 1 {
                    let a = lp(p, q, u)
                    lines.move(to: pt(a.x, a.y - y)); lines.addLine(to: pt(a.x, a.y - y + 14))
                    u += 26 / len
                }
                y += 14; row += 1
            }
            w.stroke(lines, with: .color(T.line), lineWidth: 1)
        }
        var light = Path(), dark = Path()
        let n = Int(len * h / 260)
        for _ in 0..<max(0, n) {
            let a = lp(p, q, CGFloat(R.next())), y = CGFloat(R.next()) * h
            let isLight = R.next() < 0.5
            let r = CGRect(x: a.x, y: a.y - y, width: 2 + CGFloat(R.next()) * 3, height: 2)
            if isLight { light.addRect(r) } else { dark.addRect(r) }
        }
        w.fill(light, with: .color(rgba(255, 245, 225, 0.18)))
        w.fill(dark, with: .color(rgba(90, 45, 20, 0.12)))
        let top = min(p.y, q.y) - h, bottom = max(p.y, q.y)
        let g = grad([(rgba(255, 240, 215, 0.10), 0), (rgba(0, 0, 0, 0), 0.75), (rgba(70, 30, 15, 0.28), 1)])
        w.fill(Path(CGRect(x: min(p.x, q.x) - 2, y: top - 2, width: abs(q.x - p.x) + 4, height: bottom - top + 4)),
               with: .linearGradient(g, startPoint: pt(0, top), endPoint: pt(0, bottom)))
    }

    func corners(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double) -> (CGPoint, CGPoint, CGPoint, CGPoint) {
        (iso(gx, gy), iso(gx + w, gy), iso(gx + w, gy + d), iso(gx, gy + d))
    }

    /// A stone block: lit left wall, shaded right wall, top, optional parapet.
    @discardableResult
    mutating func block(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat,
                                lit litIn: String? = nil, shade shadeIn: String? = nil, top topIn: String? = nil,
                                courses: Bool = true, parapet: Bool = false, roofIn: String = "#e8cba3", seed: Double? = nil) -> Box {
        let T = tuff
        let lit = litIn ?? T.lit, shade = shadeIn ?? T.shade, top = topIn ?? T.top
        let (A, B, C, D) = corners(gx, gy, w, d)
        let sd = seed ?? (gx * 31 + gy * 17).rounded()
        stoneWall(D, C, h, lit, seed: sd, courses: courses)
        stoneWall(C, B, h, shade, seed: sd + 1, courses: courses)
        let a = upp(A, h), b = upp(B, h), cc = upp(C, h), dd = upp(D, h)
        poly([a, b, cc, dd], hex(s.local.winter != nil ? "#f6f9fc" : top))
        if parapet {
            let k: CGFloat = 0.06
            poly([lp(a, cc, k), lp(b, dd, k), lp(a, cc, 1 - k), lp(b, dd, 1 - k)], hex(roofIn))
        }
        return Box(A: A, B: B, C: C, D: D, a: a, b: b, c: cc, d: dd)
    }

    /// Arched window or door on a face, in face units (u along the wall, v up). Lit windows glow.
    mutating func opening(_ p: CGPoint, _ q: CGPoint, _ h: CGFloat, _ u: CGFloat, _ v: CGFloat, _ w: CGFloat, _ hh: CGFloat,
                                  door: Bool = false, lit: Bool = false) {
        var f = face(p, q, h)
        let x0 = u - w / 2
        var arch = Path()
        arch.move(to: pt(x0, v))
        arch.addLine(to: pt(x0, v + hh - w / 2))
        arch.addQuadCurve(to: pt(x0 + w, v + hh - w / 2), control: pt(u, v + hh + w * 0.45))
        arch.addLine(to: pt(x0 + w, v))
        arch.closeSubpath()
        f.fill(arch, with: .color(hex(door ? "#5a3418" : lit ? "#ffd27a" : "#3a2018")))
        if night != nil { windows.append(NightWindow(p: p, q: q, h: h, u: u, v: v, w: w, hh: hh, door: door)) }
        if door {
            f.fill(Path(CGRect(x: x0 + w * 0.1, y: v, width: w * 0.35, height: hh * 0.8)), with: .color(hex("#7a4a24")))
            f.fill(Path(CGRect(x: x0 + w * 0.55, y: v, width: w * 0.35, height: hh * 0.8)), with: .color(hex("#7a4a24")))
        }
        if lit {
            let m = lp(p, q, u)
            glow(m.x, m.y - h * (v + hh / 2), 24, Color(red: 1, green: 190 / 255, blue: 90 / 255), 0.16)
        }
    }

    /// A glass panel in a face, in face units, with wooden mullions.
    mutating func glass(_ p: CGPoint, _ q: CGPoint, _ h: CGFloat, _ u0: CGFloat, _ u1: CGFloat, _ v0: CGFloat, _ v1: CGFloat, lit: Bool) {
        var f = face(p, q, h)
        let g = grad([(hex(lit ? "#ffcf7a" : "#6a8aa8"), 0), (hex(lit ? "#ffe8b0" : "#a9c6dc"), 1)])
        f.fill(Path(CGRect(x: u0, y: v0, width: u1 - u0, height: v1 - v0)), with: .linearGradient(g, startPoint: pt(0, v0), endPoint: pt(0, v1)))
        let n = max(2, Int(((u1 - u0) / 0.14).rounded()))
        var frame = Path()
        for i in 0...n { frame.addRect(CGRect(x: u0 + (u1 - u0) * CGFloat(i) / CGFloat(n) - 0.008, y: v0, width: 0.016, height: v1 - v0)) }
        frame.addRect(CGRect(x: u0, y: v0, width: u1 - u0, height: 0.03))
        frame.addRect(CGRect(x: u0, y: v1 - 0.03, width: u1 - u0, height: 0.03))
        f.fill(frame, with: .color(hex("#6a4024")))
    }

    // MARK: Roofs

    /// Outside Cappadocia roofs are flat: a parapet round the top. Albuquerque's adobe shows its vigas (round roof beams)
    /// under the parapet; Luxor's houses get a small limewashed dome.
    mutating func flatRoof(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, dome withDome: Bool) {
        let (A, B, C, D) = corners(gx, gy, w, d), ph: CGFloat = 8, T = tuff
        poly([upp(D, h), upp(C, h), upp(C, h + ph), upp(D, h + ph)], hex(T.lit))
        poly([upp(C, h), upp(B, h), upp(B, h + ph), upp(C, h + ph)], hex(T.shade))
        let top = [upp(A, h + ph), upp(B, h + ph), upp(C, h + ph), upp(D, h + ph)]
        poly(top, hex(T.top))
        let k: CGFloat = 0.1
        poly([lp(top[0], top[2], k), lp(top[1], top[3], k), lp(top[0], top[2], 1 - k), lp(top[1], top[3], 1 - k)], mix(T.top, "#5a3a20", 0.14))
        if s.region == .abq {
            for (p, q) in [(D, C), (C, B)] {
                for i in 1..<6 {
                    let m = lp(p, q, CGFloat(i) / 6)
                    ellipse(m.x + 1.5, m.y - h + 3, 2.6, 2, hex("#5a3418"))
                    ellipse(m.x + 0.8, m.y - h + 2.6, 1.4, 1, hex("#8a5a34"))
                }
            }
        }
        if s.region == .lux && withDome {
            let cc = lp(lp(top[0], top[2], 0.5), lp(top[1], top[3], 0.5), 0.5), r = CGFloat(min(w, d)) * TownGeo.TW * 0.16
            let n = 14
            var dm = Path()
            for i in 0...n { // the rim (lower half of a flat ellipse), then the half sphere over it
                let a = Double.pi * Double(i) / Double(n)
                let q = pt(cc.x + r * CGFloat(cos(a)), cc.y + r * 0.45 * CGFloat(sin(a)))
                if i == 0 { dm.move(to: q) } else { dm.addLine(to: q) }
            }
            for i in 0...n {
                let a = Double.pi + Double.pi * Double(i) / Double(n)
                dm.addLine(to: pt(cc.x + r * CGFloat(cos(a)), cc.y + r * CGFloat(sin(a))))
            }
            dm.closeSubpath()
            c.fill(dm, with: .color(hex("#f8f2e4")))
            var sh = Path()
            for i in 0...n {
                let a = -Double.pi / 2 + Double.pi * Double(i) / Double(n)
                let q = pt(cc.x + r * 0.3 + r * 0.55 * CGFloat(cos(a)), cc.y - r * 0.1 + r * 0.9 * CGFloat(sin(a)))
                if i == 0 { sh.move(to: q) } else { sh.addLine(to: q) }
            }
            sh.closeSubpath()
            c.fill(sh, with: .color(rgba(160, 130, 90, 0.35)))
        }
    }

    /// Gable roof with the ridge along gx, tiles drawn as lines.
    mutating func gableRoof(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, _ rise: CGFloat, _ colIn: String, eave: Double = 0.08) {
        if s.region != .cap { flatRoof(gx, gy, w, d, h, dome: false); return }
        let col = snowy(colIn)
        let x0 = gx - eave, x1 = gx + w + eave, y0 = gy - eave, y1 = gy + d + eave, ym = gy + d / 2
        let P = { (x: Double, y: Double, z: CGFloat) -> CGPoint in CGPoint(x: TownGeo.iso(x, y).x, y: TownGeo.iso(x, y).y - z) }
        poly([P(x0, y0, h), P(x1, y0, h), P(x1, ym, h + rise), P(x0, ym, h + rise)], mix(col, "#000000", 0.3))
        let front = [P(x0, y1, h), P(x1, y1, h), P(x1, ym, h + rise), P(x0, ym, h + rise)]
        poly(front, hex(col))
        var tiles = Path()
        for k in 1..<10 {
            let kk = CGFloat(k) / 10
            tiles.move(to: lp(front[0], front[1], kk)); tiles.addLine(to: lp(front[3], front[2], kk))
        }
        for k in 1..<4 {
            let kk = CGFloat(k) / 4
            tiles.move(to: lp(front[0], front[3], kk)); tiles.addLine(to: lp(front[1], front[2], kk))
        }
        c.stroke(tiles, with: .color(rgba(80, 25, 10, 0.35)), lineWidth: 1.2)
        poly([P(gx + w, gy, h), P(gx + w, gy + d, h), P(gx + w, ym, h + rise)], mix(Self.tuffShade, "#000000", 0.05))
        line(P(x0, ym, h + rise), P(x1, ym, h + rise), mix(col, "#ffffff", 0.25), 2.5)
    }

    /// Hip roof (four slopes) for the konak.
    mutating func hipRoof(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, _ rise: CGFloat, _ colIn: String) {
        if s.region != .cap { flatRoof(gx, gy, w, d, h, dome: true); return }
        let col = snowy(colIn)
        let e = 0.1
        let P = { (x: Double, y: Double, z: CGFloat) -> CGPoint in CGPoint(x: TownGeo.iso(x, y).x, y: TownGeo.iso(x, y).y - z) }
        let A = P(gx - e, gy - e, h), B = P(gx + w + e, gy - e, h), C = P(gx + w + e, gy + d + e, h), D = P(gx - e, gy + d + e, h)
        let R0 = P(gx + w * 0.35, gy + d / 2, h + rise), R1 = P(gx + w * 0.65, gy + d / 2, h + rise)
        poly([A, B, R1, R0], mix(col, "#000000", 0.3))
        poly([D, A, R0], mix(col, "#000000", 0.1))
        poly([D, C, R1, R0], hex(col))
        poly([C, B, R1], mix(col, "#000000", 0.25))
        var tiles = Path()
        for k in 1..<8 {
            let kk = CGFloat(k) / 8
            tiles.move(to: lp(D, C, kk)); tiles.addLine(to: lp(R0, R1, kk))
        }
        c.stroke(tiles, with: .color(rgba(80, 25, 10, 0.3)), lineWidth: 1.1)
    }

    mutating func dome(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ col: String) {
        var p = Path()
        let n = 16
        for i in 0...n {
            let a = Double.pi * Double(i) / Double(n)
            let q = pt(cx + r * CGFloat(cos(a)), cy + r * 0.5 * CGFloat(sin(a)))
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        for i in 0...n {
            let a = Double.pi + Double.pi * Double(i) / Double(n)
            p.addLine(to: pt(cx + r * CGFloat(cos(a)), cy + r * CGFloat(sin(a))))
        }
        p.closeSubpath()
        let g = grad([(mix(col, "#ffffff", 0.55), 0), (mix(col, "#000000", 0.35), 1)])
        c.fill(p, with: .radialGradient(g, center: pt(cx - r * 0.4, cy - r * 0.5), startRadius: r * 0.1, endRadius: r * 1.6))
        rect(cx - 2, cy - r - 18, 4, 18, hex("#ffc23d"))
        ellipse(cx, cy - r - 20, 5, 5, hex("#ffc23d"))
    }

    // MARK: Props

    mutating func cypress(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat = 1) {
        let g = grad([(hex("#4f7a3a"), 0), (hex("#22401e"), 1)])
        c.fill(Path(ellipseIn: CGRect(x: x - 9 * k, y: y - 68 * k, width: 18 * k, height: 68 * k)),
               with: .linearGradient(g, startPoint: pt(x - 8 * k, 0), endPoint: pt(x + 8 * k, 0)))
    }

    mutating func roundTree(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat = 1, _ col: String = "#6f9a48") {
        rect(x - 2 * k, y - 16 * k, 4 * k, 16 * k, hex("#5a3a20"))
        let g = grad([(mix(col, "#ffffff", 0.25), 0), (mix(col, "#000000", 0.3), 1)])
        c.fill(Path(ellipseIn: CGRect(x: x - 16 * k, y: y - 42 * k, width: 32 * k, height: 32 * k)),
               with: .radialGradient(g, center: pt(x - 6 * k, y - 30 * k), startRadius: 2, endRadius: 22 * k))
    }

    mutating func palm(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat = 1, tt ttIn: Double? = nil) {
        let tt = ttIn ?? t
        var trunk = Path()
        trunk.move(to: pt(x, y))
        trunk.addQuadCurve(to: pt(x + 2 * k, y - 56 * k), control: pt(x + 6 * k, y - 30 * k))
        c.stroke(trunk, with: .color(hex("#8a6a40")), lineWidth: 4 * k)
        var fronds = Path()
        for i in 0..<7 {
            let a = -Double.pi / 2 + Double(i - 3) * 0.55 + sin(tt * 1.5 + Double(i)) * 0.04
            let ca = CGFloat(cos(a)), sa = CGFloat(sin(a))
            fronds.move(to: pt(x + 2 * k, y - 56 * k))
            fronds.addQuadCurve(to: pt(x + 2 * k + ca * 30 * k, y - 50 * k + sa * 18 * k + 10 * k),
                                control: pt(x + 2 * k + ca * 16 * k, y - 64 * k + sa * 10 * k))
        }
        c.stroke(fronds, with: .color(hex("#3f7a3a")), style: StrokeStyle(lineWidth: 3.5 * k, lineCap: .round))
    }

    /// A garden tree by a hotel: cypress in Cappadocia, cottonwood in Albuquerque, date palm in Luxor.
    mutating func hotelTree(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat) {
        switch s.region {
        case .abq: roundTree(x, y, k * 0.9, "#9aa84a")
        case .lux: palm(x, y, k * 0.9)
        case .cap: cypress(x, y, k)
        }
    }

    /// Town trees outside Cappadocia: cottonwoods, cholla and yucca in Albuquerque; date palms in Luxor.
    mutating func regionTree(_ x: CGFloat, _ y: CGFloat, _ i: Int) {
        if s.region == .lux { palm(x, y, 0.9 + CGFloat(i % 3) * 0.12, tt: t + Double(i)); return }
        if i % 3 == 0 { cholla(x, y, 0.9); return }
        if i % 3 == 1 { yucca(x, y, 0.9); return }
        roundTree(x, y, 1.05, i % 2 == 1 ? "#a8b050" : "#9aa84a")
    }

    mutating func cholla(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat) {
        let arms: [(Double, Double, CGFloat)] = [(0, 30, 5), (-0.6, 16, 3.5), (0.7, 18, 3.5), (-0.2, 10, 3)]
        for (a, l, w) in arms {
            let bx = x + CGFloat(a) * 4 * k, by = y - (a != 0 ? 16 : 0) * k
            var p = Path()
            p.move(to: pt(bx, by))
            p.addLine(to: pt(bx + CGFloat(sin(a) * l) * k, by - CGFloat(cos(a) * l) * k))
            c.stroke(p, with: .color(hex("#5a7a3a")), style: StrokeStyle(lineWidth: w * k, lineCap: .round))
        }
        ellipse(x, y - 30 * k, 2.5 * k, 2.5 * k, hex("#ff6fa8"))
    }

    mutating func yucca(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat) {
        var leaves = Path()
        for i in 0..<9 {
            let a = -Double.pi / 2 + Double(i - 4) * 0.3
            leaves.move(to: pt(x - 1.5 * k, y))
            leaves.addLine(to: pt(x + CGFloat(cos(a)) * 18 * k, y + CGFloat(sin(a)) * 18 * k))
            leaves.addLine(to: pt(x + 1.5 * k, y))
            leaves.closeSubpath()
        }
        c.fill(leaves, with: .color(hex("#6a8a4a")))
        line(pt(x, y - 14 * k), pt(x, y - 34 * k), hex("#8a7a50"), 1.5 * k)
        for j in 0..<4 {
            ellipse(x + (j % 2 == 1 ? 2 : -2) * k, y - (26 + CGFloat(j) * 2.5) * k, 2 * k, 2 * k, hex("#f6f0d8"))
        }
    }

    /// A granite obelisk on a small base.
    mutating func obelisk(_ x: CGFloat, _ y: CGFloat, _ h: CGFloat) {
        rect(x - 10, y - 8, 20, 8, hex("#d8b48a"))
        poly([pt(x - 6, y - 8), pt(x - 4, y - h), pt(x, y - h - 8), pt(x + 4, y - h), pt(x + 6, y - 8)], hex("#e8c89c"))
        poly([pt(x, y - h - 8), pt(x + 4, y - h), pt(x + 6, y - 8), pt(x + 1, y - 8)], hex("#c09a6c"))
        poly([pt(x - 4, y - h), pt(x, y - h - 8), pt(x + 4, y - h)], hex("#ffd27a"))
    }

    /// A red sandstone butte: flat top, banded sides.
    mutating func butte(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ lit: String, _ shade: String) {
        poly([pt(x - w * 0.55, y), pt(x - w * 0.42, y - h), pt(x + w * 0.42, y - h), pt(x + w * 0.55, y)], hex(shade))
        poly([pt(x - w * 0.55, y), pt(x - w * 0.42, y - h), pt(x + w * 0.05, y - h), pt(x + w * 0.1, y)], hex(lit))
        for i in 1..<4 {
            let fi = CGFloat(i)
            rect(x - w * 0.5 + fi * 2, y - h * fi / 4, w - fi * 4, 2, rgba(255, 230, 190, 0.25))
        }
        rect(x - w * 0.42, y - h - 3, w * 0.84, 4, mix(lit, "#ffffff", 0.2))
    }

    /// A temple front: two pylons and a row of columns under a lintel (Luxor).
    mutating func temple(_ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat, _ colHex: String) {
        let col = hex(colHex)
        poly([pt(x - w / 2, base), pt(x - w * 0.44, base - hgt), pt(x - w * 0.2, base - hgt), pt(x - w * 0.16, base)], col)
        poly([pt(x + w / 2, base), pt(x + w * 0.44, base - hgt), pt(x + w * 0.2, base - hgt), pt(x + w * 0.16, base)], col)
        for i in 0..<3 { rect(x - w * 0.12 + CGFloat(i) * w * 0.1 - w * 0.02, base - hgt * 0.7, w * 0.04, hgt * 0.7, col) }
        rect(x - w * 0.16, base - hgt * 0.76, w * 0.32, hgt * 0.08, col)
    }

    /// A palm in silhouette for Luxor's far bank.
    mutating func palmSil(_ x: CGFloat, _ y: CGFloat, _ h: CGFloat, _ col: Color) {
        var trunk = Path()
        trunk.move(to: pt(x, y))
        trunk.addQuadCurve(to: pt(x + h * 0.04, y - h), control: pt(x + h * 0.1, y - h * 0.5))
        c.stroke(trunk, with: .color(col), lineWidth: max(1.5, h * 0.06))
        var fronds = Path()
        for i in 0..<6 {
            let a = -Double.pi / 2 + (Double(i) - 2.5) * 0.6, ca = CGFloat(cos(a)), sa = CGFloat(sin(a))
            fronds.move(to: pt(x + h * 0.04, y - h))
            fronds.addQuadCurve(to: pt(x + h * 0.04 + ca * h * 0.45, y - h * 0.85 + sa * h * 0.25),
                                control: pt(x + h * 0.04 + ca * h * 0.25, y - h * 1.1 + sa * h * 0.15))
        }
        c.stroke(fronds, with: .color(col), style: StrokeStyle(lineWidth: max(1.2, h * 0.05), lineCap: .round))
    }

    /// What stands on the town's edges: Cappadocia's fairy chimneys, Luxor's palm clumps and an obelisk.
    /// Albuquerque leaves those spots empty.
    mutating func edgeLandmark(_ x: CGFloat, _ y: CGFloat, _ hh: CGFloat, _ seed: Double) {
        switch s.region {
        case .abq:
            return
        case .lux:
            if Int(seed.rounded()) % 3 == 0 { obelisk(x, y, hh * 0.9); return }
            let clump: [(CGFloat, CGFloat)] = [(-16, 0.85), (10, 1), (26, 0.75)]
            for (dx, k) in clump { palm(x + dx, y + (dx > 0 ? 4 : 0), k * hh / 90) }
        case .cap:
            ScenePainter.chimney(&c, x, y, hh * 0.42, hh, body: hex("#efc79e"), shade: hex("#c69068"), cap: hex("#6a4430"))
        }
    }

    /// Out in the land: fairy chimneys in Cappadocia; red buttes and junipers in Albuquerque; palm groves and temple ruins in Luxor.
    mutating func outerLandmark(_ x: CGFloat, _ y: CGFloat, _ hh: CGFloat, _ i: Int) {
        switch s.region {
        case .abq:
            if i % 3 == 0 {
                roundTree(x, y, 0.7, "#4f6e3a")
                roundTree(x + 18, y + 6, 0.55, "#5a7a40")
                return
            }
            butte(x, y, hh * (i % 2 == 1 ? 1.3 : 0.8), hh * (i % 2 == 1 ? 0.45 : 0.7), "#c8744a", "#8e4a2c")
        case .lux:
            if i % 7 == 0 {
                temple(x, y, hh * 0.9, hh * 0.42, "#c9a878")
                temple(x - 3, y, hh * 0.9, hh * 0.4, "#e2c79a")
                return
            }
            let grove: [(CGFloat, CGFloat, CGFloat)] = [(-20, 0, 0.9), (0, 6, 1.1), (18, -2, 0.8), (34, 5, 1)]
            for (dx, dy, k) in grove { palm(x + dx, y + dy, k * hh / 150, tt: t + Double(i)) }
        case .cap:
            ScenePainter.chimney(&c, x, y, hh * 0.42, hh, body: hex("#efc79e"), shade: hex("#c69068"), cap: hex("#6a4430"))
        }
    }

    mutating func lantern(_ x: CGFloat, _ y: CGFloat) {
        ellipse(x, y, 3.5, 3.5, hex("#ffd890"))
        glow(x, y, 22, Color(red: 1, green: 200 / 255, blue: 110 / 255), 0.55)
    }

    mutating func flag(_ x: CGFloat, _ y: CGFloat, _ col: String, hgt: CGFloat = 60) {
        line(pt(x, y), pt(x, y - hgt), hex("#3a2416"), 2.5)
        let wv = CGFloat(sin(t * 3 + Double(x))) * 4
        var p = Path()
        p.move(to: pt(x, y - hgt))
        p.addQuadCurve(to: pt(x + 30, y - hgt + 3), control: pt(x + 16, y - hgt - 4 + wv))
        p.addLine(to: pt(x + 30, y - hgt + 18))
        p.addQuadCurve(to: pt(x, y - hgt + 20), control: pt(x + 16, y - hgt + 14 + wv))
        p.closeSubpath()
        c.fill(p, with: .color(hex(col)))
    }

    mutating func person(_ x: CGFloat, _ y: CGFloat, _ col: String, _ tt: Double, _ ph: Double) {
        let b = CGFloat(abs(sin(tt * 6 + ph))) * 1.5
        ellipse(x, y - 15 - b, 3.2, 3.2, hex("#3a2418"))
        rect(x - 3, y - 12 - b, 6, 9, hex(col))
        rect(x - 3, y - 3, 2, 3, hex("#2a1a14"))
        rect(x + 1, y - 3, 2, 3, hex("#2a1a14"))
    }

    mutating func propane(_ x: CGFloat, _ y: CGFloat) {
        rect(x - 5, y - 18, 10, 18, hex("#d8d4cc"))
        ellipse(x, y - 18, 5, 2.5, hex("#d8d4cc"))
        rect(x + 2, y - 18, 3, 18, hex("#9a948a"))
    }

    mutating func crate(_ x: CGFloat, _ y: CGFloat) {
        rect(x - 8, y - 12, 16, 12, hex("#b07a44"))
        var p = Path(CGRect(x: x - 8, y: y - 12, width: 16, height: 12))
        p.move(to: pt(x - 8, y - 12)); p.addLine(to: pt(x + 8, y))
        c.stroke(p, with: .color(hex("#6a4424")), lineWidth: 1)
    }

    mutating func windsock(_ x: CGFloat, _ y: CGFloat, pole: CGFloat, speed: Double) {
        line(pt(x, y), pt(x, y - pole), hex("#3a2416"), 2)
        var p = Path()
        p.move(to: pt(x, y - pole))
        p.addLine(to: pt(x + 22 + CGFloat(sin(t * speed)) * 3, y - pole + 6))
        p.addLine(to: pt(x, y - pole + 10))
        p.closeSubpath()
        c.fill(p, with: .color(hex("#ff8a3d")))
    }

    mutating func balloon(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ colors: [String], burn: Bool = false, alpha: Double = 1,
                                  ad: Sponsor? = nil, design: Design? = nil) {
        ScenePainter.balloon(&c, x: x, y: y, r: r, colors: colors, burn: burn, alpha: alpha, ad: ad, design: design,
                             region: s.region, time: t)
    }

    // MARK: Shadows

    /// Soft cast shadow of a box footprint with height h.
    mutating func boxShadow(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, _ a: Double = 0.22) {
        let (A, B, C, D) = corners(gx, gy, w, d)
        let sh = { (p: CGPoint) -> CGPoint in CGPoint(x: p.x + h * Self.sunShadow.width, y: p.y + h * Self.sunShadow.height) }
        poly([A, sh(A), sh(B), sh(C), sh(D), D, C, B], rgba(90, 45, 20, a))
    }

    mutating func blobShadow(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ a: Double = 0.22) {
        ellipse(x, y, rx, ry, rgba(90, 45, 20, a))
    }

    mutating func buildingShadow(_ b: TownBuilding) {
        if b.lv <= 0 && b.look != .kiosk { return }
        let h: CGFloat
        switch b.look {
        case .hangar: h = 80
        case .workshop: h = 70
        case .office: h = b.lv == 2 ? 104 : 74
        case .school: h = 90
        case .bank: h = 85
        case .guide: h = 48
        case .agency: h = 100
        case .tower: h = 270
        case .kiosk: h = 44
        case .hotel: h = [60, 120, 140, 120][b.star]
        case .bazaar: h = 60
        case .mast: return
        }
        boxShadow(b.gx + 0.3, b.gy + 0.3, b.w - 0.6, b.d - 0.6, h, 0.18)
    }

    // MARK: Plots

    mutating func plot(_ b: TownBuilding) {
        let (A, B, C, D) = corners(b.gx + 0.1, b.gy + 0.1, b.w - 0.2, b.d - 0.2)
        poly([A, B, C, D], hex("#c99b6a"))
        poly([lp(A, C, 0.08), lp(B, D, 0.08), lp(A, C, 0.92), lp(B, D, 0.92)], hex("#d6ac7a"))
        var R = rng(b.gx * 7 + b.gy)
        var dirt = Path()
        for _ in 0..<18 {
            let p = lp(lp(A, B, CGFloat(R.next())), lp(D, C, CGFloat(R.next())), CGFloat(R.next()))
            dirt.addRect(CGRect(x: p.x, y: p.y, width: 3, height: 2))
        }
        c.fill(dirt, with: .color(rgba(120, 80, 40, 0.25)))
        var rope = Path()
        rope.move(to: upp(A, 14))
        for p in [B, C, D, A] { rope.addLine(to: upp(p, 14)) }
        c.stroke(rope, with: .color(rgba(240, 230, 210, 0.9)), lineWidth: 1.2)
        for p in [A, B, C, D] { rect(p.x - 2, p.y - 18, 4, 18, hex("#6a4426")) }
        let m = lp(A, C, 0.5)
        if b.lv == -1 {
            // Scaffolding: not open yet.
            var sc = Path()
            for i in -1...1 {
                let x = m.x + CGFloat(i) * 26
                sc.move(to: pt(x, m.y + 6)); sc.addLine(to: pt(x, m.y - 76))
            }
            for j in 0..<3 {
                let y = m.y - 10 - CGFloat(j) * 26
                sc.move(to: pt(m.x - 26, y)); sc.addLine(to: pt(m.x + 26, y))
                sc.move(to: pt(m.x - 26, y)); sc.addLine(to: pt(m.x + 26, y - 26))
            }
            c.stroke(sc, with: .color(hex("#8a6a48")), lineWidth: 2.5)
            for i in 0..<4 { rect(m.x + 30 + CGFloat(i) * 3, m.y - 4 - CGFloat(i) * 6, 14, 5, hex("#c9b8a0")) }
            return
        }
        rect(m.x - 2, m.y - 60, 4, 60, hex("#5a3a20"))
        let sign = Path(roundedRect: CGRect(x: m.x - 40, y: m.y - 86, width: 80, height: 30), cornerRadius: 5)
        c.fill(sign, with: .color(hex("#fff6e6")))
        c.stroke(sign, with: .color(hex("#ff5e3a")), lineWidth: 2.5)
        text(loc("town.forSale"), m.x, m.y - 71, size: 17, color: hex("#ff5e3a"))
    }

    // MARK: Buildings

    mutating func building(_ b: TownBuilding) {
        if b.lv <= 0 && b.look != .kiosk { plot(b); return }
        let big = b.lv == 2, g = b.gx, k = b.gy
        switch b.look {
        case .hangar: hangar(b, big)
        case .workshop: workshop(b, big)
        case .office: office(b, big)
        case .school: school(b, big)
        case .bank: bank(b, big)
        case .guide: guideOffice(b, big)
        case .agency: agency(g, k, big)
        case .tower: tower(b)
        case .kiosk: kiosk(b)
        case .hotel: hotel(b)
        case .mast: windMast(b.gx + 0.2, b.gy + 0.2)
        case .bazaar: bazaar(b)
        }
    }

    /// Barrel vault in company colors, big open doors, propane and crates.
    mutating func hangar(_ b: TownBuilding, _ big: Bool) {
        let x0 = b.gx + 0.25, y0 = b.gy + 0.2, w = b.w - 0.5, d = b.d - 0.4
        let wallH: CGFloat = big ? 46 : 36, rise: CGFloat = 52, col = s.colors
        let f = block(x0, y0, w, d, wallH, lit: "#ead2b0", shade: "#b48a64", top: "#e9d2b0")
        let N = 14
        let P = { (x: Double, y: Double, z: CGFloat) -> CGPoint in CGPoint(x: TownGeo.iso(x, y).x, y: TownGeo.iso(x, y).y - z) }
        let zh = { (sv: Double) -> CGFloat in wallH + rise * CGFloat(sin(Double.pi * sv)) }
        for i in 0..<N {
            let s0 = Double(i) / Double(N), s1 = Double(i + 1) / Double(N)
            let yA = y0 + d * s0, yB = y0 + d * s1
            let shade = 0.55 + 0.45 * cos(Double.pi * (s0 + s1) / 2 - 0.6)
            let base = col.count > 1 ? col[i % 4 < 2 ? 0 : 1] : (col.first ?? "#ff5e3a")
            poly([P(x0 - 0.05, yA, zh(s0)), P(x0 + w + 0.05, yA, zh(s0)), P(x0 + w + 0.05, yB, zh(s1)), P(x0 - 0.05, yB, zh(s1))],
                 mix(base, "#2a1020", min(max(1 - shade, 0), 0.5)))
        }
        var end: [CGPoint] = []
        for i in 0...N { end.append(P(x0 + w, y0 + d * Double(i) / Double(N), zh(Double(i) / Double(N)))) }
        end.append(P(x0 + w, y0 + d, wallH)); end.append(P(x0 + w, y0, wallH))
        poly(end, hex("#c09068"))
        opening(f.D, f.C, wallH, 0.5, 0, 0.62, 0.95)
        var door = face(f.D, f.C, wallH)
        door.fill(Path(CGRect(x: 0.2, y: 0, width: 0.6, height: 0.9)), with: .color(hex("#2a1a14")))
        door.fill(Path(CGRect(x: 0.12, y: 0, width: 0.1, height: 0.92)), with: .color(hex("#7a4a22")))
        door.fill(Path(CGRect(x: 0.78, y: 0, width: 0.1, height: 0.92)), with: .color(hex("#7a4a22")))
        let dm = lp(f.D, f.C, 0.5)
        rect(dm.x - 9, dm.y - 14, 18, 12, hex("#6b4426")) // a basket inside
        for i in 0..<4 { let p = iso(x0 + w + 0.2, y0 + 0.2 + Double(i) * 0.3); propane(p.x, p.y) }
        let cp = iso(x0 + 0.3, y0 + d + 0.35)
        crate(cp.x, cp.y); crate(cp.x + 18, cp.y + 6)
        windsock(f.b.x + 6, f.b.y - rise, pole: 40, speed: 2)
        if big { flag(f.a.x, f.a.y - rise + 10, col.first ?? "#ff5e3a") }
    }

    /// Sawtooth glass roof and the latest design's fabric drying on lines.
    mutating func workshop(_ b: TownBuilding, _ big: Bool) {
        let x0 = b.gx + 0.2, y0 = b.gy + 0.25, w = b.w - 0.4, d = b.d - 0.6
        let h: CGFloat = big ? 64 : 52
        let f = block(x0, y0, w, d, h)
        let P = { (x: Double, y: Double, z: CGFloat) -> CGPoint in CGPoint(x: TownGeo.iso(x, y).x, y: TownGeo.iso(x, y).y - z) }
        for i in 0..<3 {
            let a = x0 + w * Double(i) / 3, bb = x0 + w * Double(i + 1) / 3
            poly([P(a, y0, h), P(a, y0 + d, h), P(bb, y0 + d, h + 26), P(bb, y0, h + 26)], hex("#d9a77a"))
            poly([P(bb, y0, h + 26), P(bb, y0 + d, h + 26), P(bb, y0 + d, h), P(bb, y0, h)], rgba(160, 215, 240, 0.85))
        }
        opening(f.D, f.C, h, 0.3, 0, 0.22, 0.7, door: true)
        opening(f.D, f.C, h, 0.72, 0.3, 0.22, 0.45, lit: true)
        opening(f.C, f.B, h, 0.5, 0.35, 0.3, 0.4, lit: true)
        let cols = s.designs.last?.colors ?? (s.colors + ["#2b2350"])
        let l0 = iso(x0 - 0.1, y0 + d + 0.6), l1 = iso(x0 + w + 0.1, y0 + d + 0.6)
        for p in [l0, l1] { line(p, pt(p.x, p.y - 40), hex("#5a3a20"), 2) }
        line(pt(l0.x, l0.y - 38), pt(l1.x, l1.y - 38), hex("#5a3a20"), 1)
        let n = big ? 5 : 3, span: CGFloat = big ? 5.4 : 3.6
        for i in 0..<n {
            let p = lp(l0, l1, (CGFloat(i) + 0.6) / span), sway = CGFloat(sin(t * 2 + Double(i))) * 2
            poly([pt(p.x - 8, p.y - 38), pt(p.x + 8, p.y - 37), pt(p.x + 7 + sway, p.y - 12), pt(p.x - 7 + sway, p.y - 13)],
                 hex(cols.isEmpty ? "#ff5e3a" : cols[i % cols.count]))
        }
    }

    /// Pilot office: parapet, wooden balcony, windsock and a bench.
    mutating func office(_ b: TownBuilding, _ big: Bool) {
        let x0 = b.gx + 0.3, y0 = b.gy + 0.3, w = b.w - 0.6, d = b.d - 0.6
        let h: CGFloat = big ? 104 : 74
        let f = block(x0, y0, w, d, h, parapet: true)
        opening(f.D, f.C, h, 0.3, 0, 0.2, big ? 0.35 : 0.5, door: true)
        for u: CGFloat in [0.6, 0.82] { opening(f.D, f.C, h, u, big ? 0.1 : 0.18, 0.14, big ? 0.2 : 0.3, lit: true) }
        for u: CGFloat in [0.25, 0.5, 0.75] { opening(f.D, f.C, h, u, big ? 0.58 : 0.62, 0.14, big ? 0.2 : 0.26, lit: u != 0.5) }
        opening(f.C, f.B, h, 0.5, 0.55, 0.2, 0.25, lit: true)
        let b0 = upp(lp(f.D, f.C, 0.15), h * 0.55), b1 = upp(lp(f.D, f.C, 0.85), h * 0.55)
        poly([b0, b1, pt(b1.x - 10, b1.y + 5), pt(b0.x - 10, b0.y + 5)], hex("#7a4a24"))
        var rail = Path()
        for i in 0...8 {
            let p = lp(b0, b1, CGFloat(i) / 8)
            rail.move(to: pt(p.x - 5, p.y + 3)); rail.addLine(to: pt(p.x - 5, p.y - 10))
        }
        c.stroke(rail, with: .color(hex("#5a3418")), lineWidth: 1.5)
        windsock(f.b.x - 6, f.b.y, pole: 34, speed: 2.4)
        let bench = iso(x0 + 0.2, y0 + d + 0.35)
        rect(bench.x - 12, bench.y - 6, 24, 4, hex("#7a4a24"))
        rect(bench.x - 10, bench.y - 2, 3, 4, hex("#7a4a24"))
        rect(bench.x + 7, bench.y - 2, 3, 4, hex("#7a4a24"))
    }

    /// Pilot school: gable roof, bell tower, a tethered training balloon and students.
    mutating func school(_ b: TownBuilding, _ big: Bool) {
        let x0 = b.gx + 0.25, y0 = b.gy + 0.35, w = b.w - 0.9, d = b.d - 0.7
        let h: CGFloat = 66
        let f = block(x0, y0, w, d, h)
        gableRoof(x0, y0, w, d, h, 26, "#c0583a")
        for u: CGFloat in [0.2, 0.45, 0.7] { opening(f.D, f.C, h, u, 0.25, 0.14, 0.45, lit: true) }
        opening(f.C, f.B, h, 0.5, 0, 0.3, 0.6, door: true)
        let tw = block(x0 + w + 0.05, y0 + 0.1, 0.45, 0.45, 120, parapet: true)
        opening(tw.D, tw.C, 120, 0.5, 0.72, 0.45, 0.2)
        let bc = lp(tw.D, tw.C, 0.5)
        ellipse(bc.x, bc.y - 120 * 0.78, 5, 5, hex("#ffc23d"))
        let tb = iso(x0 + w + 0.3, y0 + d + 0.7), alt: CGFloat = big ? 110 : 70, sway = CGFloat(sin(t * 0.8)) * 4
        line(tb, pt(tb.x + sway, tb.y - alt), rgba(60, 35, 25, 0.7), 1)
        blobShadow(tb.x + 30, tb.y + 10, 18, 7, 0.18)
        balloon(tb.x + sway, tb.y - alt + 10, 22, ["#14a39a", "#e8fff9"], burn: t.truncatingRemainder(dividingBy: 3) < 0.3)
        let cols = ["#2b2350", "#ff5e3a", "#14a39a"]
        for i in 0..<(big ? 5 : 3) {
            let p = iso(x0 + 0.2 + Double(i) * 0.25, y0 + d + 0.5)
            person(p.x, p.y, cols[i % 3], t * 0.2, Double(i))
        }
    }

    /// Bank: marble steps, colonnade, pediment with the currency sign, an armored van while you owe money.
    mutating func bank(_ b: TownBuilding, _ big: Bool) {
        let x0 = b.gx + 0.3, y0 = b.gy + 0.35, w = b.w - 0.6, d = b.d - 0.7
        let h: CGFloat = 70
        block(x0 - 0.15, y0 - 0.05, w + 0.3, d + 0.3, 10, lit: "#efe8dc", shade: "#b8ad9c", top: "#f6f1e8", courses: false)
        let f = block(x0, y0, w, d, h, lit: "#efe8dc", shade: "#b8ad9c", top: "#f6f1e8", courses: false)
        for i in 0..<5 {
            let p = lp(lp(f.D, f.C, 0.08), lp(f.D, f.C, 0.92), CGFloat(i) / 4), q = pt(p.x - 8, p.y + 4)
            rect(q.x - 5, q.y - h + 6, 10, h - 6, hex("#fbf8f2"))
            rect(q.x + 2, q.y - h + 6, 3, h - 6, rgba(120, 100, 80, 0.25))
        }
        gableRoof(x0, y0, w, d, h, 22, "#e2d8c6", eave: 0.14)
        let pd = upp(lp(f.D, f.C, 0.5), h + 9)
        text(s.region == .abq ? "$" : "€", pd.x, pd.y - 2, size: 20, color: hex("#c98a00"))
        if big {
            let p = iso(x0 + w + 0.4, y0 + d + 0.2)
            rect(p.x - 14, p.y - 22, 28, 22, hex("#2b2350"))
            rect(p.x - 10, p.y - 18, 20, 6, hex("#ffc23d"))
        }
    }

    /// Guide office: striped teal awning, map board, the tour minibus.
    mutating func guideOffice(_ b: TownBuilding, _ big: Bool) {
        let x0 = b.gx + 0.35, y0 = b.gy + 0.4, w = b.w - 1, d = b.d - 1
        let h: CGFloat = 48
        let f = block(x0, y0, w, d, h)
        let a0 = upp(f.D, h - 6), a1 = upp(f.C, h - 6), a2 = pt(a1.x - 16, a1.y + 14), a3 = pt(a0.x - 16, a0.y + 14)
        for i in 0..<6 {
            let k0 = CGFloat(i) / 6, k1 = CGFloat(i + 1) / 6
            poly([lp(a0, a1, k0), lp(a0, a1, k1), lp(a3, a2, k1), lp(a3, a2, k0)], hex(i % 2 == 1 ? "#ffffff" : "#3ad0c0"))
        }
        opening(f.D, f.C, h, 0.5, 0, 0.3, 0.55, door: true)
        let mb = iso(x0 - 0.2, y0 + d + 0.2)
        rect(mb.x - 1, mb.y - 30, 3, 30, hex("#5a3a20"))
        rect(mb.x - 14, mb.y - 42, 28, 18, hex("#f3e8c8"))
        var route = Path()
        route.move(to: pt(mb.x - 10, mb.y - 30)); route.addLine(to: pt(mb.x - 2, mb.y - 38)); route.addLine(to: pt(mb.x + 8, mb.y - 32))
        c.stroke(route, with: .color(hex("#3ad0c0")), lineWidth: 1.5)
        block(x0 + w + 0.15, y0 + 0.05, 0.55, 0.9, 22, lit: "#ffffff", shade: "#d8d8d8", top: "#f4f4f4", courses: false)
        let s0 = iso(x0 + w + 0.15, y0 + 0.95)
        rect(s0.x - 2, s0.y - 12, 38, 5, hex("#3ad0c0"))
        if big {
            let cols = ["#ffc23d", "#ff6fa8", "#5aa9e6", "#22a45d"]
            for i in 0..<4 {
                let p = iso(x0 + 0.1 + Double(i) * 0.2, y0 + d + 0.45)
                person(p.x, p.y, cols[i], t * 0.2, Double(i))
            }
        }
    }

    /// Influencer agency: a modern cave-stone villa with big lit glass, a roof terrace and a pool.
    mutating func agency(_ g: Double, _ k: Double, _ big: Bool) {
        let x0 = g + 0.25, y0 = k + 0.25, w = 1.5, d = 1.15
        let h1: CGFloat = 54, h2: CGFloat = 46
        let lit = "#f6e2c8", shade = "#c4936c", top = "#efd9b8"
        let f1 = block(x0, y0, w, d, h1, lit: lit, shade: shade, top: top, courses: false)
        glass(f1.D, f1.C, h1, 0.08, 0.62, 0.04, 0.82, lit: true)
        opening(f1.D, f1.C, h1, 0.8, 0, 0.18, 0.62, door: true)
        glass(f1.C, f1.B, h1, 0.2, 0.8, 0.3, 0.78, lit: false)
        // Bougainvillea climbing the lit wall.
        var R = rng(77)
        for _ in 0..<26 {
            let a = lp(f1.D, f1.C, 0.62 + CGFloat(R.next()) * 0.1), y = h1 * (0.2 + CGFloat(R.next()) * 0.8)
            let r1 = R.next(), r2 = R.next()
            let col = r1 < 0.3 ? "#7aa04a" : r2 < 0.6 ? "#e0408a" : "#ff6fa8"
            let dx = CGFloat(R.next()) * 6 - 3, rr = 2.5 + CGFloat(R.next()) * 2
            ellipse(a.x + dx, a.y - y, rr, rr, hex(col))
        }
        // Upper floor, set back, standing on the roof.
        let keep = c
        c.translateBy(x: 0, y: -h1)
        let f2 = block(x0 + 0.55, y0 + 0.05, 0.9, 0.75, h2, lit: lit, shade: shade, top: top, courses: false, parapet: true, roofIn: "#e2c7a2")
        glass(f2.D, f2.C, h2, 0.1, 0.9, 0.1, 0.85, lit: true)
        glass(f2.C, f2.B, h2, 0.25, 0.75, 0.25, 0.8, lit: false)
        // Pergola over the roof terrace.
        let pa = iso(x0 + 0.08, y0 + 0.1), pb = iso(x0 + 0.5, y0 + 0.1), pc = iso(x0 + 0.5, y0 + 1.05), pdd = iso(x0 + 0.08, y0 + 1.05)
        let ph: CGFloat = 30
        var posts = Path()
        for q in [pa, pb, pc, pdd] { posts.move(to: q); posts.addLine(to: upp(q, ph)) }
        c.stroke(posts, with: .color(hex("#6a4024")), lineWidth: 2.5)
        var beams = Path()
        for i in 0...5 {
            let kk = CGFloat(i) / 5
            beams.move(to: upp(lp(pa, pdd, kk), ph)); beams.addLine(to: upp(lp(pb, pc, kk), ph))
        }
        beams.move(to: upp(pdd, ph)); beams.addLine(to: upp(pc, ph))
        c.stroke(beams, with: .color(hex("#6a4024")), lineWidth: 2)
        // The influencer filming with a ring light.
        let ip = lp(f2.D, f2.C, 0.1), ix = ip.x - 26, iy = ip.y + 12
        person(ix, iy, "#ff6fa8", big ? t : 0, 3)
        c.stroke(Path(ellipseIn: CGRect(x: ix - 25, y: iy - 33, width: 14, height: 14)), with: .color(big ? .white : Color.white.opacity(0.7)), lineWidth: 2.5)
        line(pt(ix - 18, iy - 19), pt(ix - 18, iy), hex("#3a2416"), 1.2)
        // Neon play sign on the upper wall, pulsing while a campaign runs.
        let sc = upp(lp(f2.C, f2.B, 0.5), h2 * 0.55), pulse = big ? 0.7 + 0.3 * sin(t * 5) : 0.5
        var neon = c
        neon.opacity = pulse
        if big { neon.addFilter(.shadow(color: hex("#ff6fa8"), radius: 10)) }
        neon.fill(Path(roundedRect: CGRect(x: sc.x - 13, y: sc.y - 9, width: 26, height: 18), cornerRadius: 5), with: .color(hex("#ff6fa8")))
        poly([pt(sc.x - 4, sc.y - 5), pt(sc.x + 6, sc.y), pt(sc.x - 4, sc.y + 5)], .white)
        c = keep
        // Turquoise pool in the front garden.
        let (pA, pB, pC, pD) = corners(x0 + 0.05, y0 + d + 0.12, 1.3, 0.4)
        poly([pA, pB, pC, pD], hex("#efe2cc"))
        let (iA, iB, iC, iD) = corners(x0 + 0.12, y0 + d + 0.17, 1.16, 0.3)
        polyShade([iA, iB, iC, iD], .linearGradient(grad([(hex("#8ae6ec"), 0), (hex("#2aa6c4"), 1)]), startPoint: iA, endPoint: iC))
        ripples(iA, iB, iC, iD, rows: 3)
        let cp = iso(g + 1.9, k + 0.35)
        hotelTree(cp.x, cp.y, 1)
    }

    mutating func ripples(_ A: CGPoint, _ B: CGPoint, _ C: CGPoint, _ D: CGPoint, rows: Int) {
        var p = Path()
        for i in 0..<rows {
            let k = 0.3 + CGFloat(i) * (rows > 3 ? 0.18 : 0.2)
            let a = lp(A, D, k), b = lp(B, C, k)
            p.move(to: pt(a.x + CGFloat(sin(t + Double(i))) * 3, a.y))
            p.addLine(to: pt(b.x + CGFloat(sin(t + Double(i) + 1)) * 3, b.y))
        }
        c.stroke(p, with: .color(Color.white.opacity(0.5)), lineWidth: 1.2)
    }

    /// Holding tower: gold glass with a crown and a glow.
    mutating func tower(_ b: TownBuilding) {
        let x0 = b.gx + 0.45, y0 = b.gy + 0.45, w = b.w - 0.9, d = b.d - 0.9
        let h: CGFloat = 270
        let (A, B, C, D) = corners(x0, y0, w, d)
        for (p, q, light) in [(D, C, true), (C, B, false)] {
            let g = grad([(hex(light ? "#ffe9b0" : "#b07a2a"), 0), (hex(light ? "#d9a64a" : "#6a4410"), 1)])
            polyShade([p, q, upp(q, h), upp(p, h)], .linearGradient(g, startPoint: pt(p.x, 0), endPoint: pt(q.x, 0)))
            var floors = Path()
            for i in 1..<18 {
                let z = h * CGFloat(i) / 18
                floors.move(to: upp(p, z)); floors.addLine(to: upp(q, z))
            }
            c.stroke(floors, with: .color(rgba(70, 40, 10, 0.3)), lineWidth: 1)
        }
        poly([upp(A, h), upp(B, h), upp(C, h), upp(D, h)], hex("#ffd27a"))
        let top = lp(upp(A, h), upp(C, h), 0.5)
        let cx = top.x, cy = top.y - 18
        poly([pt(cx - 22, cy + 12), pt(cx - 26, cy - 12), pt(cx - 12, cy), pt(cx, cy - 20), pt(cx + 12, cy), pt(cx + 26, cy - 12), pt(cx + 22, cy + 12)],
             hex("#ffc23d"))
        glow(top.x, top.y, 120, Color(red: 1, green: 210 / 255, blue: 120 / 255), 0.45)
    }

    /// Booking office kiosk: awning and mini balloon in the company's colors; boarded up once it's gone.
    mutating func kiosk(_ b: TownBuilding) {
        let x0 = b.gx + 0.1, y0 = b.gy + 0.1, w = b.w - 0.2, d = b.d - 0.2
        let c1 = b.colors.first ?? "#ff5e3a", c2 = b.colors.count > 1 ? b.colors[1] : "#ffffff"
        if b.lv == 0 {
            let f = block(x0, y0, w, d, 34, lit: "#9a8a78", shade: "#6a5a48", top: "#8a7a68")
            let boards = face(f.D, f.C, 34)
            for i in 0..<3 {
                var bd = boards
                bd.translateBy(x: 0.5, y: 0.45)
                bd.rotate(by: .radians(Double(i - 1) * 0.3))
                bd.fill(Path(CGRect(x: -0.5, y: -0.06, width: 1, height: 0.12)), with: .color(hex("#5a3a20")))
            }
            return
        }
        let f = block(x0, y0, w, d, 44)
        let a0 = upp(f.D, 40), a1 = upp(f.C, 40), a2 = pt(a1.x - 12, a1.y + 10), a3 = pt(a0.x - 12, a0.y + 10)
        for i in 0..<4 {
            let k0 = CGFloat(i) / 4, k1 = CGFloat(i + 1) / 4
            poly([lp(a0, a1, k0), lp(a0, a1, k1), lp(a3, a2, k1), lp(a3, a2, k0)], hex(i % 2 == 1 ? c2 : c1))
        }
        opening(f.D, f.C, 44, 0.5, 0, 0.3, 0.55, door: true)
        let top = lp(f.a, f.c, 0.5)
        balloon(top.x, top.y - 4, 11, [c1, c2])
    }

    // MARK: Hotels

    /// Four hotels, each clearly grander than the last.
    mutating func hotel(_ b: TownBuilding) {
        let g = b.gx, k = b.gy, own = b.lv == 2
        switch b.star {
        case 0: pension(g, k)
        case 1: konak(g, k)
        case 2: caveHotel(g, k)
        default: palace(g, k, own: own)
        }
        let top = iso(b.gx + b.w * 0.5, b.gy + 0.3)
        if let fl = b.flag, b.star < 3 {
            let lift: CGFloat = b.star == 2 ? 110 : b.star == 1 ? 100 : 50
            flag(top.x + 18, top.y - lift, fl, hgt: 34)
        }
        if own {
            let m = iso(b.gx + b.w / 2, b.gy + b.d / 2)
            glow(m.x, m.y - 40, 160, Color(red: 1, green: 200 / 255, blue: 90 / 255), 0.13)
        }
    }

    /// Göreme stone pension: one humble storey, laundry and geraniums.
    mutating func pension(_ g: Double, _ k: Double) {
        let f = block(g + 0.45, k + 0.55, 1.1, 0.9, 46)
        gableRoof(g + 0.45, k + 0.55, 1.1, 0.9, 46, 18, "#b0583a")
        opening(f.D, f.C, 46, 0.3, 0, 0.22, 0.6, door: true)
        opening(f.D, f.C, 46, 0.72, 0.3, 0.18, 0.35, lit: true)
        for u: CGFloat in [0.15, 0.55, 0.9] {
            let p = lp(f.D, f.C, u)
            rect(p.x - 4, p.y - 6, 8, 6, hex("#8a4a2a"))
            ellipse(p.x, p.y - 9, 4, 4, hex("#e5432f"))
        }
        let l0 = iso(g + 0.3, k + 1.7), l1 = iso(g + 1.3, k + 1.7)
        line(pt(l0.x, l0.y - 26), pt(l1.x, l1.y - 26), hex("#5a3a20"), 1)
        for (i, col) in ["#ffffff", "#5aa9e6", "#ffc23d"].enumerated() {
            let p = lp(l0, l1, 0.2 + CGFloat(i) * 0.25)
            rect(p.x - 4, p.y - 26, 8, 10, hex(col))
        }
    }

    /// Ürgüp konak: two storeys, wooden bay window, hip roof, courtyard wall.
    mutating func konak(_ g: Double, _ k: Double) {
        block(g + 0.1, k + 1.55, 1.6, 0.12, 18, courses: false)
        let f = block(g + 0.35, k + 0.3, 1.3, 1.1, 92)
        hipRoof(g + 0.35, k + 0.3, 1.3, 1.1, 92, 30, "#c0583a")
        for u: CGFloat in [0.2, 0.45] { opening(f.D, f.C, 92, u, 0.08, 0.14, 0.25, lit: true) }
        opening(f.D, f.C, 92, 0.78, 0, 0.2, 0.32, door: true)
        for u: CGFloat in [0.25, 0.75] { opening(f.C, f.B, 92, u, 0.55, 0.2, 0.25, lit: true) }
        // Cumba: wooden bay window projecting from the upper floor.
        let bayH: CGFloat = 34, by: CGFloat = 92 * 0.5
        let q0 = upp(lp(f.D, f.C, 0.5), by), q1 = upp(lp(f.D, f.C, 0.95), by), ox: CGFloat = -14, oy: CGFloat = 7
        let o0 = pt(q0.x + ox, q0.y + oy), o1 = pt(q1.x + ox, q1.y + oy)
        poly([q0, q1, o1, o0], hex("#5a3418"))
        poly([o0, o1, upp(o1, bayH), upp(o0, bayH)], hex("#8a5a30"))
        for i in 0..<3 {
            let p = lp(o0, o1, (CGFloat(i) + 0.5) / 3)
            rect(p.x - 5, p.y - bayH + 6, 9, 16, hex("#ffd27a"))
        }
        poly([upp(q0, bayH), upp(q1, bayH), upp(o1, bayH), upp(o0, bayH)], hex("#c0583a"))
        let tr = iso(g + 0.25, k + 1.35)
        roundTree(tr.x, tr.y, 1, "#7aa04a")
    }

    /// Cave hotel: suites carved into fairy chimneys, a terrace with cushions and lanterns.
    mutating func caveHotel(_ g: Double, _ k: Double) {
        let terrace = block(g + 0.15, k + 1.05, 1.7, 0.8, 10, lit: "#c8955c", shade: "#8a5a34", top: "#b07a44", courses: false)
        let cones: [(Double, Double, CGFloat)] = [(g + 0.5, k + 0.5, 150), (g + 1.2, k + 0.45, 120), (g + 1.55, k + 0.9, 95)]
        for (x, y, hh) in cones.sorted(by: { $0.0 + $0.1 < $1.0 + $1.1 }) {
            let p = iso(x, y)
            switch s.region {
            case .abq: // stepped adobe pueblo with viga ends
                let steps: [(CGFloat, CGFloat)] = [(0, 0.5), (0.38, 0.36)]
                for (kk, w0) in steps {
                    let y0 = p.y - hh * kk, ht = hh * 0.36, x0 = p.x - hh * w0 / 2
                    rect(x0, y0 - ht, hh * w0, ht, hex("#b8724a"))
                    rect(x0, y0 - ht, hh * w0 * 0.6, ht, hex("#d99a6c"))
                    rect(x0 - 2, y0 - ht - 3, hh * w0 + 4, 4, hex("#e6b088"))
                    for vi in 0..<4 { rect(x0 + 4 + CGFloat(vi) * hh * w0 / 4, y0 - ht + 3, 3, 3, hex("#6a4028")) }
                }
            case .lux: // Nubian mud-brick house with a dome
                rect(p.x - hh * 0.2, p.y - hh * 0.7, hh * 0.4, hh * 0.7, hex("#c9ab7e"))
                rect(p.x - hh * 0.24, p.y - hh * 0.7, hh * 0.26, hh * 0.7, hex("#efe0c2"))
                dome(p.x - hh * 0.02, p.y - hh * 0.7, hh * 0.17, "#f3e8d2")
            case .cap:
                ScenePainter.chimney(&c, p.x, p.y, hh * 0.55, hh, body: hex("#efc79e"), shade: hex("#c69068"), cap: hex("#6a4430"))
            }
            for i in 0..<3 {
                let wy = p.y - hh * (0.18 + CGFloat(i) * 0.22), wx = p.x - hh * 0.08 + CGFloat(i % 2) * hh * 0.1
                var win = Path()
                win.move(to: pt(wx - 5, wy + 8))
                win.addLine(to: pt(wx - 5, wy))
                win.addQuadCurve(to: pt(wx + 5, wy), control: pt(wx, wy - 7))
                win.addLine(to: pt(wx + 5, wy + 8))
                win.closeSubpath()
                c.fill(win, with: .color(hex("#ffd27a")))
                lantern(wx, wy + 2)
            }
        }
        let cushions = ["#c0392b", "#e08a1e", "#7a2a4a", "#2b5a7a"]
        for i in 0..<4 {
            let u = 0.2 + CGFloat(i) * 0.2
            let p = lp(lp(terrace.d, terrace.c, u), lp(terrace.a, terrace.b, u), 0.4)
            rect(p.x - 7, p.y - 4, 14, 5, hex(cushions[i]))
        }
        for u: CGFloat in [0.05, 0.95] {
            let p = lp(terrace.d, terrace.c, u)
            rect(p.x - 1, p.y - 22, 2, 22, hex("#3a2416"))
            lantern(p.x, p.y - 24)
        }
    }

    /// Palace resort: a tall main block stepping forward between two wings, gilded domes, arcades,
    /// red carpet, infinity pool, palms and cypresses.
    mutating func palace(_ g: Double, _ k: Double, own: Bool) {
        let (oA, oB, oC, oD) = corners(g + 0.2, k + 2.1, 2.6, 0.72)
        poly([oA, oB, oC, oD], hex("#e8dcc6"))
        let (iA, iB, iC, iD) = corners(g + 0.3, k + 2.17, 2.4, 0.56)
        polyShade([iA, iB, iC, iD], .linearGradient(grad([(hex("#7fe0e8"), 0), (hex("#2a9ab8"), 1)]), startPoint: iA, endPoint: iC))
        ripples(iA, iB, iC, iD, rows: 4)
        let wingL = block(g + 0.2, k + 0.3, 0.8, 1.3, 80, parapet: true, roofIn: "#ead7b4")
        let wingR = block(g + 2.1, k + 0.3, 0.8, 1.3, 80, parapet: true, roofIn: "#ead7b4")
        let main = block(g + 0.95, k + 0.15, 1.2, 1.85, 130, parapet: true, roofIn: "#ead7b4")
        for f in [wingL, wingR] {
            for r in 0..<2 {
                for u: CGFloat in [0.2, 0.5, 0.8] { opening(f.D, f.C, 80, u, 0.12 + CGFloat(r) * 0.45, 0.16, 0.28, lit: r == 0 || u != 0.5) }
            }
        }
        for r in 0..<2 {
            for i in 0..<5 { opening(main.D, main.C, 130, 0.1 + CGFloat(i) * 0.2, 0.06 + CGFloat(r) * 0.46, 0.13, 0.34, lit: r == 0 || i % 2 == 0) }
        }
        let dc = lp(main.a, main.c, 0.5)
        dome(dc.x, dc.y - 6, 38, "#e8b23a")
        for f in [wingL, wingR] { let p = lp(f.a, f.c, 0.5); dome(p.x, p.y - 4, 18, "#e8b23a") }
        let flagCol = own ? (s.colors.first ?? "#ffc23d") : "#ffc23d"
        for f in [wingL, main, wingR] { flag(f.b.x - 4, f.b.y, flagCol, hgt: 40) }
        let rc = lp(main.D, main.C, 0.5)
        poly([rc, pt(rc.x + 10, rc.y + 5), pt(rc.x - 18, rc.y + 40), pt(rc.x - 28, rc.y + 35)], hex("#c0283a")) // red carpet
        for (x, y) in [(g + 0.1, k + 2.7), (g + 1, k + 2.85), (g + 2, k + 2.85), (g + 2.95, k + 2.7)] { let p = iso(x, y); palm(p.x, p.y, 0.9) }
        for (x, y) in [(g + 0.05, k + 0.2), (g + 3, k + 0.25)] { let p = iso(x, y); hotelTree(p.x, p.y, 1.2) }
    }

    // MARK: Ground

    func pmod(_ a: Double, _ m: Double) -> Double { (a.truncatingRemainder(dividingBy: m) + m).truncatingRemainder(dividingBy: m) }

    /// Today's wind in a layer: direction and strength, so balloons drift the way the flight will.
    func windK(_ i: Int) -> Double {
        let v = (s.weather?.layers.indices.contains(i) ?? false) ? s.weather!.layers[i] : 3
        let sign: Double = v < 0 ? -1 : 1
        return sign * min(max(abs(v) / 4, 0.5), 2)
    }

    /// Ground inside the walls: patches, vineyards, cobbled roads and the striped launch field.
    mutating func townDecor() {
        var R = Mulberry32(seed: 5)
        var green = Path(), brown = Path()
        for _ in 0..<160 {
            let p = iso(R.next() * 15, R.next() * 15)
            let isBrown = R.next() < 0.5
            let rx = 6 + CGFloat(R.next()) * 16, ry = 3 + CGFloat(R.next()) * 6
            let e = CGRect(x: p.x - rx, y: p.y - ry, width: rx * 2, height: ry * 2)
            if isBrown { brown.addEllipse(in: e) } else { green.addEllipse(in: e) }
        }
        c.fill(brown, with: .color(rgba(160, 120, 70, 0.18)))
        c.fill(green, with: .color(rgba(120, 150, 70, 0.22)))
        vineyards([(13.2, 3.4, 1.6, 3.6), (-9, 2, 5, 4), (18, 10, 4, 5), (2, 18, 4, 3.5), (-12, 12, 4, 3)])
        road(0, 7.55, 15, 8.45); road(7.55, 0, 8.45, 15); road(0.6, 3.6, 7.55, 4.1)
        let lf = [iso(1, 4.4), iso(7, 4.4), iso(7, 7.2), iso(1, 7.2)]
        poly(lf, hex("#a3b066"))
        var stripes = c
        stripes.opacity = 0.25
        for i in 0..<9 {
            let x = 1 + Double(i) * 0.67
            stripes.fill(path([iso(x, 4.4), iso(x + 0.33, 4.4), iso(x + 0.33, 7.2), iso(x, 7.2)]), with: .color(hex(i % 2 == 1 ? "#8a9a50" : "#b8c47a")))
        }
    }

    mutating func vineyards(_ fields: [(Double, Double, Double, Double)]) {
        var rows = Path()
        for (gx0, gy0, gw, gd) in fields {
            for r in 0..<6 {
                let y = gy0 + Double(r) * gd / 6
                rows.move(to: iso(gx0, y)); rows.addLine(to: iso(gx0 + gw, y))
            }
        }
        c.stroke(rows, with: .color(hex("#6f8a3a")), style: StrokeStyle(lineWidth: 4, dash: [6, 4]))
    }

    /// Cobbled road with kerbs.
    mutating func road(_ gx0: Double, _ gy0: Double, _ gx1: Double, _ gy1: Double) {
        let pts = [iso(gx0, gy0), iso(gx1, gy0), iso(gx1, gy1), iso(gx0, gy1)]
        let shape = path(pts)
        c.fill(shape, with: .color(hex("#c9a47a")))
        var inner = c
        inner.clip(to: shape)
        var R = rng(gx0 * 13 + gy0 * 7 + 1)
        var light = Path(), dark = Path()
        for _ in 0..<260 {
            let p = iso(gx0 + (gx1 - gx0) * R.next(), gy0 + (gy1 - gy0) * R.next())
            let e = CGRect(x: p.x - 4, y: p.y - 2, width: 8, height: 4)
            if R.next() < 0.5 { light.addEllipse(in: e) } else { dark.addEllipse(in: e) }
        }
        inner.fill(light, with: .color(rgba(255, 240, 215, 0.35)))
        inner.fill(dark, with: .color(rgba(110, 70, 40, 0.22)))
        c.stroke(shape, with: .color(rgba(110, 70, 40, 0.35)), lineWidth: 2)
    }

    private static let outerFields: [(Double, Double)] = [(-6, 9.5), (18, 2), (10, 18), (-4, -6), (20, 15)]

    /// Land around the town: patches, dirt roads running off, other companies' launch fields.
    /// Colors of the land round the town: patches, dirt roads, fields (vineyards, alfalfa, sugar cane).
    struct OuterLook {
        var patch: (Color, Color)
        var split: Double
        var road: String, field: String
    }

    var outerLook: OuterLook {
        switch s.region {
        case .cap: return OuterLook(patch: (rgba(160, 120, 70, 0.16), rgba(120, 150, 70, 0.2)), split: 0.55, road: "#d8b085", field: "#b3b86e")
        case .abq: return OuterLook(patch: (rgba(170, 90, 50, 0.16), rgba(130, 140, 90, 0.22)), split: 0.6, road: "#d49a6e", field: "#a9b46a")
        case .lux: return OuterLook(patch: (rgba(110, 160, 70, 0.24), rgba(200, 170, 110, 0.18)), split: 0.6, road: "#dcc28e", field: "#8db05a")
        }
    }

    mutating func outerDecor() {
        let L = outerLook
        var R = Mulberry32(seed: 9)
        var first = Path(), second = Path()
        for _ in 0..<420 {
            let gx = -22 + R.next() * 60, gy = -22 + R.next() * 60
            if gx > -1 && gx < 16 && gy > -1 && gy < 16 { continue }
            let p = iso(gx, gy)
            let isFirst = R.next() < L.split
            let rx = 8 + CGFloat(R.next()) * 22, ry = 4 + CGFloat(R.next()) * 8
            let e = CGRect(x: p.x - rx, y: p.y - ry, width: rx * 2, height: ry * 2)
            if isFirst { first.addEllipse(in: e) } else { second.addEllipse(in: e) }
        }
        c.fill(first, with: .color(L.patch.0))
        c.fill(second, with: .color(L.patch.1))
        // Luxor: the Nile runs past behind the town, green banks on both sides.
        if s.region == .lux {
            let band = { (y0: Double, y1: Double) -> [CGPoint] in
                [TownGeo.iso(-60, y0), TownGeo.iso(70, y0), TownGeo.iso(70, y1), TownGeo.iso(-60, y1)]
            }
            poly(band(-15.5, -9.5), hex("#8fb85a"))
            poly(band(-13.6, -11.2), hex("#3f8fa8"))
            poly(band(-13.1, -12.7), Color.white.opacity(0.18))
        }
        let dirt = { (x0: Double, y0: Double, x1: Double, y1: Double) -> [CGPoint] in
            [TownGeo.iso(x0, y0), TownGeo.iso(x1, y0), TownGeo.iso(x1, y1), TownGeo.iso(x0, y1)]
        }
        for r in [dirt(-40, 7.65, 0, 8.35), dirt(15, 7.65, 55, 8.35), dirt(7.65, -40, 8.35, 0), dirt(7.65, 15, 8.35, 55)] {
            poly(r, hex(L.road))
        }
        for f in Self.outerFields {
            let q = [iso(f.0, f.1), iso(f.0 + 3, f.1), iso(f.0 + 3, f.1 + 2.2), iso(f.0, f.1 + 2.2)]
            poly(q, hex(L.field))
            outline(q, rgba(110, 90, 40, 0.3), 2)
            if s.region == .lux { // sugar cane rows
                var rows = Path()
                for k in 1..<8 {
                    let x = f.0 + Double(k) * 0.37
                    rows.move(to: iso(x, f.1)); rows.addLine(to: iso(x, f.1 + 2.2))
                }
                c.stroke(rows, with: .color(rgba(60, 100, 40, 0.35)), lineWidth: 1.5)
            }
        }
    }

    /// Fairy chimneys, trees, your fleet on the launch field and people walking the roads.
    func scenery() -> [TownItem] {
        var items: [TownItem] = []
        let chims: [(Double, Double, CGFloat)] = [(0.3, 6.6, 150), (15.2, 8, 140), (0.4, 12.6, 130), (7.7, 0.3, 120),
                                                   (5.6, 15.2, 150), (0.5, 3.0, 160), (12.8, 0.2, 140)]
        // Albuquerque leaves the edge spots empty; Luxor puts palms and obelisks there, Cappadocia fairy chimneys.
        for (gx, gy, hh) in chims where s.region != .abq {
            items.append(TownItem(depth: gx + gy, shadow: { p in
                let q = TownGeo.iso(gx, gy); p.blobShadow(q.x + hh * 0.3, q.y + 8, hh * 0.3, hh * 0.08, 0.16)
            }, draw: { p in
                let q = TownGeo.iso(gx, gy)
                p.edgeLandmark(q.x, q.y, hh, gx + gy)
            }))
        }
        let cap = s.region == .cap
        let trees: [(Double, Double)] = [(7.1, 6.9), (7.1, 9.2), (8.9, 6.9), (3.4, 8.9), (6.6, 10.7), (14.6, 7.3), (10.8, 4.4), (4.3, 7.0), (8.4, 15)]
        for (i, (gx, gy)) in trees.enumerated() {
            items.append(TownItem(depth: gx + gy, shadow: { p in
                let q = TownGeo.iso(gx, gy); p.blobShadow(q.x + 12, q.y + 4, 14, 5, 0.16)
            }, draw: { p in
                let q = TownGeo.iso(gx, gy)
                if !cap { p.regionTree(q.x, q.y, i) } else if i % 3 == 0 { p.cypress(q.x, q.y) } else { p.roundTree(q.x, q.y, 0.9, i % 2 == 1 ? "#7aa04a" : "#8aa84e") }
            }))
        }
        // Your fleet on the launch field, burners flickering. At night the envelopes are packed away, except for a Fiesta balloon glow.
        let colors = s.colors, tt = t
        let packed = night != nil && night?.event != .balloonGlow
        for (i, b) in s.fieldBalloons.prefix(packed ? 0 : 6).enumerated() {
            let gx = 1.8 + Double(i % 3) * 1.9, gy = 5 + Double(i / 3) * 1.4
            let r: CGFloat = b.size == .XL ? 44 : b.size == .L ? 38 : b.size == .M ? 33 : 28
            let design = s.design(of: b), ad = b.ad
            items.append(TownItem(depth: gx + gy, shadow: { p in
                let q = TownGeo.iso(gx, gy); p.blobShadow(q.x + 26, q.y + 6, 26, 9, 0.18)
            }, draw: { p in
                let q = TownGeo.iso(gx, gy)
                p.balloon(q.x, q.y, r, colors, burn: (tt * 1.3 + Double(i)).truncatingRemainder(dividingBy: 3) < 0.4, ad: ad, design: design)
            }))
        }
        items += decorations() + bunting()
        // People strolling on the roads.
        let shirts = ["#2b2350", "#ff5e3a", "#14a39a", "#ffc23d", "#9b7be0"]
        for i in 0..<10 {
            let along = ((t * 0.05 + Double(i) * 0.1).truncatingRemainder(dividingBy: 1)) * 15
            let off = 7.8 + Double(i % 3) * 0.15
            let gx = i % 2 == 1 ? along : off, gy = i % 2 == 1 ? off : along
            items.append(TownItem(depth: gx + gy, draw: { p in
                let q = TownGeo.iso(gx, gy); p.person(q.x, q.y, shirts[i % 5], tt, Double(i))
            }))
        }
        return items
    }

    /// Fairy chimney clusters out in the valley, and balloons inflating and lifting off the other fields.
    func outerScenery() -> [TownItem] {
        var items: [TownItem] = []
        var R = Mulberry32(seed: 21)
        for i in 0..<46 {
            let gx = -18 + R.next() * 50, gy = -18 + R.next() * 50, hh = CGFloat(110 + R.next() * 120)
            if gx > -2 && gx < 17 && gy > -2 && gy < 17 { continue }
            if abs(gx - 8) < 1.6 || abs(gy - 8) < 1.6 { continue }
            if Self.outerFields.contains(where: { gx > $0.0 - 1 && gx < $0.0 + 4 && gy > $0.1 - 1 && gy < $0.1 + 3.5 }) { continue }
            items.append(TownItem(depth: gx + gy, at: (gx, gy), shadow: { p in
                let q = TownGeo.iso(gx, gy); p.blobShadow(q.x + hh * 0.3, q.y + 8, hh * 0.3, hh * 0.08, 0.14)
            }, draw: { p in
                let q = TownGeo.iso(gx, gy)
                p.outerLandmark(q.x, q.y, hh, i)
            }))
        }
        let cols: [[String]] = s.local.rivals.map { $0.colors } + [["#ff5e3a", "#ffc23d"], ["#14a39a", "#e8fff9"]]
        let tt = t
        // Nobody flies at night.
        for (i, f) in Self.outerFields.enumerated() where night == nil {
            for j in 0..<2 {
                let ph = (tt * 0.05 + Double(i) * 0.23 + Double(j) * 0.5).truncatingRemainder(dividingBy: 1)
                let gx = f.0 + 0.9 + Double(j) * 1.3, gy = f.1 + 1.1, col = cols[(i + j) % cols.count]
                let inflating = ph < 0.55, k = CGFloat(inflating ? 0.35 + 0.65 * ph / 0.55 : 1)
                let alt = CGFloat(inflating ? 0 : pow((ph - 0.55) / 0.45, 1.6) * 520)
                let burn = inflating ? ph > 0.3 && (tt * 3).truncatingRemainder(dividingBy: 1) < 0.5 : (tt + Double(i)).truncatingRemainder(dividingBy: 3) < 0.4
                let alpha = ph > 0.9 ? (1 - ph) * 10 : 1
                items.append(TownItem(depth: gx + gy, at: (gx, gy), shadow: { p in
                    let q = TownGeo.iso(gx, gy); p.blobShadow(q.x + 20, q.y + 6, 24 * k, 8 * k, inflating ? 0.18 : 0.1)
                }, draw: { p in
                    let q = TownGeo.iso(gx, gy)
                    p.balloon(q.x, q.y - alt, 30 * k, col, burn: burn, alpha: alpha)
                }))
            }
        }
        return items
    }

    /// A low tuff wall round the town with gaps where the roads leave.
    func townWall() -> [TownItem] {
        var items: [TownItem] = []
        let t0 = -0.5, t1 = 15.5, th = 0.14
        let seg = { (gx: Double, gy: Double, w: Double, d: Double) -> TownItem in
            TownItem(depth: gx + w + gy + d - 0.5, draw: { p in p.block(gx, gy, w, d, 16, top: "#f3dcb8", courses: false) })
        }
        var x = t0
        while x < t1 {
            let w = min(1, t1 - x)
            if !(x + w > 7.55 && x < 8.45) { items.append(seg(x, t0 - th, w, th)); items.append(seg(x, t1, w, th)) }
            x += 1
        }
        var y = t0
        while y < t1 {
            let d = min(1, t1 - y)
            if !(y + d > 7.55 && y < 8.45) { items.append(seg(t0 - th, y, th, d)); items.append(seg(t1, y, th, d)) }
            y += 1
        }
        return items
    }

    /// Balloons drifting over the town with the day's wind, and their shadows on the ground.
    func skyBalloons() -> (shadows: [(inout TownPainter) -> Void], balloons: [(inout TownPainter) -> Void]) {
        let list: [(Double, Double, CGFloat, String, String)] = [(0, 2, 230, "#ff5e3a", "#ffc23d"), (5, 11, 300, "#14a39a", "#e8fff9"),
                                                                 (9, 4, 260, "#9b7be0", "#f2ebff"), (3, 7, 340, "#5aa9e6", "#eaf4fc")]
        var shadows: [(inout TownPainter) -> Void] = [], balloons: [(inout TownPainter) -> Void] = []
        let tt = t, wk = windK(1)
        // A brand's shaped balloon, flying over the region that signed the deal.
        if night == nil, let shape = s.adShape(over: s.region) {
            let gx = pmod(6 + tt * 0.1 * windK(2), 18) - 2, gy = 6 + sin(tt * 0.15) * 0.6
            let q = TownGeo.iso(gx, gy)
            shadows.append { p in p.blobShadow(q.x, q.y, 26, 10, 0.14) }
            balloons.append { p in AdShapeArt.draw(&p.c, shape, center: CGPoint(x: q.x, y: q.y - 380), size: 70 * 3.2) }
        }
        for (i, (gx0, gy0, alt, c1, c2)) in list.enumerated() where night == nil {
            let gx = pmod(gx0 + tt * 0.12 * wk + Double(i) * 3, 18) - 2, gy = gy0 + sin(tt * 0.2 + Double(i)) * 0.5
            let q = TownGeo.iso(gx, gy)
            shadows.append { p in p.blobShadow(q.x, q.y, 22, 9, 0.14) }
            balloons.append { p in p.balloon(q.x, q.y - alt, 30, [c1, c2], burn: (tt + Double(i)).truncatingRemainder(dividingBy: 4) < 0.5) }
        }
        return (shadows, balloons)
    }

    // MARK: Sky

    /// Sunrise behind the town, in screen space: sky, sun, clouds, distant balloons and ridges of fairy chimneys.
    mutating func backdrop(_ w: CGFloat, _ h: CGFloat) {
        let hz = TownGeo.horizon(v, height: h), px = v.ox * 0.08, p = 0.32
        if hz < 2 { return }
        let sky = grad([(mix("#1b1840", "#5f8fc6", p), 0), (mix("#6b3e6e", "#f0b48c", p), 0.5), (mix("#f08a4a", "#ffe2ac", p), 1)])
        c.fill(Path(CGRect(x: 0, y: 0, width: w, height: hz + 2)), with: .linearGradient(sky, startPoint: .zero, endPoint: pt(0, hz)))
        // Faint stars still fading at the top.
        var R = Mulberry32(seed: 11)
        for i in 0..<26 {
            let x = CGFloat(R.next()) * w, y = CGFloat(R.next()) * hz * 0.35
            let a = (0.15 + R.next() * 0.35) * (0.7 + 0.3 * sin(t * 1.5 + Double(i)))
            c.fill(Path(CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(Color.white.opacity(a)))
        }
        let sx = w * 0.74 + px, sy = hz - h * 0.045, sr = min(w, h) * 0.055
        let sun = grad([(rgba(255, 225, 160, 0.65), 0), (rgba(255, 170, 110, 0.25), 0.35), (rgba(255, 160, 110, 0), 1)])
        if night == nil { // no sun at night
            c.fill(Path(CGRect(x: sx - sr * 7, y: sy - sr * 7, width: sr * 14, height: sr * 14)),
                   with: .radialGradient(sun, center: pt(sx, sy), startRadius: 0, endRadius: sr * 7))
            ellipse(sx, sy, sr, sr, hex("#fff0c8"))
        }
        // Thin pink clouds lit from below.
        for i in 0..<4 {
            let cw = w * (0.28 + 0.1 * CGFloat(i % 2))
            let cx = CGFloat(pmod(Double(CGFloat(i) * w * 0.37 + CGFloat(t) * CGFloat(4 + i * 2) + px * 0.5), Double(w + cw))) - cw * 0.5
            let cy = hz * (0.3 + CGFloat(i) * 0.13)
            var cl = c
            cl.opacity = 0.5
            cl.fill(Path(ellipseIn: CGRect(x: cx - cw * 0.5, y: cy - (h * 0.007 + 2), width: cw, height: (h * 0.007 + 2) * 2)),
                    with: .color(mix("#c77a9a", "#ffd0b0", 0.25 + Double(i) * 0.18)))
            let ry = h * 0.006 + 2
            cl.fill(Path(ellipseIn: CGRect(x: cx + cw * 0.12 - cw * 0.3, y: cy - h * 0.006 - ry, width: cw * 0.6, height: ry * 2)),
                    with: .color(mix("#e89aa8", "#ffe2c4", 0.3 + Double(i) * 0.15)))
        }
        farBalloons(w, h, hz, px, layer: 0)
        // A far ridge with fairy chimney silhouettes, then a nearer one.
        // Albuquerque: mesa silhouettes; Luxor: palms on the far bank and the al-Qurn peak.
        let ridges: [(CGFloat, String, CGFloat, CGFloat, Double)]
        switch s.region {
        case .cap:
            ridges = [(0, ScenePainter.mixHex("#6b4a6e", "#d9a07a", 0.35), 0.05, 0.5, 3),
                      (0.025, ScenePainter.mixHex("#5a3a50", "#c48a6e", 0.3), 0.035, 1, 7)]
        case .abq:
            ridges = [(0, ScenePainter.mixHex("#8a4a6e", "#e09a8a", 0.4), 0.07, 0.5, 3),
                      (0.025, ScenePainter.mixHex("#6a3a50", "#c47a6e", 0.3), 0.03, 1, 7)]
        case .lux:
            ridges = [(0, ScenePainter.mixHex("#9a7a5e", "#e8c49a", 0.45), 0.06, 0.5, 3),
                      (0.025, ScenePainter.mixHex("#7a6a48", "#b8a070", 0.3), 0.02, 1, 7)]
        }
        for (k, colHex, amp, par, seed) in ridges {
            let col = hex(colHex), cap = mix(colHex, "#000000", 0.25)
            let base = hz + h * k, off = px * par
            var ridge = Path()
            ridge.move(to: pt(0, h))
            var x: CGFloat = -20
            while x <= w + 20 {
                let a = Double(x - off)
                let y = base - h * amp * CGFloat(0.5 + 0.5 * sin(a * 0.012 + seed) * 0.7 + 0.3 * sin(a * 0.031 + seed * 2))
                ridge.addLine(to: pt(x, y))
                x += 16
            }
            ridge.addLine(to: pt(w + 20, h))
            ridge.closeSubpath()
            c.fill(ridge, with: .color(col))
            var Rc = rng(seed * 13)
            for i in 0..<14 {
                let cx = CGFloat(pmod(Double(CGFloat(Rc.next()) * (w + 200) + off), Double(w + 200))) - 100
                let hh = h * (0.03 + CGFloat(Rc.next()) * 0.035) * (k > 0 ? 1.2 : 0.8)
                let by = base - h * amp * 0.35
                switch s.region {
                case .abq:
                    if i % 2 == 1 {
                        rect(cx - hh * 0.7, by - hh * 0.5, hh * 1.4, hh * 0.5 + 4, col)
                        poly([pt(cx - hh * 0.9, by + 4), pt(cx - hh * 0.7, by - hh * 0.5), pt(cx + hh * 0.7, by - hh * 0.5), pt(cx + hh * 0.9, by + 4)], col)
                    }
                case .lux:
                    if k > 0 { palmSil(cx, by + h * 0.02, hh * 0.9, col) }
                    else if i == 3 { poly([pt(cx - hh * 1.2, by + 4), pt(cx, by - hh * 1.3), pt(cx + hh * 1.2, by + 4)], col) }
                case .cap:
                    ScenePainter.chimney(&c, cx, by, hh * 0.42, hh, body: col, shade: nil, cap: cap)
                }
            }
        }
        farBalloons(w, h, hz, px, layer: 1)
    }

    /// Dozens of distant balloons drifting over the valley with the wind; the far ones hazier.
    mutating func farBalloons(_ w: CGFloat, _ h: CGFloat, _ hz: CGFloat, _ px: CGFloat, layer: Int) {
        if night != nil { return }
        let cols: [[String]] = [s.colors] + s.local.rivals.map { $0.colors } + [["#ff5e3a", "#ffc23d"], ["#14a39a", "#e8fff9"], ["#e0408a", "#ffd0e0"], ["#5aa9e6", "#eaf4fc"]]
        var R = Mulberry32(seed: layer == 1 ? 41 : 23)
        let n = layer == 1 ? 8 : 20, wk = windK(layer == 1 ? 2 : 3)
        for _ in 0..<n {
            let sp = (layer == 1 ? 5 : 2.5) + R.next() * 3, x0 = R.next() * Double(w + 120)
            let alt = hz * CGFloat(layer == 1 ? 0.12 + R.next() * 0.4 : 0.04 + R.next() * 0.3)
            let ph = R.next() * 7, col = cols[Int(R.next() * Double(cols.count)) % cols.count]
            let x = CGFloat(pmod(x0 + t * sp * wk + Double(px) * (layer == 1 ? 0.6 : 0.3), Double(w + 120))) - 60
            let y = hz - alt * CGFloat(1 + 0.03 * sin(t * 0.3 + ph)) + (layer == 1 ? 0 : h * 0.01)
            let r = CGFloat(layer == 1 ? 7 : 3.5) + CGFloat(R.next()) * (layer == 1 ? 4 : 2.5)
            balloon(x, y, r, col, burn: layer == 1 && (t + ph).truncatingRemainder(dividingBy: 5) < 0.35, alpha: layer == 1 ? 0.8 : 0.5)
        }
    }

    /// The valley floor's colors from the horizon down, per region.
    var groundColors: [String] {
        switch s.region {
        case .cap: return ["#d9a88a", "#e2b98e", "#e6c294"]
        case .abq: return ["#d4987a", "#dca67e", "#e2b384"]
        case .lux: return ["#c9b48a", "#c8be8a", "#cfc490"]
        }
    }

    /// The valley floor from the horizon down; returns where the ground starts.
    mutating func ground(_ w: CGFloat, _ h: CGFloat) -> CGFloat {
        let hz = max(0, TownGeo.horizon(v, height: h) + h * 0.015)
        let g = s.local.winter != nil ? grad([(hex("#c9d2e0"), 0), (hex("#dfe6ef"), 0.25), (hex("#eef2f8"), 1)])
            : grad([(hex(groundColors[0]), 0), (hex(groundColors[1]), 0.25), (hex(groundColors[2]), 1)])
        c.fill(Path(CGRect(x: 0, y: hz, width: w, height: max(0, h - hz))),
               with: .linearGradient(g, startPoint: pt(0, hz), endPoint: pt(0, max(hz + 1, h))))
        return hz
    }

    /// Haze where the ground meets the sky.
    mutating func haze(_ w: CGFloat, _ h: CGFloat) {
        let hz = TownGeo.horizon(v, height: h)
        if hz < -h * 0.2 { return }
        let g = grad([(rgba(236, 170, 135, 0), 0), (rgba(236, 172, 136, 0.75), 0.25), (rgba(232, 180, 140, 0.45), 0.45), (rgba(232, 190, 145, 0), 1)])
        c.fill(Path(CGRect(x: 0, y: hz - h * 0.05, width: w, height: h * 0.2)),
               with: .linearGradient(g, startPoint: pt(0, hz - h * 0.05), endPoint: pt(0, hz + h * 0.15)))
    }

    // MARK: Zones and labels

    private static let zoneFontSize: CGFloat = 95

    /// Text runs along +gx with "up" toward -gy; side zones run along -gy instead (up and to the right on screen).
    func zoneMatrix(_ z: TownZone) -> CGAffineTransform {
        let o = TownGeo.iso(z.gx, z.gy), a = TownGeo.TW / 200, b = TownGeo.TH / 200
        return z.side ? CGAffineTransform(a: a, b: -b, c: a, d: b, tx: o.x, ty: o.y)
            : CGAffineTransform(a: a, b: b, c: -a, d: b, tx: o.x, ty: o.y)
    }

    func zoneText(_ z: TownZone) -> Text {
        Text(loc(z.key)).font(.custom("BarlowCondensed-ExtraBold", fixedSize: Self.zoneFontSize))
    }

    /// The zone's text box on the ground, in world coordinates.
    func zoneQuad(_ z: TownZone) -> [CGPoint] {
        let w = Double(c.resolve(zoneText(z)).measure(in: CGSize(width: 4000, height: 400)).width) / 100
        let h = Double(Self.zoneFontSize) * 0.75 / 100
        if z.side {
            return [TownGeo.iso(z.gx - h - 0.15, z.gy + w / 2 + 0.2), TownGeo.iso(z.gx - h - 0.15, z.gy - w / 2 - 0.2),
                    TownGeo.iso(z.gx + 0.15, z.gy - w / 2 - 0.2), TownGeo.iso(z.gx + 0.15, z.gy + w / 2 + 0.2)]
        }
        return [TownGeo.iso(z.gx - w / 2 - 0.2, z.gy - h - 0.15), TownGeo.iso(z.gx + w / 2 + 0.2, z.gy - h - 0.15),
                TownGeo.iso(z.gx + w / 2 + 0.2, z.gy + 0.15), TownGeo.iso(z.gx - w / 2 - 0.2, z.gy + 0.15)]
    }

    /// Zone names written in the sand: a groove with a shadowed upper lip and a lit lower lip.
    mutating func zoneText() {
        let a = Double(min(max(1.25 - v.z, 0.35), 0.85))
        for z in Town.zones {
            var g = c
            g.concatenate(zoneMatrix(z))
            g.opacity = a
            let base = zoneText(z)
            for (dy, col) in [(CGFloat(6), rgba(255, 248, 232, 0.9)), (0, rgba(96, 56, 30, 0.85)), (3, rgba(150, 98, 60, 0.75))] {
                g.draw(base.foregroundColor(col), at: pt(0, dy), anchor: .bottom)
            }
        }
    }

    /// Building labels once zoomed in, red dots on zones that need you, and the tap targets.
    mutating func labels(_ bs: [TownBuilding]) -> TownHits {
        var hits = TownHits()
        let z = v.z, full = z >= TownGeo.labelZoom, sc = min(max(z / 0.5, 0.75), 1.15)
        var taken: [CGRect] = []
        // Big buildings label before small ones (the mast, kiosks, the bazaar), and front ones first, so a small
        // sign never hides a building's name (as in the prototype).
        for b in bs.sorted(by: { $0.small != $1.small ? !$0.small : ($0.gx + $0.gy) > ($1.gx + $1.gy) }) {
            let m = iso(b.gx + b.w / 2, b.gy + b.d / 2)
            let sx = m.x * z + v.ox, sy = (m.y - CGFloat(Town.labelTop(b))) * z + v.oy
            let pts = [iso(b.gx, b.gy), iso(b.gx + b.w, b.gy), iso(b.gx + b.w, b.gy + b.d), iso(b.gx, b.gy + b.d)].map { v.screen($0) }
            let bottom = pts.map(\.y).max() ?? sy
            let half = 50 * z / 0.5
            hits.buildings.append(.init(b: b, pts: pts, box: CGRect(x: sx - half, y: sy - 30, width: half * 2, height: max(0, bottom - sy + 30)),
                                        depth: b.gx + b.gy))
            if full && !v.noLabels && night == nil { label(b, sx, sy, sc, &taken) }
        }
        let alerts = Town.alerts(s)
        for zn in Town.zones {
            guard let al = zn.alert, alerts.contains(al) else { continue }
            let q = v.screen(zoneQuad(zn)[1]), r = 7 + CGFloat(sin(t * 4)) * 1.2
            ellipse(q.x + 4 + 6, q.y - 6, r + 2, r + 2, .white)
            ellipse(q.x + 4 + 6, q.y - 6, r, r, hex("#e5432f"))
        }
        if !full {
            hits.zones = Town.zones.map { .init(zone: $0, pts: zoneQuad($0).map { v.screen($0) }) }
        }
        let field = [iso(1, 4.4), iso(7, 4.4), iso(7, 7.2), iso(1, 7.2)]
        hits.field = [field.map { v.screen($0) }, field.map { v.screen(CGPoint(x: $0.x, y: $0.y - 90)) }]
        return hits
    }

    /// Name tag above a building, with its state below the name. Skipped when it would cover another.
    mutating func label(_ b: TownBuilding, _ sx: CGFloat, _ sy: CGFloat, _ sc: CGFloat, _ taken: inout [CGRect]) {
        let fn = ((b.small ? 13 : 16) * sc).rounded(), fs = ((b.small ? 11 : 13) * sc).rounded()
        let locked = b.lv == -1, plot = b.lv == 0 && b.look != .kiosk
        let name = c.resolve(Text(b.name).font(.custom("BarlowCondensed-ExtraBold", fixedSize: fn))
            .foregroundColor(locked ? .white : Theme.ink))
        let sub = c.resolve(Text(b.sub).font(.custom("Barlow-SemiBold", fixedSize: fs))
            .foregroundColor(plot ? hex("#ff5e3a") : locked ? Color.white.opacity(0.75) : Theme.ink2))
        let nw = name.measure(in: CGSize(width: 600, height: 100)).width, sw = sub.measure(in: CGSize(width: 600, height: 100)).width
        let w = max(nw, sw) + 16 * sc, hh = fn + fs + 14
        let r = CGRect(x: sx - w / 2, y: sy - hh, width: w, height: hh)
        if taken.contains(where: { $0.intersects(r) }) { return }
        taken.append(r)
        let shape = Path(roundedRect: r, cornerRadius: 9 * sc)
        c.fill(shape, with: .color(locked ? Color(red: 43 / 255, green: 35 / 255, blue: 80 / 255).opacity(0.72) : Color(red: 1, green: 250 / 255, blue: 243 / 255).opacity(0.94)))
        if plot { c.stroke(shape, with: .color(hex("#ff5e3a")), lineWidth: 1.5) }
        c.draw(name, at: pt(sx, r.minY + 4), anchor: .top)
        c.draw(sub, at: pt(sx, sy - 5), anchor: .bottom)
    }
}

extension GameState {
    /// The launch field's balloons (v110): shaped envelopes first, then other designs, then the flagship, then the
    /// rest in fleet order. The field shows the first six.
    var fieldBalloons: [Balloon] {
        func rank(_ b: Balloon) -> Int {
            if let d = design(of: b) { return d.shape != nil ? 0 : 1 }
            return b.id == local.flagship ? 2 : 3
        }
        return local.balloons.enumerated().sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }.map(\.element)
    }
}
