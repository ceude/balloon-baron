import SwiftUI
import BalloonBaronCore

/// The v113 town decorations (€0,49 each): a pigeon flock, welcome arches over the roads into town, a garden café and a
/// kilim display. Each draws round a ground point on any context, so the bazaar's thumbnails use the same drawing.
/// Port of `decoPigeons`, `decoArch`, `decoCafe`, `decoRugs`.
struct DecorPainter {
    var c: GraphicsContext

    /// v125.x: each arch stands in a gap of the town wall where a main road leaves: its posts on the wall's line (15.57),
    /// flush against the wall ends (`TownPainter.wallGap`, 7.3–8.7), outside the road's edges (7.55–8.45).
    static let arches: [((Double, Double), (Double, Double), Double)] = [((7.37, 15.57), (8.63, 15.57), 23.2), ((15.57, 7.37), (15.57, 8.63), 23.2)]
    static let cafeAt = (14.9, 1.1), rugsAt = (2.5, 0.35), plaqueAt = (9.15, 6.55)

    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    func hex(_ h: String) -> Color { Color(hex: h) }
    /// One tile along the two grid axes from p.
    func iu(_ p: CGPoint, _ u: CGFloat, _ v: CGFloat) -> CGPoint { pt(p.x + (u - v) * TownGeo.TW / 2, p.y + (u + v) * TownGeo.TH / 2) }
    mutating func fill(_ pts: [CGPoint], _ col: Color) {
        var p = Path(); p.move(to: pts[0]); for q in pts.dropFirst() { p.addLine(to: q) }; p.closeSubpath()
        c.fill(p, with: .color(col))
    }
    mutating func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: Color) { c.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(col)) }
    mutating func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ col: Color) { c.fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), with: .color(col)) }

    /// A flock wheeling round a centre, grey rock pigeons and a few white ones, wings beating.
    mutating func pigeons(_ ctr: CGPoint, _ t: Double, _ sc: CGFloat = 1) {
        for i in 0..<16 {
            let d = Double(i), ph = d * 2.399, a = t * 0.42 + d * 0.19
            let rx = CGFloat(210 + Double(i % 4) * 18) * sc, ry = CGFloat(60 + Double(i % 3) * 12) * sc
            let x = ctr.x + CGFloat(cos(a)) * rx + CGFloat(sin(ph)) * 16 * sc
            let y = ctr.y + CGFloat(sin(a)) * ry + CGFloat(cos(ph * 1.3)) * 10 * sc + CGFloat(sin(t * 1.7 + d)) * 4 * sc
            let f = CGFloat(sin(t * 13 + ph)), w = 13 * sc, dir: CGFloat = sin(a) > 0 ? -1 : 1
            let col = hex(i % 5 == 0 ? "#f4f1ea" : i % 2 == 1 ? "#5d6480" : "#7a819b")
            bird(x, y, w, f, col, 3.6 * sc)
            oval(x + dir * 1.5 * sc, y + 0.5 * sc, 3.4 * sc, 2.1 * sc, col)
        }
    }

    mutating func bird(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ f: CGFloat, _ col: Color, _ lw: CGFloat) {
        var p = Path()
        p.move(to: pt(x - w, y - 3 * f * lw / 3.6))
        p.addQuadCurve(to: pt(x, y), control: pt(x - w * 0.4, y - lw * 0.55 - 2 * f * lw / 3.6))
        p.addQuadCurve(to: pt(x + w, y - 3 * f * lw / 3.6), control: pt(x + w * 0.4, y - lw * 0.55 - 2 * f * lw / 3.6))
        c.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: lw, lineCap: .round))
    }

    /// The arch between two pillars, in the company colours, the name on a sign and a little balloon on top.
    mutating func arch(_ p: CGPoint, _ q: CGPoint, _ t: Double, _ colors: [String], _ name: String) {
        let H: CGFloat = 66, mx = (p.x + q.x) / 2, my = (p.y + q.y) / 2 - H
        let c0 = hex(colors.first ?? "#ff5e3a"), c1 = hex(colors.count > 1 ? colors[1] : "#ffc23d")
        for r in [p, q] {
            rect(r.x - 4.5, r.y - H, 9, H, hex("#c8a67a")); rect(r.x + 1.5, r.y - H, 3, H, hex("#a07e52"))
            rect(r.x - 6.5, r.y - H - 4, 13, 5, hex("#ead6ae")); rect(r.x - 6.5, r.y - 6, 13, 6, hex("#ead6ae"))
        }
        var arc = Path(); arc.move(to: pt(p.x, p.y - H)); arc.addQuadCurve(to: pt(q.x, q.y - H), control: pt(mx, my - 30))
        c.stroke(arc, with: .color(c0), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        c.stroke(arc, with: .color(c1), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 7], dashPhase: CGFloat(-t * 6)))
        var an = atan2(Double(q.y - p.y), Double(q.x - p.x))
        if an > .pi / 2 { an -= .pi }
        if an < -.pi / 2 { an += .pi }
        var g = c
        g.translateBy(x: mx, y: my - 13)
        g.rotate(by: .radians(an * 0.6))
        // The sign holds about 60 pt: a long name shrinks down to 8 pt, then a name of several words becomes its
        // initials and one long word is cut short (prototype `archLabel`).
        func resolved(_ s: String) -> GraphicsContext.ResolvedText {
            g.resolve(Text(s).font(.custom("BarlowCondensed-ExtraBold", fixedSize: 11)).foregroundColor(c1))
        }
        var label = resolved(name)
        let w8 = label.measure(in: CGSize(width: 400, height: 40)).width * 8 / 11
        if w8 > 60 {
            let words = name.split(whereSeparator: \.isWhitespace)
            if words.count > 1 {
                label = resolved(words.prefix(4).map { String($0.prefix(1)).uppercased(with: Locale(identifier: "tr")) }.joined())
            } else {
                // One long word: as much as fits.
                label = resolved(String(name.prefix(max(1, Int(CGFloat(name.count) * 60 / w8) - 1))) + ".")
            }
        }
        let tw = label.measure(in: CGSize(width: 400, height: 40)).width, sw = min(70, tw + 14), k = min(1, (sw - 10) / max(1, tw))
        g.fill(Path(CGRect(x: -1, y: -24, width: 2, height: 10)), with: .color(hex("#5a3a24")))
        let sign = Path(roundedRect: CGRect(x: -sw / 2, y: -8, width: sw, height: 16), cornerRadius: 4)
        g.fill(sign, with: .color(c0)); g.stroke(sign, with: .color(.white.opacity(0.7)), lineWidth: 1)
        var tg = g; tg.scaleBy(x: k, y: k); tg.draw(label, at: .zero, anchor: .center)
        let by: CGFloat = -30 + CGFloat(sin(t * 1.5)) * 1.5
        g.fill(Path(ellipseIn: CGRect(x: -6, y: by - 13, width: 12, height: 14)), with: .color(c0))
        g.fill(Path(CGRect(x: -1.2, y: by - 13, width: 2.4, height: 13)), with: .color(c1))
        g.fill(Path(CGRect(x: -2, y: by + 1, width: 4, height: 3)), with: .color(hex("#7a4e2a")))
    }

    /// A timber deck with four tables under striped parasols, tea steaming in the glasses.
    mutating func cafe(_ p: CGPoint, _ t: Double) {
        let d = [iu(p, -0.75, -0.75), iu(p, 0.75, -0.75), iu(p, 0.75, 0.75), iu(p, -0.75, 0.75)]
        fill(d, hex("#b98656"))
        for i in 1..<6 {
            let a = iu(p, -0.75 + CGFloat(i) * 0.25, -0.75), b = iu(p, -0.75 + CGFloat(i) * 0.25, 0.75)
            var l = Path(); l.move(to: a); l.addLine(to: b); c.stroke(l, with: .color(Color(red: 80 / 255, green: 45 / 255, blue: 20 / 255).opacity(0.3)), lineWidth: 1)
        }
        fill([d[2], d[3], pt(d[3].x, d[3].y + 4), pt(d[2].x, d[2].y + 4)], hex("#8a5a32"))
        fill([d[1], d[2], pt(d[2].x, d[2].y + 4), pt(d[1].x, d[1].y + 4)], hex("#6e4626"))
        let cols = [("#c2401f", "#fff3dc"), ("#14a39a", "#fff3dc"), ("#e0a020", "#fff3dc"), ("#2b4a8a", "#fff3dc")]
        for (i, uv) in [(-0.38, -0.36), (0.36, -0.3), (-0.3, 0.38), (0.4, 0.4)].enumerated() {
            let q = iu(p, CGFloat(uv.0), CGFloat(uv.1))
            for s2: CGFloat in [-1, 1] { rect(q.x + s2 * 9 - 2, q.y - 7, 4, 7, hex("#6a4024")); rect(q.x + s2 * 9 - 3, q.y - 12, 2, 6, hex("#6a4024")) }
            rect(q.x - 1, q.y - 10, 2, 10, hex("#3a2a20")); oval(q.x, q.y - 10, 8, 3.5, hex("#f6eedd"))
            rect(q.x - 3, q.y - 14, 2, 4, hex("#c0392b")); rect(q.x + 2, q.y - 14, 2, 4, hex("#c0392b"))
            var steam = Path(); let sy = q.y - 16
            steam.move(to: pt(q.x - 2, sy)); steam.addQuadCurve(to: pt(q.x - 2, sy - 9), control: pt(q.x - 4 + CGFloat(sin(t * 3 + Double(i))) * 2, sy - 5))
            c.stroke(steam, with: .color(.white.opacity(0.5)), lineWidth: 0.8)
            rect(q.x - 0.8, q.y - 38, 1.6, 28, hex("#4a3a2a"))
            let top = q.y - 40, R: CGFloat = 17
            for k in 0..<8 {
                let a0 = Double.pi + Double(k) * .pi / 8, a1 = a0 + .pi / 8
                fill([pt(q.x, top - 6), pt(q.x + CGFloat(cos(a0)) * R, top + 4 - CGFloat(sin(a0)) * 2), pt(q.x + CGFloat(cos(a1)) * R, top + 4 - CGFloat(sin(a1)) * 2)],
                     hex(k % 2 == 0 ? cols[i].0 : cols[i].1))
            }
        }
    }

    /// Three kilims on a line between two posts, swaying, a pile of cushions below.
    mutating func rugs(_ p: CGPoint, _ t: Double) {
        let P = iu(p, -0.85, 0), Q = iu(p, 0.85, 0), H: CGFloat = 48
        for r in [P, Q] { rect(r.x - 2, r.y - H - 4, 4, H + 4, hex("#5a3a24")) }
        var wire = Path(); wire.move(to: pt(P.x, P.y - H)); wire.addLine(to: pt(Q.x, Q.y - H)); c.stroke(wire, with: .color(hex("#3a2418")), lineWidth: 1.2)
        let rugs = [["#b8322a", "#e6b04a", "#2b2350"], ["#2b4a8a", "#ead8b0", "#c2401f"], ["#c96a2a", "#3a2a5a", "#f2e2b8"]]
        for (i, col) in rugs.enumerated() {
            let f0 = 0.06 + CGFloat(i) * 0.31, f1 = f0 + 0.27
            let A = pt(P.x + (Q.x - P.x) * f0, P.y + (Q.y - P.y) * f0 - H), B = pt(P.x + (Q.x - P.x) * f1, P.y + (Q.y - P.y) * f1 - H)
            let rh: CGFloat = 34, sw = CGFloat(sin(t * 1.4 + Double(i) * 1.7)) * 2.2
            for (k, cc) in [(CGFloat(0), col[0]), (0.12, col[1]), (0.2, col[0])] {
                let a = pt(A.x + (B.x - A.x) * k, A.y + (B.y - A.y) * k), b2 = pt(B.x + (A.x - B.x) * k, B.y + (A.y - B.y) * k)
                fill([pt(a.x, a.y + rh * k * 0.5), pt(b2.x, b2.y + rh * k * 0.5), pt(b2.x + sw, b2.y + rh - rh * k * 0.5), pt(a.x + sw, a.y + rh - rh * k * 0.5)], hex(cc))
            }
            let cx = (A.x + B.x) / 2 + sw / 2, cy = (A.y + B.y) / 2 + rh / 2
            fill([pt(cx, cy - 9), pt(cx + 6, cy), pt(cx, cy + 9), pt(cx - 6, cy)], hex(col[2]))
            fill([pt(cx, cy - 4), pt(cx + 2.6, cy), pt(cx, cy + 4), pt(cx - 2.6, cy)], hex(col[1]))
            var fr = Path()
            for k in 0..<6 { let f = (CGFloat(k) + 0.5) / 6, x = A.x + (B.x - A.x) * f + sw, y = A.y + (B.y - A.y) * f + rh; fr.move(to: pt(x, y)); fr.addLine(to: pt(x, y + 3)) }
            c.stroke(fr, with: .color(hex(col[1])), lineWidth: 1)
        }
        for (i, col) in ["#c2401f", "#e0a020", "#14a39a", "#9b5ab0"].enumerated() {
            let q = iu(p, -0.3 + CGFloat(i) * 0.22, 0.35)
            c.fill(Path(roundedRect: CGRect(x: q.x - 7, y: q.y - 6 - CGFloat(i % 2) * 4, width: 14, height: 7), cornerRadius: 3), with: .color(hex(col)))
        }
    }

    /// v115: the Supporter Edition's brass plaque on two posts by the square, a heart and your company's name.
    mutating func plaque(_ p: CGPoint, _ company: String) {
        rect(p.x - 13, p.y - 22, 3, 22, hex("#4a2e1a")); rect(p.x + 10, p.y - 22, 3, 22, hex("#4a2e1a"))
        c.fill(Path(roundedRect: CGRect(x: p.x - 17, y: p.y - 38, width: 34, height: 20), cornerRadius: 3), with: .color(hex("#6a4024")))
        c.fill(Path(roundedRect: CGRect(x: p.x - 15, y: p.y - 36, width: 30, height: 16), cornerRadius: 2),
               with: .linearGradient(Gradient(colors: [hex("#ffe39a"), hex("#e8b04a"), hex("#b07a1e")]), startPoint: pt(0, p.y - 36), endPoint: pt(0, p.y - 20)))
        oval(p.x - 1.6, p.y - 31, 1.8, 1.8, hex("#c2401f")); oval(p.x + 1.6, p.y - 31, 1.8, 1.8, hex("#c2401f"))
        fill([pt(p.x - 3.3, p.y - 30.4), pt(p.x, p.y - 27), pt(p.x + 3.3, p.y - 30.4)], hex("#c2401f"))
        var t = c
        t.translateBy(x: p.x, y: p.y - 22.5)
        let r = t.resolve(Text(company).font(.custom("Barlow-Bold", fixedSize: 4.5)).foregroundColor(hex("#5a3a10")))
        let w = r.measure(in: CGSize(width: 400, height: 20)).width, k = min(1, 26 / max(1, w))
        t.scaleBy(x: k, y: k)
        t.draw(r, at: .zero, anchor: .bottom)
    }

    /// The bazaar thumbnail of the pigeons: a dovecote on a pole with pigeons flying round it (64 × 72 units).
    mutating func dovecote() {
        rect(30.5, 36, 3.5, 22, hex("#6a4a30")); rect(21, 24, 22, 14, hex("#e8d2ac")); rect(34, 24, 9, 14, hex("#c9ad84"))
        fill([pt(18, 25), pt(32, 14), pt(46, 25)], hex("#b8582e"))
        for x: CGFloat in [25, 32, 39] { oval(x, 31, 2.2, 2.2, hex("#3a2418")) }
        rect(21, 33.5, 22, 1.5, hex("#8a6a4a"))
        let birds: [(CGFloat, CGFloat, CGFloat)] = [(10, 12, 1), (20, 5, -0.5), (47, 7, 0.7), (55, 17, -1), (8, 27, 0.3), (55, 33, -0.8), (38, 3, 0.9)]
        for (i, b) in birds.enumerated() { bird(b.0, b.1, 6.5, b.2 * 0.66, hex(i % 3 == 0 ? "#ffffff" : "#4f5674"), 2.4) }
    }
}

