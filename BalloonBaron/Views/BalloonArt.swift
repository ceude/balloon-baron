import SwiftUI
import BalloonBaronCore

/// Balloon drawn like the prototype's `balloon()`: envelope, ropes and basket. With a design the
/// envelope carries its pattern, otherwise the company's two-colour stripes. Fits any frame.
struct DesignBalloon: View {
    /// Company colours (main, stripe) used when there is no pattern.
    let colors: [String]
    let pattern: Pattern?
    /// Main, pattern and accent colour of the design.
    let patternColors: [String]
    var shape: EnvelopeShape?

    init(colors: [String], design: Design? = nil) {
        self.colors = colors
        pattern = design?.pattern
        patternColors = design?.colors ?? []
        shape = design?.shape
    }

    /// A design that isn't saved yet, for the studio preview and the bazaar.
    init(pattern: Pattern, colors: [String], shape: EnvelopeShape? = nil) {
        self.colors = colors
        self.pattern = pattern
        patternColors = colors
        self.shape = shape
    }

    var body: some View {
        Canvas { ctx, size in
            BalloonPainter.draw(&ctx, size: size, colors: colors, pattern: pattern, patternColors: patternColors, shape: shape)
        }
        .accessibilityHidden(true)
    }
}

/// Port of the prototype's canvas code (`balloon`, `paintDesign`, `star`, `heart`).
enum BalloonPainter {
    static func draw(_ ctx: inout GraphicsContext, size: CGSize, colors: [String], pattern: Pattern?, patternColors: [String], shape: EnvelopeShape? = nil) {
        // The prototype's balloon is 2R wide and 2.55R tall, from envelope top to basket bottom.
        let r = min(size.width / 2, size.height / 2.55) * 0.96
        guard r > 0 else { return }
        let x = size.width / 2
        let bottom = (size.height + r * 2.55) / 2
        let top = bottom - r * 2.55
        let cy = top + r
        let design: [String]? = pattern != nil && patternColors.count >= 3 ? patternColors : nil
        let main = hex(design ?? colors, 0, "#ff5e3a")

        let env = shape.map { envelope($0, x: x, cy: cy, r: r) } ?? envelope(x: x, cy: cy, r: r)
        ctx.fill(env, with: .color(main))
        var inner = ctx
        inner.clip(to: env)
        if let design, let pattern {
            paint(&inner, pattern: pattern, colors: design, x: x, cy: cy, r: r, top: top)
        } else {
            stripes(&inner, color: hex(colors, 1, "#ffc23d"), x: x, cy: cy, r: r)
        }
        let shade = Gradient(stops: [
            .init(color: Color.white.opacity(0.18), location: 0),
            .init(color: Color.white.opacity(0), location: 0.6),
            .init(color: Color(red: 40 / 255, green: 10 / 255, blue: 40 / 255).opacity(0.35), location: 1)
        ])
        inner.fill(Path(CGRect(x: x - r, y: top, width: r * 2, height: r * 3)),
                   with: .linearGradient(shade, startPoint: CGPoint(x: x - r, y: 0), endPoint: CGPoint(x: x + r, y: 0)))
        if shape == .skull { skullFace(&ctx, x: x, cy: cy, r: r) }

        // Ropes and basket.
        let by = cy + r * 1.55, bb = bottom - r * 0.32
        var ropes = Path()
        ropes.move(to: CGPoint(x: x - r * 0.22, y: by))
        ropes.addLine(to: CGPoint(x: x - r * 0.24, y: bb))
        ropes.move(to: CGPoint(x: x + r * 0.22, y: by))
        ropes.addLine(to: CGPoint(x: x + r * 0.24, y: bb))
        ctx.stroke(ropes, with: .color(Color(red: 60 / 255, green: 35 / 255, blue: 30 / 255).opacity(0.8)), lineWidth: max(1, r * 0.04))
        ctx.fill(Path(roundedRect: CGRect(x: x - r * 0.3, y: bb, width: r * 0.6, height: r * 0.32), cornerRadius: r * 0.05),
                 with: .color(Color(hex: "#6b4426")))
    }

    static func hex(_ list: [String], _ i: Int, _ fallback: String) -> Color {
        Color(hex: i < list.count ? list[i] : fallback)
    }

