import SwiftUI
import CoreText
import BalloonBaronCore

/// v113: the Balloon Show figures sold in the bazaar (`figPath`, `initialPts`, `showFigure`). Each is an outline the
/// balloons spread evenly along, traced behind them in light; the initial is the company's first letter, its balloons
/// spread evenly over the letter.
extension BalloonShow {
    struct Custom {
        var spots: [Spot]
        /// The line of light, in screen space.
        var trace: Path
    }

    /// The figure's outline, roughly in −1…1.
    static func outline(_ k: StoreItem) -> (points: [CGPoint], open: Bool) {
        var P: [CGPoint] = []
        switch k {
        case .figStar:
            for i in 0...10 { let a = -Double.pi / 2 + Double(i) * .pi / 5, r = i % 2 == 1 ? 0.42 : 1; P.append(CGPoint(x: cos(a) * r, y: sin(a) * r)) }
        case .figTulip:
            P = [(0, 0.35), (-0.38, 0.28), (-0.62, -0.05), (-0.66, -0.8), (-0.33, -0.38), (0, -0.92), (0.33, -0.38), (0.66, -0.8), (0.62, -0.05), (0.38, 0.28), (0, 0.35), (0, 1.1)]
                .map { CGPoint(x: $0.0, y: $0.1) }
        case .figButterfly:
            for j in 0...300 {
                let t = Double(j) / 300 * .pi * 2, r = exp(cos(t)) - 2 * cos(4 * t) - pow(sin(t / 12), 5)
                P.append(CGPoint(x: sin(t) * r, y: -cos(t) * r))
            }
        case .figSpiral:
            for j in 0...240 { let a = Double(j) / 240 * .pi * 4.4, r = 0.1 + 0.9 * Double(j) / 240; P.append(CGPoint(x: cos(a) * r, y: sin(a) * r)) }
        default: break
        }
        return (P, k == .figTulip || k == .figSpiral)
    }

    /// The company's first letter as a glyph outline (y down), in the game's font or, for letters it lacks, the system's.
    static func letter(_ name: String, size: CGFloat = 84) -> CGPath? {
        let ch = String((name.trimmingCharacters(in: .whitespaces).first ?? "B")).uppercased(with: Locale(identifier: "tr"))
        let base = CTFontCreateWithName("BarlowCondensed-ExtraBold" as CFString, size, nil)
        let font = CTFontCreateForString(base, ch as CFString, CFRange(location: 0, length: (ch as NSString).length))
        let u = Array(ch.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: u.count)
        guard CTFontGetGlyphsForCharacters(font, u, &glyphs, u.count), glyphs[0] != 0, let p = CTFontCreatePathForGlyph(font, glyphs[0], nil) else { return nil }
        var flip = CGAffineTransform(scaleX: 1, y: -1)
        return p.copy(using: &flip)
    }

    private static var memo: [String: Custom] = [:]

