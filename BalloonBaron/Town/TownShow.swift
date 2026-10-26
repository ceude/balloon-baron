import SwiftUI
import BalloonBaronCore

// The Balloon Show (prototype v111, `drawShow`): a 27-second night show over the town, made only from your own
// balloons: their number, sizes, designs and shapes. They rise from the launch field in waves into a grid over the
// town, burners lighting their envelopes from inside; the glows pulse to the music, sweep across in a wave and flash
// in a checker; then the balloons glide into a heart (a V for a small fleet, a ring for a middling one), a light chases
// round it, fireworks burst behind and every burner blazes for the finale.

enum BalloonShow {
    /// Seconds from dusk to dawn.
    static let length = 27.0
    /// Reference radius the sprites are drawn at.
    static let spriteR: CGFloat = 44

    /// One sprite per look (design, sponsor band, flame on or off) and layer: 0 the balloon, 1 its night silhouette,
    /// 2 its burner-lit glow. Drawn once as Canvas symbols, then each frame only stacks three images, so a
    /// 50-balloon show stays smooth.
    struct Look: Hashable { var design: Int?, ad: Sponsor?, flame: Bool, layer: Int }

    static func looks(_ s: GameState, ids: [Int]) -> [Look] {
        var seen = Set<Look>(), out: [Look] = []
        for b in ids.compactMap({ s.balloon($0) }) {
            for flame in [false, true] {
                for layer in 0..<3 {
                    let l = Look(design: s.design(of: b)?.id, ad: b.ad, flame: flame, layer: layer)
                    if seen.insert(l).inserted { out.append(l) }
                }
            }
        }
        return out
    }

    static var spriteSize: CGSize { CGSize(width: (spriteR * 3.2).rounded(.up), height: (spriteR * 3.6).rounded(.up)) }

    /// The symbol view for one look.
    struct Sprite: View {
        let state: GameState
        let look: Look

        var body: some View {
            let sz = BalloonShow.spriteSize, R = BalloonShow.spriteR
            Canvas { ctx, _ in
                ctx.drawLayer { layer in
                    var l = layer
                    let x = sz.width / 2, y = sz.height - R * 0.3
                    if let id = look.design, let d = state.designs.first(where: { $0.id == id }) {
                        ScenePainter.designBalloon3d(&l, x: x, y: y, r: R, colors: state.colors, burn: look.flame, ad: look.ad, design: d, region: state.region)
                    } else {
                        ScenePainter.balloon3d(&l, x: x, y: y, r: R, colors: state.colors, burn: look.flame, ad: look.ad, region: state.region)
                    }
                    let all = Path(CGRect(origin: .zero, size: sz))
                    if look.layer == 1 {
                        l.blendMode = .sourceAtop
                        l.fill(all, with: .color(Color(red: 16 / 255, green: 18 / 255, blue: 54 / 255)))
                    } else if look.layer == 2 {
                        l.blendMode = .sourceIn
                        l.fill(all, with: .radialGradient(Gradient(stops: [
                            .init(color: Color(red: 1, green: 190 / 255, blue: 90 / 255).opacity(0.8), location: 0),
                            .init(color: Color(red: 1, green: 130 / 255, blue: 50 / 255).opacity(0.35), location: 0.6),
                            .init(color: .clear, location: 1)
                        ]), center: CGPoint(x: x, y: y - R * 1.4), startRadius: R * 0.1, endRadius: R * 1.7))
                    }
                }
            }
            .frame(width: sz.width, height: sz.height)
        }
    }

    /// The show's camera: a little further out and lower than the usual night, for a bigger sky.
    static func camera(_ sz: CGSize) -> TownViewport {
        let B = NightCamera.base(sz), z = B.z * 0.85
        return TownViewport(z: z, ox: sz.width / 2 - TownGeo.iso(7.5, 7.5).x * z, oy: B.oy + sz.height * 0.2)
    }

    struct Spot { var x: CGFloat, y: CGFloat, r: CGFloat, row = 0, col = 0, depth: CGFloat = 1 }

    static func ease3(_ k: Double) -> Double { 1 - pow(1 - min(max(k, 0), 1), 3) }
    static func easeIO(_ k: Double) -> Double {
        let k = min(max(k, 0), 1)
        return k < 0.5 ? 4 * k * k * k : 1 - pow(-2 * k + 2, 3) / 2
    }