extension TownPainter {
    /// v113 decorations in the town, depth-sorted like the others.
    func newDecorations() -> [TownItem] {
        var items: [TownItem] = []
        let tt = t, colors = s.colors, name = s.company, nk = night?.k ?? 0
        if s.owned(.arch) {
            for (P, Q, dp) in DecorPainter.arches {
                items.append(TownItem(depth: dp, draw: { p in var d = DecorPainter(c: p.c); d.arch(TownGeo.iso(P.0, P.1), TownGeo.iso(Q.0, Q.1), tt, colors, name) }))
            }
        }
        if s.owned(.cafe) {
            let a = DecorPainter.cafeAt
            items.append(TownItem(depth: a.0 + a.1, shadow: { p in let q = TownGeo.iso(a.0, a.1); p.blobShadow(q.x, q.y + 4, 70, 22, 0.1) },
                                  draw: { p in var d = DecorPainter(c: p.c); d.cafe(TownGeo.iso(a.0, a.1), tt) }))
        }
        if s.owned(.supporter) {
            let a = DecorPainter.plaqueAt
            items.append(TownItem(depth: a.0 + a.1, draw: { p in var d = DecorPainter(c: p.c); d.plaque(TownGeo.iso(a.0, a.1), name) }))
        }
        if s.owned(.rugs) {
            let a = DecorPainter.rugsAt
            items.append(TownItem(depth: a.0 + a.1, draw: { p in var d = DecorPainter(c: p.c); d.rugs(TownGeo.iso(a.0, a.1), tt) }))
        }
        // pigeons roost at night
        if s.owned(.pigeons) && nk < 0.3 {
            items.append(TownItem(depth: 99, draw: { p in
                var g = p.c
                g.opacity = 1 - nk / 0.3
                var d = DecorPainter(c: g)
                let q = TownGeo.iso(7.5, 5.5)
                d.pigeons(CGPoint(x: q.x, y: q.y - 250), tt)
            }))
        }
        return items
    }
}
