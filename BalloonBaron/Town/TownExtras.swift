import SwiftUI
import BalloonBaronCore

// Town pieces from prototype v75–v85: the wind mast, the bazaar, the bazaar's decorations,
// festival bunting and winter snow.
extension TownPainter {
    /// A roof color under snow in winter.
    func snowy(_ col: String) -> String { s.local.winter != nil ? TownPainter.hexMix(col, "#f4f7fb", 0.7) : col }

    static func hexMix(_ a: String, _ b: String, _ k: Double) -> String {
        func rgb(_ h: String) -> [Double] {
            let v = UInt64(h.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
            return [Double((v >> 16) & 0xff), Double((v >> 8) & 0xff), Double(v & 0xff)]
        }
        let A = rgb(a), B = rgb(b)
        return "#" + zip(A, B).map { String(format: "%02x", Int((($0 + ($1 - $0) * k)).rounded())) }.joined()
    }

    // MARK: Wind mast

    /// A tuff plinth, a tall striped mast with a cup anemometer and a windsock showing the ground wind.
    /// Level 2 adds a white instrument box, level 3 a radar dome.
    mutating func windMast(_ gx: Double, _ gy: Double) {
        let f = block(gx - 0.17, gy - 0.17, 0.34, 0.34, 14, courses: false)
        let q = lp(f.a, f.c, 0.5), H: CGFloat = 128, lvl = s.level(.mast)
        if lvl >= 2 {
            let sb = iso(gx + 0.45, gy + 0.1)
            rect(sb.x - 1, sb.y - 22, 2, 22, hex("#5a3a20"))
            rect(sb.x - 9, sb.y - 36, 18, 15, hex("#fbfcfd"))
            for i in 0..<4 { line(pt(sb.x - 8, sb.y - 33 + CGFloat(i) * 3.5), pt(sb.x + 8, sb.y - 33 + CGFloat(i) * 3.5), hex("#c9ccd2"), 1) }
            poly([pt(sb.x - 11, sb.y - 36), pt(sb.x, sb.y - 42), pt(sb.x + 11, sb.y - 36)], hex("#e8ecef"))
        }
        if lvl >= 3 {
            let rd = iso(gx - 0.2, gy + 0.55)
            block(gx - 0.38, gy + 0.38, 0.36, 0.36, 18, lit: "#e8ecef", shade: "#b8bec6", top: "#f4f6f8", courses: false)
            var dome = Path()
            dome.addArc(center: pt(rd.x, rd.y - 28), radius: 15, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            c.fill(dome, with: .radialGradient(Gradient(colors: [.white, hex("#c9ced6")]), center: pt(rd.x - 6, rd.y - 40), startRadius: 2, endRadius: 18))
        }
        let v = s.weather?.layers.first ?? 2, dir: CGFloat = v < 0 ? -1 : 1, k = CGFloat(min(max(abs(v) / 6, 0.15), 1))
        for i in 0..<8 { rect(q.x - 2.5, q.y - H * CGFloat(i + 1) / 8, 5, H / 8 + 0.5, hex(i % 2 == 1 ? "#fffaf3" : "#ff5e3a")) }
        rect(q.x + 0.5, q.y - H, 2, H, rgba(0, 0, 0, 0.18))
        // Cup anemometer, spinning with the wind.
        let ty = q.y - H - 6, sp = t * (2 + Double(k) * 10)
        line(pt(q.x, q.y - H), pt(q.x, ty), hex("#3a2416"), 1.5)
        for i in 0..<3 {
            let a = sp + Double(i) * 2.094, x = q.x + CGFloat(cos(a)) * 11, y = ty + CGFloat(sin(a)) * 3.5
            line(pt(q.x, ty), pt(x, y), hex("#3a2416"), 1.5)
            ellipse(x, y, 3.2, 3.2, hex(sin(a) > 0 ? "#e8ecef" : "#aeb6bd"))
        }
        // The sock: five rings, stiff in a strong wind, drooping when calm, fluttering a little.
        let sy = q.y - H + 10, len: CGFloat = 46
        line(pt(q.x, sy), pt(q.x + dir * 6, sy), hex("#3a2416"), 2)
        func droop(_ u: CGFloat) -> CGFloat { (1 - k) * pow(u, 1.5) * 34 + CGFloat(sin(t * (4 + Double(k) * 6) + Double(u) * 5)) * 2.2 * u }
        func rad(_ u: CGFloat) -> CGFloat { 8 - u * 3.5 - (1 - k) * u * 2 }
        for i in 0..<5 {
            let u0 = CGFloat(i) / 5, u1 = CGFloat(i + 1) / 5, reach = len * (0.45 + k * 0.55)
            let x0 = q.x + dir * (6 + u0 * reach), x1 = q.x + dir * (6 + u1 * reach), y0 = sy + droop(u0), y1 = sy + droop(u1)
            poly([pt(x0, y0 - rad(u0)), pt(x1, y1 - rad(u1)), pt(x1, y1 + rad(u1)), pt(x0, y0 + rad(u0))], hex(i % 2 == 1 ? "#fffaf3" : "#ff5e3a"))
        }
        let reach = len * (0.45 + k * 0.55)
        poly([pt(q.x + dir * 6, sy + 2), pt(q.x + dir * (6 + reach), sy + (1 - k) * 34 + 2), pt(q.x + dir * (6 + reach), sy + (1 - k) * 34 + 5), pt(q.x + dir * 6, sy + 8)],
             rgba(90, 40, 20, 0.18))
    }

    // MARK: Bazaar

    /// v128: a row of three awning shops on the main road by the square (`marketRow`, TownIdentity.swift).
    mutating func bazaar(_ b: TownBuilding) { marketRow(b) }

    // MARK: Decorations

    /// Lantern posts along the main roads (with the bazaar's lantern strings).
    static let lanternSpots: [(Double, Double)] = [(2, 7.4), (5, 7.4), (10.5, 7.4), (13.5, 7.4), (7.4, 2), (7.4, 5.5), (7.4, 10.5), (7.4, 13.5)]
    /// v128: Hezarfen's statue stands at the square's north-east corner since the bazaar took the south-west one.
    static let statueAt: (Double, Double) = (9.05, 6.95)
    static let flagSpots: [(Double, Double)] = [(0, 4), (0, 11), (4, 15.3), (11, 15.3), (15.3, 6.6), (15.3, 11)]

    func decorations() -> [TownItem] {
        var items: [TownItem] = []
        let tt = t, colors = s.colors
        if s.placed(.fountain) {
            items.append(TownItem(depth: 16.2, draw: { p in p.fountain(TownGeo.iso(8, 8), tt) }))
        }
        if s.placed(.statue) {
            let a = Self.statueAt
            items.append(TownItem(depth: 16, shadow: { p in let q = TownGeo.iso(a.0, a.1); p.blobShadow(q.x + 18, q.y + 4, 18, 6, 0.16) },
                                  draw: { p in p.statue(TownGeo.iso(a.0, a.1)) }))
        }
        if s.placed(.lanterns) {
            for (gx, gy) in Self.lanternSpots { items.append(TownItem(depth: gx + gy, draw: { p in p.lanternPost(TownGeo.iso(gx, gy), tt, gx) })) }
        }
        if s.placed(.flags) {
            for (gx, gy) in Self.flagSpots { items.append(TownItem(depth: gx + gy + 0.6, draw: { p in p.companyFlag(TownGeo.iso(gx, gy), tt, colors, gx) })) }
        }
        return items
    }

    mutating func fountain(_ p: CGPoint, _ tt: Double) {
        ellipse(p.x, p.y, 34, 17, hex("#d9c2a0"))
        rect(p.x - 34, p.y - 8, 68, 8, hex("#b89a74"))
        ellipse(p.x, p.y - 8, 34, 17, hex("#e8d6b6"))
        ellipse(p.x, p.y - 9, 28, 13, hex("#4ab8d0"))
        rect(p.x - 4, p.y - 30, 8, 22, hex("#d9c2a0"))
        ellipse(p.x, p.y - 30, 12, 5, hex("#d9c2a0"))
        var jets = Path()
        for i in 0..<6 {
            let a = Double(i) / 6 * .pi * 2 + tt, ex = p.x + CGFloat(cos(a)) * 22, ey = p.y - 9 + CGFloat(sin(a)) * 9
            jets.move(to: pt(p.x, p.y - 34))
            jets.addQuadCurve(to: pt(ex, ey), control: pt((p.x + ex) / 2, p.y - 44))
        }
        c.stroke(jets, with: .color(rgba(200, 240, 255, 0.85)), lineWidth: 1.5)
    }

    /// Hezarfen with his wings spread, in bronze, on a tuff plinth.
    mutating func statue(_ p: CGPoint) {
        rect(p.x - 10, p.y - 22, 20, 22, hex("#c8b090"))
        rect(p.x + 2, p.y - 22, 8, 22, hex("#a8906e"))
        let q = pt(p.x, p.y - 22)
        rect(q.x - 3, q.y - 22, 6, 22, hex("#8a6a3a"))
        ellipse(q.x, q.y - 26, 4.5, 4.5, hex("#8a6a3a"))
        ellipse(q.x, q.y - 31, 5, 3, hex("#f2eee6"))
        for sgn: CGFloat in [-1, 1] {
            poly([pt(q.x, q.y - 18), pt(q.x + sgn * 26, q.y - 30), pt(q.x + sgn * 22, q.y - 14)], hex("#a07c44"))
        }
    }

    mutating func lanternPost(_ p: CGPoint, _ tt: Double, _ ph: Double) {
        rect(p.x - 1.5, p.y - 40, 3, 40, hex("#3a2a20"))
        rect(p.x - 6, p.y - 41, 12, 2, hex("#3a2a20"))
        let on = 0.7 + 0.3 * sin(tt * 2 + ph)
        glow(p.x, p.y - 46, 22, Color(red: 1, green: 190 / 255, blue: 90 / 255), 0.35 * on)
        ellipse(p.x, p.y - 46, 4, 6, hex("#ffcf6a"))
        rect(p.x - 4, p.y - 53, 8, 2, hex("#b8582e"))
    }

    mutating func companyFlag(_ p: CGPoint, _ tt: Double, _ colors: [String], _ ph: Double) {
        line(p, pt(p.x, p.y - 80), hex("#4a3a2a"), 2)
        var f = Path()
        f.move(to: pt(p.x, p.y - 80))
        for i in 0...8 { f.addLine(to: pt(p.x + CGFloat(i) * 3.5, p.y - 80 + CGFloat(sin(tt * 4 + Double(i) * 0.8 + ph)) * 2)) }
        for i in stride(from: 8, through: 0, by: -1) { f.addLine(to: pt(p.x + CGFloat(i) * 3.5, p.y - 62 + CGFloat(sin(tt * 4 + Double(i) * 0.8 + ph)) * 2)) }
        f.closeSubpath()
        c.fill(f, with: .color(hex(colors.first ?? "#ff5e3a")))
        rect(p.x + 8, p.y - 74 + CGFloat(sin(tt * 4 + 2.5 + ph)) * 2, 12, 5, hex(colors.count > 1 ? colors[1] : "#ffc23d"))
    }

    /// Festival days: bunting strung along the main roads.
    func bunting() -> [TownItem] {
        guard s.local.festival != nil else { return [] }
        let tt = t
        let spans: [(Double, Double)] = [(7.5, 1), (7.5, 5), (7.5, 9.5), (1, 7.5), (4.5, 7.5), (10.5, 7.5)]
        return spans.map { along in
            let onX = along.1 == 7.5
            let a = onX ? (along.0, 7.45) : (7.45, along.1), b = onX ? (along.0 + 3, 7.45) : (7.45, along.1 + 3)
            return TownItem(depth: a.0 + a.1 + 1.5, draw: { p in
                let P = TownGeo.iso(a.0, a.1), Q = TownGeo.iso(b.0, b.1), H: CGFloat = 46
                for r in [P, Q] { p.line(r, p.pt(r.x, r.y - H), p.hex("#5a3a20"), 2.5) }
                var wire = Path()
                wire.move(to: p.pt(P.x, P.y - H))
                wire.addQuadCurve(to: p.pt(Q.x, Q.y - H), control: p.pt((P.x + Q.x) / 2, (P.y + Q.y) / 2 - H + 14))
                p.c.stroke(wire, with: .color(p.hex("#5a3a20")), lineWidth: 1)
                let cols = ["#ff5e3a", "#ffc23d", "#14a39a", "#9b7be0", "#ff6fa8"]
                for i in 1..<10 {
                    let k = CGFloat(i) / 10, x = P.x + (Q.x - P.x) * k
                    let y = P.y + (Q.y - P.y) * k - H + 14 * 4 * k * (1 - k) + CGFloat(sin(tt * 3 + Double(i))) * 0.8
                    p.poly([p.pt(x - 4, y), p.pt(x + 4, y), p.pt(x, y + 9)], p.hex(cols[i % 5]))
                }
            })
        }
    }

    /// Winter: snow falling over the town, in screen space.
    mutating func snowfall(_ w: CGFloat, _ h: CGFloat) {
        var flakes = Path()
        for i in 0..<120 {
            let d = Double(i)
            let x = CGFloat((d * 97.3 + t * (10 + Double(i % 4) * 6) + sin(t + d) * 8).truncatingRemainder(dividingBy: Double(w) + 20)) - 10
            let y = CGFloat((d * 53.7 + t * (22 + Double(i % 5) * 8)).truncatingRemainder(dividingBy: Double(h)))
            let r = 1.1 + CGFloat(i % 3) * 0.6
            flakes.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        c.fill(flakes, with: .color(.white.opacity(0.9)))
    }
}