    /// `showGrid`: rows over the town, back rows a little smaller.
    static func grid(_ n: Int, w: CGFloat, top: CGFloat, bot: CGFloat) -> [Spot] {
        let H1 = bot - top
        let cols = min(max(Int((Double(n) * Double(w / H1) * 0.55).squareRoot().rounded()), min(n, 3)), n)
        let rows = (n + cols - 1) / cols
        let cw = w * 0.9 / CGFloat(cols), ch = H1 / CGFloat(rows), R = min(cw / 2.3, ch / 3.1, w * 0.09)
        return (0..<n).map { i in
            let row = i / cols, inRow = row == rows - 1 ? n - row * cols : cols, c = i % cols
            let depth: CGFloat = rows > 1 ? CGFloat(row) / CGFloat(rows - 1) : 1
            let stagger: CGFloat = rows > 1 ? (row % 2 == 1 ? cw * 0.22 : -cw * 0.22) : 0
            return Spot(x: w / 2 + (CGFloat(c) - CGFloat(inRow - 1) / 2) * cw + stagger, y: top + ch * (CGFloat(row) + 0.92),
                        r: R * (0.82 + 0.18 * depth), row: row, col: c, depth: depth)
        }
    }

    /// `showHeart`: a V of geese below 8 balloons, a ring below 16, a heart from 16 up.
    static func figure(_ n: Int, w: CGFloat, top: CGFloat, bot: CGFloat, r R0: CGFloat) -> [Spot] {
        let cx = w / 2, H1 = bot - top
        if n < 8 {
            let m = n > 1 ? (n - 1 + 1) / 2 : 1
            return (0..<n).map { i in
                let k = ((i + 1) / 2) * (i % 2 == 1 ? -1 : 1)
                return Spot(x: cx + CGFloat(k) / CGFloat(m) * w * 0.36, y: top + R0 * 2.8 + (H1 - R0 * 3) * 0.55 * CGFloat(abs(k)) / CGFloat(m), r: R0)
            }
        }
        if n < 16 {
            let R = min(R0 * 1.1, w * 0.9 * .pi / CGFloat(n) / 2.3), rx = w * 0.5 - R * 1.3, ry = (H1 - R * 3) / 2, cy = top + R * 2.8 + ry
            return (0..<n).map { i in
                let a = -Double.pi / 2 + Double(i) / Double(n) * .pi * 2
                return Spot(x: cx + CGFloat(cos(a)) * rx, y: cy + CGFloat(sin(a)) * ry, r: R)
            }
        }
        // Even spacing along the heart's outline.
        let sx = (w * 0.5 - R0 * 1.2) / 16, sy = max(1, (H1 - R0 * 3) / 29), cy = top + R0 * 2.8 + 12 * sy
        var P: [CGPoint] = []
        for j in 0...400 {
            let t = Double(j) / 400 * .pi * 2
            P.append(CGPoint(x: cx + 16 * CGFloat(pow(sin(t), 3)) * sx,
                             y: cy - CGFloat(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)) * sy))
        }
        var L: [CGFloat] = [0]
        for j in 1..<P.count { L.append(L[j - 1] + hypot(P[j].x - P[j - 1].x, P[j].y - P[j - 1].y)) }
        let tot = L[L.count - 1], R = min(R0, tot / CGFloat(n) / 2.3)
        return (0..<n).map { i in
            let d = (CGFloat(i) + 0.5) / CGFloat(n) * tot
            var j = 1
            while L[j] < d { j += 1 }
            return Spot(x: P[j].x, y: P[j].y, r: R)
        }
    }
}