    /// Where `n` balloons stand for figure `k` in the sky between `top` and `bot` (`showFigure`).
    static func custom(_ k: StoreItem, _ n: Int, w: CGFloat, top: CGFloat, bot: CGFloat, r R0: CGFloat, company: String) -> Custom {
        let key = "\(k.rawValue):\(n):\(Int(w)):\(Int(top)):\(Int(bot)):\(Int(R0)):\(k == .figInitial ? company : "")"
        if let c = memo[key] { return c }
        let H1 = bot - top, bw = w * 0.9 - R0 * 1.2, bh = max(40, H1 - R0 * 3), cx = w / 2, cy = top + R0 * 2.8 + bh / 2
        var out = Custom(spots: [], trace: Path())
        if k == .figInitial, let glyph = letter(company) {
            let bb = glyph.boundingBoxOfPath, sc = min(bw / max(1, bb.width), bh / max(1, bb.height))
            let map = CGAffineTransform(translationX: cx, y: cy).scaledBy(x: sc, y: sc).translatedBy(x: -bb.midX, y: -bb.midY)
            out.trace = Path(glyph).applying(map)
            // farthest-point sampling over the letter: each next balloon goes where the letter is emptiest
            var cand: [CGPoint] = []
            let step = max(bb.width, bb.height) / 48
            var y = bb.minY
            while y <= bb.maxY { var x = bb.minX; while x <= bb.maxX { if glyph.contains(CGPoint(x: x, y: y)) { cand.append(CGPoint(x: x, y: y)) }; x += step }; y += step }
            if cand.isEmpty { cand = [CGPoint(x: bb.midX, y: bb.midY)] }
            var pick = [cand.min { ($0.y, $0.x) < ($1.y, $1.x) }!]
            var dm = cand.map { hypot($0.x - pick[0].x, $0.y - pick[0].y) }
            while pick.count < min(n, cand.count) {
                let bi = dm.indices.max { dm[$0] < dm[$1] }!, q = cand[bi]
                pick.append(q)
                for i in cand.indices { dm[i] = min(dm[i], hypot(cand[i].x - q.x, cand[i].y - q.y)) }
            }
            pick.sort { ($0.y, $0.x) < ($1.y, $1.x) }
            let P = pick.map { $0.applying(map) }
            var md = CGFloat.greatestFiniteMagnitude
            for i in P.indices { for j in P.indices where j > i { md = min(md, hypot(P[i].x - P[j].x, P[i].y - P[j].y)) } }
            let R = min(R0, (P.count > 1 ? md : R0 * 3) / 2.1)
            out.spots = (0..<n).map { i in let q = P[i % P.count]; return Spot(x: q.x, y: q.y + R * 1.6, r: R) }
        } else {
            let (raw, open) = outline(k)
            guard !raw.isEmpty else { return out }
            let xs = raw.map(\.x), ys = raw.map(\.y)
            let x0 = xs.min()!, x1 = xs.max()!, y0 = ys.min()!, y1 = ys.max()!
            let sc = min(bw / max(0.001, x1 - x0), bh / max(0.001, y1 - y0))
            let P = raw.map { CGPoint(x: cx + ($0.x - (x0 + x1) / 2) * sc, y: cy + ($0.y - (y0 + y1) / 2) * sc) }
            var tr = Path(); tr.move(to: P[0]); for q in P.dropFirst() { tr.addLine(to: q) }; if !open { tr.closeSubpath() }
            out.trace = tr
            var L: [CGFloat] = [0]
            for j in 1..<P.count { L.append(L[j - 1] + hypot(P[j].x - P[j - 1].x, P[j].y - P[j - 1].y)) }
            let tot = L[L.count - 1], R = min(R0, tot / CGFloat(n) / 2.3)
            out.spots = (0..<n).map { i in
                let d = open ? (n > 1 ? CGFloat(i) / CGFloat(n - 1) : 0.5) * tot : (CGFloat(i) + 0.5) / CGFloat(n) * tot
                var j = 1
                while j < L.count - 1 && L[j] < d { j += 1 }
                let f = (d - L[j - 1]) / max(0.000001, L[j] - L[j - 1])
                return Spot(x: P[j - 1].x + (P[j].x - P[j - 1].x) * f, y: P[j - 1].y + (P[j].y - P[j - 1].y) * f + R * 1.6, r: R)
            }
        }
        memo[key] = out
        return out
    }

    /// The trace of light: a soft wide glow, a brighter line and dots running along it.
    static func drawTrace(_ c: GraphicsContext, _ trace: Path, alpha: Double, phase: Double, scale: CGFloat = 1) {
        var lit = c
        lit.blendMode = .plusLighter
        let warm = Color(red: 1, green: 205 / 255, blue: 130 / 255)
        lit.stroke(trace, with: .color(warm.opacity(0.08 * alpha)), style: StrokeStyle(lineWidth: 14 * scale, lineCap: .round, lineJoin: .round))
        lit.stroke(trace, with: .color(warm.opacity(0.16 * alpha)), style: StrokeStyle(lineWidth: 6 * scale, lineCap: .round, lineJoin: .round))
        lit.stroke(trace, with: .color(warm.opacity(0.9 * alpha)),
                   style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round, lineJoin: .round, dash: [2 * scale, 12 * scale], dashPhase: CGFloat(-phase * 40) * scale))
    }
}