    static func point(_ x: CGFloat, _ y: CGFloat, angle a: Double, radius: CGFloat) -> CGPoint {
        CGPoint(x: x + radius * CGFloat(cos(a)), y: y + radius * CGFloat(sin(a)))
    }

    /// Round top from 0.85π over the crown to 0.15π, then tapering to the mouth.
    static func envelope(x: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        var p = Path()
        let a0 = Double.pi * 0.85, a1 = Double.pi * 2.15, steps = 36
        for i in 0...steps {
            let pt = point(x, cy, angle: a0 + (a1 - a0) * Double(i) / Double(steps), radius: r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.addQuadCurve(to: CGPoint(x: x + r * 0.22, y: cy + r * 1.55), control: CGPoint(x: x + r * 0.75, y: cy + r * 1.15))
        p.addLine(to: CGPoint(x: x - r * 0.22, y: cy + r * 1.55))
        p.addQuadCurve(to: point(x, cy, angle: Double.pi * 0.85, radius: r), control: CGPoint(x: x - r * 0.75, y: cy + r * 1.15))
        p.closeSubpath()
        return p
    }

    /// Shaped envelopes from the bazaar (`envShape`): a heart, a star, a skull. All end in the same neck.
    static func envelope(_ shape: EnvelopeShape, x: CGFloat, cy: CGFloat, r R: CGFloat) -> Path {
        var p = Path()
        func P(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint { CGPoint(x: x + dx * R, y: cy + dy * R) }
        switch shape {
        case .heart:
            p.move(to: P(0, -0.55))
            p.addCurve(to: P(-1.1, -0.05), control1: P(-0.2, -1.25), control2: P(-1.35, -1.05))
            p.addQuadCurve(to: P(-0.22, 1.55), control: P(-0.8, 0.8))
            p.addLine(to: P(0.22, 1.55))
            p.addQuadCurve(to: P(1.1, -0.05), control: P(0.8, 0.8))
            p.addCurve(to: P(0, -0.55), control1: P(1.35, -1.05), control2: P(0.2, -1.25))
        case .star:
            // A five-point star with softened tips; a narrow neck between the two lower points leads to the burner.
            var pts: [(CGPoint, CGFloat)] = []
            for n in 0..<10 {
                let a = -Double.pi / 2 + Double(n) * Double.pi / 5, rr: CGFloat = n % 2 == 1 ? 0.55 : 1.2
                if n == 5 {
                    pts += [(P(0.17, 0.64), R * 0.1), (P(0.2, 1.55), 0), (P(-0.2, 1.55), 0), (P(-0.17, 0.64), R * 0.1)]
                    continue
                }
                pts.append((P(CGFloat(cos(a)) * rr, 0.06 + CGFloat(sin(a)) * rr), n % 2 == 1 ? R * 0.08 : R * 0.14))
            }
            let first = pts[pts.count - 1].0, second = pts[0].0
            p.move(to: CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2))
            for n in pts.indices {
                let (q, rad) = pts[n], next = pts[(n + 1) % pts.count].0
                if rad > 0 { p.addArc(tangent1End: q, tangent2End: next, radius: rad) } else { p.addLine(to: q) }
            }
        case .skull:
            // A round cranium over the top, cheekbones narrowing to the jaw, then the neck.
            let cc = cy - R * 0.06, rr = R * 1.05, a0 = Double.pi * 0.78, a1 = Double.pi * 2.22, steps = 36
            for i in 0...steps {
                let pt = point(x, cc, angle: a0 + (a1 - a0) * Double(i) / Double(steps), radius: rr)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.addQuadCurve(to: P(0.52, 1.14), control: P(0.8, 0.98))
            p.addQuadCurve(to: P(0.22, 1.55), control: P(0.3, 1.28))
            p.addLine(to: P(-0.22, 1.55))
            p.addQuadCurve(to: P(-0.52, 1.14), control: P(-0.3, 1.28))
            p.addQuadCurve(to: point(x, cc, angle: a0, radius: rr), control: P(-0.8, 0.98))
        }
        p.closeSubpath()
        return p
    }

    /// The skull's face: hollow eyes with a glint, a heart-shaped nose, a grin of teeth.
    static func skullFace(_ ctx: inout GraphicsContext, x: CGFloat, cy: CGFloat, r R: CGFloat) {
        func P(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint { CGPoint(x: x + dx * R, y: cy + dy * R) }
        let ink = Color(red: 28 / 255, green: 16 / 255, blue: 32 / 255).opacity(0.88)
        for side: CGFloat in [-1, 1] {
            var eye = ctx
            eye.translateBy(x: x + side * R * 0.37, y: cy + R * 0.2)
            eye.rotate(by: .radians(Double(side) * 0.18))
            eye.fill(ellipse(cx: 0, cy: 0, rx: R * 0.25, ry: R * 0.29), with: .color(ink))
            ctx.fill(ellipse(cx: x + side * R * 0.37 - R * 0.08, cy: cy + R * 0.1, rx: R * 0.06, ry: R * 0.06), with: .color(.white.opacity(0.75)))
        }
        var nose = Path()
        nose.move(to: P(0, 0.7))
        nose.addQuadCurve(to: P(-0.1, 0.48), control: P(-0.16, 0.58))
        nose.addQuadCurve(to: P(0, 0.5), control: P(-0.04, 0.43))
        nose.addQuadCurve(to: P(0.1, 0.48), control: P(0.04, 0.43))
        nose.addQuadCurve(to: P(0, 0.7), control: P(0.16, 0.58))
        ctx.fill(nose, with: .color(ink))
        let teeth = Path(roundedRect: CGRect(x: x - R * 0.34, y: cy + R * 0.82, width: R * 0.68, height: R * 0.22), cornerRadius: R * 0.06)
        ctx.fill(teeth, with: .color(Color(hex: "#fff8ec")))
        var lines = teeth
        lines.move(to: P(-0.34, 0.93)); lines.addLine(to: P(0.34, 0.93))
        for t in -2...2 { lines.move(to: P(CGFloat(t) * 0.12, 0.82)); lines.addLine(to: P(CGFloat(t) * 0.12, 1.04)) }
        ctx.stroke(lines, with: .color(ink), lineWidth: max(0.6, R * 0.035))
    }

    static func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    /// Company look: four vertical stripes.
    static func stripes(_ ctx: inout GraphicsContext, color: Color, x: CGFloat, cy: CGFloat, r: CGFloat) {
        for i in stride(from: -3, through: 3, by: 2) {
            ctx.fill(ellipse(cx: x + CGFloat(i) * r * 0.18, cy: cy + r * 0.1, rx: r * 0.1, ry: r * 1.6), with: .color(color))
        }
    }

    static func star(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) -> Path {
        var p = Path()
        for i in 0..<10 {
            let pt = point(x, y, angle: -Double.pi / 2 + Double(i) * Double.pi / 5, radius: i % 2 == 1 ? s * 0.45 : s)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    static func heart(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: x, y: y + s * 0.35))
        p.addCurve(to: CGPoint(x: x, y: y - s * 0.45),
                   control1: CGPoint(x: x - s * 1.1, y: y - s * 0.35), control2: CGPoint(x: x - s * 0.45, y: y - s * 1.05))
        p.addCurve(to: CGPoint(x: x, y: y + s * 0.35),
                   control1: CGPoint(x: x + s * 0.45, y: y - s * 1.05), control2: CGPoint(x: x + s * 1.1, y: y - s * 0.35))
        p.closeSubpath()
        return p
    }

    /// `paintDesign`: the envelope is already clipped; c1 fills, c2 and c3 draw the pattern.
    static func paint(_ ctx: inout GraphicsContext, pattern: Pattern, colors: [String], x: CGFloat, cy: CGFloat, r: CGFloat, top: CGFloat) {
        let c1 = hex(colors, 0, "#ff5e3a"), c2 = hex(colors, 1, "#ffc23d"), c3 = hex(colors, 2, "#ffffff")
        ctx.fill(Path(CGRect(x: x - r, y: top, width: r * 2, height: r * 3.2)), with: .color(c1))
        switch pattern {
        case .stripes:
            stripes(&ctx, color: c2, x: x, cy: cy, r: r)
            ctx.fill(ellipse(cx: x, cy: cy + r * 0.1, rx: r * 0.06, ry: r * 1.6), with: .color(c3))
        case .zigzag:
            for row in 0..<4 {
                let y0 = top + r * (0.5 + CGFloat(row) * 0.6)
                var p = Path()
                for k in 0...8 {
                    let pt = CGPoint(x: x - r + CGFloat(k) * r / 4, y: y0 + (k % 2 == 1 ? -r * 0.14 : r * 0.14))
                    if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                for k in stride(from: 8, through: 0, by: -1) {
                    p.addLine(to: CGPoint(x: x - r + CGFloat(k) * r / 4, y: y0 + r * 0.24 + (k % 2 == 1 ? -r * 0.14 : r * 0.14)))
                }
                p.closeSubpath()
                ctx.fill(p, with: .color(row % 2 == 1 ? c3 : c2))
            }
        case .checker:
            let s = r * 0.4
            for i in 0..<6 {
                for j in 0..<8 where (i + j) % 2 == 1 {
                    ctx.fill(Path(CGRect(x: x - r + CGFloat(i) * s, y: top + CGFloat(j) * s, width: s, height: s)),
                             with: .color((i + j) % 4 == 1 ? c2 : c3))
                }
            }
        case .stars:
            ctx.fill(Path(CGRect(x: x - r, y: cy - r * 0.12, width: r * 2, height: r * 0.42)), with: .color(c2))
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(-0.5, -0.45, 0.2), (0.45, -0.5, 0.17), (0, -0.78, 0.14), (-0.35, 0.75, 0.15), (0.4, 0.7, 0.17)]
            for (dx, dy, s) in spots {
                ctx.fill(star(x + dx * r, cy + dy * r, s * r), with: .color(c3))
            }
        case .hearts:
            let spots: [(CGFloat, CGFloat, CGFloat, Bool)] = [(-0.45, -0.4, 0.22, false), (0.4, -0.5, 0.2, true), (0, 0.05, 0.3, false),
                                                             (-0.4, 0.65, 0.18, true), (0.42, 0.6, 0.2, false)]
            for (dx, dy, s, accent) in spots {
                ctx.fill(heart(x + dx * r, cy + dy * r, s * r), with: .color(accent ? c3 : c2))
            }
        case .sunburst:
            let origin = CGPoint(x: x, y: cy + r * 1.5)
            for k in 0..<14 {
                let a0 = -Double.pi / 2 + Double(k - 7) * 0.16
                var p = Path()
                p.move(to: origin)
                p.addLine(to: point(origin.x, origin.y, angle: a0, radius: r * 4))
                p.addLine(to: point(origin.x, origin.y, angle: a0 + 0.16, radius: r * 4))
                p.closeSubpath()
                ctx.fill(p, with: .color(k % 2 == 1 ? c2 : c3))
            }
        case .waves:
            let style = StrokeStyle(lineWidth: r * 0.16, lineCap: .round)
            for row in 0..<5 {
                let y0 = top + r * (0.45 + CGFloat(row) * 0.48)
                var p = Path()
                for k in 0...20 {
                    let pt = CGPoint(x: x - r + CGFloat(k) * r / 10, y: y0 + CGFloat(sin(Double(k) * 0.9)) * r * 0.09)
                    if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                ctx.stroke(p, with: .color(row % 2 == 1 ? c2 : c3), style: style)
            }
        case .rainbow:
            let bands: [Color] = [c1, c2, c3, Color(hex: "#ffc23d"), Color(hex: "#3ad0c0"), Color(hex: "#9b7be0")]
            for k in 0..<6 {
                ctx.fill(Path(CGRect(x: x - r + CGFloat(k) * r / 3, y: top, width: r / 3 + 0.6, height: r * 3.2)), with: .color(bands[k]))
            }
        case .dots:
            for i in 0..<5 {
                for j in 0..<7 {
                    let cx = x - r + r * 0.2 + CGFloat(i) * r * 0.42 + CGFloat(j % 2) * r * 0.21
                    ctx.fill(ellipse(cx: cx, cy: top + r * 0.25 + CGFloat(j) * r * 0.42, rx: r * 0.11, ry: r * 0.11),
                             with: .color((i + j) % 3 != 0 ? c2 : c3))
                }
            }
        case .gold:
            // Gold leaf with a band in the main color and faint gores.
            let g = Gradient(stops: [.init(color: Color(hex: "#fff2b0"), location: 0), .init(color: Color(hex: "#e8b23a"), location: 0.35),
                                     .init(color: Color(hex: "#fff6c8"), location: 0.6), .init(color: Color(hex: "#b07a1a"), location: 1)])
            ctx.fill(Path(CGRect(x: x - r, y: top, width: r * 2, height: r * 3.2)),
                     with: .linearGradient(g, startPoint: CGPoint(x: x - r, y: top), endPoint: CGPoint(x: x + r, y: top + r * 3)))
            ctx.fill(Path(CGRect(x: x - r, y: cy + r * 0.05, width: r * 2, height: r * 0.5)), with: .color(c1))
            for k in -2...2 {
                ctx.stroke(ellipse(cx: x + CGFloat(k) * r * 0.3, cy: cy, rx: r * 0.12, ry: r * 1.5), with: .color(Color(hex: "#784f0a").opacity(0.35)), lineWidth: 1)
            }
        case .tile:
            // Iznik tiles: eight-point stars on white, a cobalt band.
            ctx.fill(Path(CGRect(x: x - r, y: top, width: r * 2, height: r * 3.2)), with: .color(Color(hex: "#f6f2ea")))
            for i in 0..<4 {
                for j in 0..<5 {
                    let px = x - r * 0.9 + CGFloat(i) * r * 0.6 + CGFloat(j % 2) * r * 0.3, py = top + r * 0.35 + CGFloat(j) * r * 0.55
                    var p = Path()
                    for k in 0..<8 {
                        let pt = point(px, py, angle: Double(k) * Double.pi / 4, radius: k % 2 == 1 ? r * 0.1 : r * 0.22)
                        if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    p.closeSubpath()
                    ctx.fill(p, with: .color(c1))
                    ctx.fill(ellipse(cx: px, cy: py, rx: r * 0.06, ry: r * 0.06), with: .color(Color(hex: "#e5432f")))
                }
            }
            ctx.fill(Path(CGRect(x: x - r, y: cy + r * 0.9, width: r * 2, height: r * 0.12)), with: .color(Color(hex: "#2b5ab8")))
        case .sky:
            // A constellation: night sky fading into the main color, stars and a faint line between them.
            let g = Gradient(colors: [Color(hex: "#141238"), c1])
            ctx.fill(Path(CGRect(x: x - r, y: top, width: r * 2, height: r * 3.2)),
                     with: .linearGradient(g, startPoint: CGPoint(x: x, y: top), endPoint: CGPoint(x: x, y: top + r * 3)))
            for i in 0..<14 {
                let sx = x - r * 0.85 + CGFloat((i * 37) % 17) / 17 * r * 1.7, sy = top + r * 0.2 + CGFloat((i * 53) % 23) / 23 * r * 2.2
                ctx.fill(star(sx, sy, r * (0.04 + CGFloat(i % 3) * 0.025)), with: .color(i % 4 != 0 ? Color(hex: "#fff6d0") : c2))
            }
            var line = Path()
            line.move(to: CGPoint(x: x - r * 0.5, y: cy - r * 0.4))
            line.addLine(to: CGPoint(x: x - r * 0.1, y: cy - r * 0.6))
            line.addLine(to: CGPoint(x: x + r * 0.3, y: cy - r * 0.3))
            line.addLine(to: CGPoint(x: x + r * 0.55, y: cy - r * 0.55))
            ctx.stroke(line, with: .color(Color(hex: "#fff6d0").opacity(0.5)), lineWidth: 1)
        case .kilim:
            // Cappadocian kilim: woven bands with a row of diamonds in each.
            let bands: [Color] = [c1, Color(hex: "#c0283a"), c2, Color(hex: "#2b2350"), c3, Color(hex: "#e8b23a"), c1]
            for row in 0..<7 {
                let y0 = top + CGFloat(row) * r * 0.46
                ctx.fill(Path(CGRect(x: x - r, y: y0, width: r * 2, height: r * 0.46)), with: .color(bands[row]))
                for k in 0..<5 {
                    let px = x - r * 0.8 + CGFloat(k) * r * 0.4, py = y0 + r * 0.23
                    var d = Path()
                    d.move(to: CGPoint(x: px, y: py - r * 0.14))
                    d.addLine(to: CGPoint(x: px + r * 0.12, y: py))
                    d.addLine(to: CGPoint(x: px, y: py + r * 0.14))
                    d.addLine(to: CGPoint(x: px - r * 0.12, y: py))
                    d.closeSubpath()
                    ctx.fill(d, with: .color(Color(hex: row % 2 == 1 ? "#f6e6c0" : "#2b2350")))
                }
            }
        }
    }
}