extension TownPainter {
    /// The show itself, in screen space over the night town. `st` counts from when the dusk has fallen.
    func showLayer(screen: GraphicsContext, hz: CGFloat, ids: [Int], t0: Double) {
        let bs = ids.compactMap { s.balloon($0) }, n = bs.count
        guard n > 0 else { return }
        let w = size.width, h = size.height, st = t - t0 - 1.2
        let top = max(150, hz * 0.1), bot = max(top + 200, hz + (h - hz) * 0.14)
        let G = BalloonShow.grid(n, w: w, top: top, bot: bot), Hh = BalloonShow.figure(n, w: w, top: top, bot: bot, r: G[0].r)
        let field = v.screen(TownGeo.iso(3, 6.2)), beat = st * 2, bp = beat - floor(beat)
        var lit = screen
        lit.blendMode = .plusLighter
        func glow(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ c: (Double, Double, Double), _ a: Double) {
            lit.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .radialGradient(Gradient(colors: [Color(red: c.0 / 255, green: c.1 / 255, blue: c.2 / 255).opacity(min(1, max(0, a))), .clear]),
                                           center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r))
        }
        // Fireworks behind the balloons for the finale.
        if st > 16.5 && st < 25 {
            let cols: [(Double, Double, Double)] = [(255, 94, 58), (255, 194, 61), (58, 208, 192), (255, 111, 168), (155, 123, 224), (255, 255, 255), (120, 200, 255)]
            for j in 0..<(st > 21 ? 7 : 4) {
                let ph = ((st - 16.5) * 0.5 + Double(j) * 0.37).truncatingRemainder(dividingBy: 1)
                let cx = w * (0.1 + CGFloat((Double(j) * 0.29).truncatingRemainder(dividingBy: 0.8)))
                let cy = top + (hz - top) * (0.15 + CGFloat((Double(j) * 0.23).truncatingRemainder(dividingBy: 0.5)))
                if ph < 0.25 {
                    glow(cx, hz - (hz - cy) * CGFloat(ph / 0.25), 5, (255, 230, 180), 0.9)
                } else {
                    let r = CGFloat((ph - 0.25) / 0.75), a = 1 - Double(r)
                    for i in 0..<22 {
                        let an = Double(i) / 22 * .pi * 2
                        glow(cx + CGFloat(cos(an)) * r * w * 0.16, cy + CGFloat(sin(an)) * r * w * 0.16 + r * r * 26, 6, cols[j], a)
                    }
                    glow(cx, cy, w * 0.22 * r, cols[j], 0.1 * a)
                }
            }
        }
        // Two searchlights from the square sweep the sky while the balloons dance.
        if st > 6 && st < 24 {
            let b0 = v.screen(TownGeo.iso(7.5, 7.5)), a0 = min(max((st - 6) / 1.2, 0), 1) * min(max((24 - st) / 1.2, 0), 1)
            for sgn in [-1.0, 1.0] {
                let an = -Double.pi / 2 + sgn * (0.35 + 0.3 * sin(st * 0.9 + (sgn > 0 ? 1.4 : 0)))
                let e = CGPoint(x: b0.x + CGFloat(cos(an)) * h, y: b0.y + CGFloat(sin(an)) * h)
                let px = -CGFloat(sin(an)) * h * 0.09, py = CGFloat(cos(an)) * h * 0.09
                var beam = Path()
                beam.move(to: CGPoint(x: b0.x - 3, y: b0.y))
                beam.addLine(to: CGPoint(x: e.x - px, y: e.y - py))
                beam.addLine(to: CGPoint(x: e.x + px, y: e.y + py))
                beam.addLine(to: CGPoint(x: b0.x + 3, y: b0.y))
                beam.closeSubpath()
                lit.fill(beam, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 236 / 255, blue: 190 / 255).opacity(0.28 * a0), .clear]),
                                                     startPoint: b0, endPoint: e))
            }
        }
        // The balloons, back rows first.
        for i in (0..<n).sorted(by: { G[$0].depth < G[$1].depth }) {
            let g = G[i], f = Hh[i]
            let t0i = 0.3 + (n > 1 ? Double(i) / Double(n - 1) : 0) * min(4, 1 + Double(n) * 0.12)
            if st < t0i { continue }
            let k = CGFloat(BalloonShow.ease3((st - t0i) / 2.6))
            let m = CGFloat(BalloonShow.easeIO((st - 13) / 2.6) * (1 - BalloonShow.easeIO((st - 23) / 2)))
            var x = field.x + (g.x - field.x) * k, y = field.y + (g.y - field.y) * k, R = g.r * 0.35 + (g.r - g.r * 0.35) * k
            x += (f.x - x) * m; y += (f.y - y) * m; R += (f.r - R) * m
            let drift = max(0, st - 23.5)
            x += CGFloat(sin(t * 0.6 + Double(i) * 1.7)) * R * 0.12
            y += CGFloat(sin(t * 0.8 + Double(i) * 1.3)) * R * 0.1 - CGFloat(drift * drift * 9)
            // The burners: the rise, then the light patterns of the dance.
            let burn: Double
            if st < t0i + 2.4 { burn = 0.9 + 0.1 * sin(t * 30 + Double(i)) }
            else if st < 9.5 { burn = bp < 0.22 ? 1 : 0.12 }
            else if st < 11.5 { burn = max(0.1, pow(max(0, cos((Double(x / w) - (st - 9.5) * 0.9 + 0.2) * .pi * 2.2)), 6)) }
            else if st < 13 { burn = (g.row + g.col + Int(floor(beat))) % 2 == 1 ? 1 : 0.1 }
            else if st < 16 { burn = 0.25 + 0.2 * sin(t * 9 + Double(i)) }
            else if st < 20.5 {
                let c = ((st - 16) * Double(n) * 0.45).truncatingRemainder(dividingBy: Double(n))
                let dd = min(abs(Double(i) - c), Double(n) - abs(Double(i) - c))
                burn = max(0.15, 1 - dd / max(2, Double(n) * 0.12))
            } else { burn = 0.85 + 0.15 * sin(t * 25 + Double(i) * 2) }
            let alpha = min(max(1 - (st - 24.5) / 1.8, 0), 1) * min(max((st - t0i) * 3, 0), 1)
            showBalloon(screen, bs[i], x: x, y: y, r: R, burn: burn, alpha: alpha, glow: glow)
        }
        // The title at the start and the tally at the end.
        func caption(_ a: Double, _ big: String, _ small: String) {
            guard a > 0 else { return }
            var c = screen
            c.opacity = a
            c.addFilter(.shadow(color: .black.opacity(0.6), radius: 10))
            let y = h * 0.3
            c.draw(Text(big).font(Theme.font(min(46, w * 0.11), .heavy, condensed: true)).foregroundColor(hex("#ffd27a")), at: CGPoint(x: w / 2, y: y))
            c.draw(Text(small).font(Theme.font(min(20, w * 0.048), .semibold)).foregroundColor(hex("#fff8e6")), at: CGPoint(x: w / 2, y: y + min(34, w * 0.08)))
        }
        caption(min(1, st * 1.5) * min(max(1 - (st - 2.6) / 0.8, 0), 1), loc("show.title"), s.company)
        caption(min(max((st - 21) * 1.5, 0), 1) * min(max(1 - (st - 25), 0), 1), loc("show.tally", num(n)), loc("show.cheer"))
    }

    /// One balloon of the show: the balloon, darkened by the night and lit from inside by its burner, with a soft glow
    /// around it while the burner roars. Uses the night's sprites when it has them, else draws the layers itself.
    private func showBalloon(_ screen: GraphicsContext, _ b: Balloon, x: CGFloat, y: CGFloat, r R: CGFloat, burn: Double, alpha: Double,
                             glow: (CGFloat, CGFloat, CGFloat, (Double, Double, Double), Double) -> Void) {
        guard alpha > 0.01, R > 1 else { return }
        if burn > 0.05 { glow(x, y - R * 1.9, R * 2.6, (255, 150, 60), 0.32 * burn * alpha) }
        let flame = burn > 0.45, design = s.design(of: b)?.id
        if let sprite = night?.sprite,
           let base = sprite(BalloonShow.Look(design: design, ad: b.ad, flame: flame, layer: 0)),
           let dark = sprite(BalloonShow.Look(design: design, ad: b.ad, flame: flame, layer: 1)),
           let warm = sprite(BalloonShow.Look(design: design, ad: b.ad, flame: flame, layer: 2)) {
            let k = R / BalloonShow.spriteR, sz = BalloonShow.spriteSize
            let rect = CGRect(x: x - sz.width * k / 2, y: y - (sz.height - BalloonShow.spriteR * 0.3) * k, width: sz.width * k, height: sz.height * k)
            var c = screen
            c.opacity = alpha
            c.draw(base, in: rect)
            c.opacity = alpha * 0.74 * (1 - burn * 0.8)
            c.draw(dark, in: rect)
            if burn > 0.02 {
                c.opacity = alpha * burn
                c.draw(warm, in: rect)
            }
            return
        }
        var c = screen
        c.opacity = alpha
        let box = CGRect(x: x - R * 1.6, y: y - R * 3.4, width: R * 3.2, height: R * 3.7)
        c.drawLayer { layer in
            var l = layer
            if let d = s.design(of: b) {
                ScenePainter.designBalloon3d(&l, x: x, y: y, r: R, colors: s.colors, burn: flame, ad: b.ad, design: d, region: s.region)
            } else {
                ScenePainter.balloon3d(&l, x: x, y: y, r: R, colors: s.colors, burn: flame, ad: b.ad, region: s.region)
            }
            l.blendMode = .sourceAtop
            l.fill(Path(box), with: .color(Color(red: 16 / 255, green: 18 / 255, blue: 54 / 255).opacity(0.74 * (1 - burn * 0.8))))
            l.fill(Path(box), with: .radialGradient(Gradient(stops: [
                .init(color: Color(red: 1, green: 190 / 255, blue: 90 / 255).opacity(0.8 * burn), location: 0),
                .init(color: Color(red: 1, green: 130 / 255, blue: 50 / 255).opacity(0.35 * burn), location: 0.6),
                .init(color: .clear, location: 1)
            ]), center: CGPoint(x: x, y: y - R * 1.4), startRadius: R * 0.1, endRadius: R * 1.7))
        }
    }
}