/// The bazaar picture of a show figure: a starry night, the figure in a line of light, small lit balloons along it and a
/// dark ridge with a few village lights.
struct FigureThumb: View {
    let item: StoreItem
    let colors: [String]
    let company: String

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width / 64, size.height / 72)
            var c = ctx
            c.translateBy(x: (size.width - 64 * k) / 2, y: (size.height - 72 * k) / 2)
            c.scaleBy(x: k, y: k)
            c.fill(Path(CGRect(x: 0, y: 0, width: 64, height: 72)), with: .radialGradient(Gradient(colors: [Color(hex: "#2c2f6e"), Color(hex: "#0b0d26")]),
                                                                                         center: CGPoint(x: 32, y: 34), startRadius: 4, endRadius: 52))
            var rng = Mulberry32(seed: 7)
            for _ in 0..<26 {
                let a = 0.25 + Double(rng.next()) * 0.5, x = CGFloat(rng.next()) * 64, y = CGFloat(rng.next()) * 50
                c.fill(Path(CGRect(x: x, y: y, width: 0.7, height: 0.7)), with: .color(.white.opacity(a)))
            }
            var ridge = Path()
            ridge.move(to: CGPoint(x: 0, y: 72)); ridge.addLine(to: CGPoint(x: 0, y: 64))
            ridge.addQuadCurve(to: CGPoint(x: 28, y: 63), control: CGPoint(x: 14, y: 58))
            ridge.addQuadCurve(to: CGPoint(x: 64, y: 60), control: CGPoint(x: 44, y: 67))
            ridge.addLine(to: CGPoint(x: 64, y: 72)); ridge.closeSubpath()
            c.fill(ridge, with: .color(Color(hex: "#141433")))
            for (x, y) in [(9.0, 66.0), (13, 65), (36, 67), (49, 65), (53, 66)] as [(CGFloat, CGFloat)] {
                c.fill(Path(CGRect(x: x, y: y, width: 1.2, height: 1.2)), with: .color(Color(hex: "#ffcf7a")))
            }
            let n = [StoreItem.figStar: 10, .figTulip: 11, .figButterfly: 12, .figSpiral: 11, .figInitial: 11][item] ?? 10
            let f = BalloonShow.custom(item, n, w: 64, top: 3, bot: 64, r: 3.2, company: company)
            BalloonShow.drawTrace(c, f.trace, alpha: 1, phase: 0, scale: 0.38)
            let c0 = Color(hex: colors.first ?? "#ff5e3a"), c1 = Color(hex: colors.count > 1 ? colors[1] : "#ffc23d")
            var lit = c
            lit.blendMode = .plusLighter
            for q in f.spots {
                let r = min(3.2, q.r * 0.8), x = q.x, y = q.y - q.r * 1.6
                lit.fill(Path(ellipseIn: CGRect(x: x - r * 3.2, y: y - r * 3.2, width: r * 6.4, height: r * 6.4)),
                         with: .radialGradient(Gradient(colors: [Color(red: 1, green: 170 / 255, blue: 80 / 255).opacity(0.5), .clear]), center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r * 3.2))
                var env = Path()
                env.move(to: CGPoint(x: x, y: y + r * 1.25))
                env.addCurve(to: CGPoint(x: x, y: y - r * 1.15), control1: CGPoint(x: x - r * 1.35, y: y + r * 0.35), control2: CGPoint(x: x - r * 1.15, y: y - r * 1.15))
                env.addCurve(to: CGPoint(x: x, y: y + r * 1.25), control1: CGPoint(x: x + r * 1.15, y: y - r * 1.15), control2: CGPoint(x: x + r * 1.35, y: y + r * 0.35))
                c.fill(env, with: .color(c0))
                c.fill(Path(CGRect(x: x - r * 0.18, y: y - r * 1.1, width: r * 0.36, height: r * 2.2)), with: .color(c1))
                lit.fill(Path(ellipseIn: CGRect(x: x - r * 1.2, y: y - r * 1.2, width: r * 2.4, height: r * 2.4)),
                         with: .radialGradient(Gradient(colors: [Color(red: 1, green: 220 / 255, blue: 140 / 255).opacity(0.6), .clear]), center: CGPoint(x: x, y: y + r * 0.4), startRadius: 0, endRadius: r * 1.2))
                c.fill(Path(CGRect(x: x - r * 0.28, y: y + r * 1.45, width: r * 0.56, height: r * 0.42)), with: .color(Color(hex: "#6a4024")))
            }
        }
    }
}
