import SwiftUI
import BalloonBaronCore

// The painted scene on each achievement's postcard: port of the prototype's `pcScene` (v78), drawn in the
// postcard's 150×96 artboard with the same shapes, colors and mulberry32 seeds.

extension Achievement {
    /// The scene inside the postcard's frame (6…144 × 6…72), over the sky gradient.
    func scene(_ ctx: inout GraphicsContext, colors: [String]) {
        let main = colors.first ?? "#ff5e3a", second = colors.count > 1 ? colors[1] : "#ffc23d"
        let key = rawValue, seed = key.count * 97 + Int(key.unicodeScalars.first?.value ?? 0)
        var pc = PostcardPainter(c: ctx, c0: main, c1: second, r: Mulberry32(seed: UInt32(seed)))
        pc.draw(self)
    }
}

/// Draws one scene; the helpers mirror the prototype's `pcB`, `pcCh`, `pcHills`, `pcStar`, `pcCrown`, `pcMesa` and `pcCactus`.
private struct PostcardPainter {
    let c: GraphicsContext
    /// The player's company colors.
    let c0: String, c1: String
    var r: Mulberry32

    static let cols = ["#ff5e3a", "#ffc23d", "#14a39a", "#9b7be0", "#5aa9e6", "#ff6fa8", "#22a45d", "#e5432f"]

    // MARK: Primitives

    func fill(_ d: String, _ col: String, in g: GraphicsContext? = nil) {
        (g ?? c).fill(HezarfenAvatar.svgPath(d), with: .color(Color(hex: col)))
    }

    func stroke(_ d: String, _ col: String, _ w: CGFloat = 1, round: Bool = false, in g: GraphicsContext? = nil) {
        (g ?? c).stroke(HezarfenAvatar.svgPath(d), with: .color(Color(hex: col)),
                        style: StrokeStyle(lineWidth: w, lineCap: round ? .round : .butt))
    }

    func circle(_ x: CGFloat, _ y: CGFloat, _ rr: CGFloat, _ col: String, in g: GraphicsContext? = nil) {
        (g ?? c).fill(Path(ellipseIn: CGRect(x: x - rr, y: y - rr, width: rr * 2, height: rr * 2)), with: .color(Color(hex: col)))
    }

    func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ col: String, in g: GraphicsContext? = nil) {
        (g ?? c).fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), with: .color(Color(hex: col)))
    }

    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ col: String, rx: CGFloat = 0, in g: GraphicsContext? = nil) {
        let p = rx > 0 ? Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: rx) : Path(CGRect(x: x, y: y, width: w, height: h))
        (g ?? c).fill(p, with: .color(Color(hex: col)))
    }

    /// SVG text: `y` is the baseline, centered on `x`.
    func text(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, _ col: String) {
        c.draw(Text(s).font(.custom("BarlowCondensed-ExtraBold", size: size)).foregroundColor(Color(hex: col)),
               at: CGPoint(x: x, y: y + size * 0.22), anchor: .bottom)
    }

    /// A random number with one decimal, like the prototype's `toFixed(1)`.
    mutating func r1(_ base: Double, _ span: Double) -> CGFloat {
        CGFloat(((base + r.next() * span) * 10).rounded() / 10)
    }

    /// A number for path data, never in exponent form.
    func f(_ v: Double) -> String { String(format: "%.3f", v) }

    // MARK: Pieces

    /// `pcB`: a balloon whose envelope top is at (x, y), `k` times the 24-wide artboard.
    func balloon(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat, _ f: String, _ s: String, opacity: Double = 1) {
        var g = c
        g.opacity = opacity
        g.translateBy(x: x - 12 * k, y: y)
        g.scaleBy(x: k, y: k)
        fill("M0 14 C0 4 7 0 12 0 C17 0 24 4 24 14 C24 22 16 26 14 30 L10 30 C8 26 0 22 0 14Z", f, in: g)
        stroke("M8 3 C6 10 6 20 10 30 M16 3 C18 10 18 20 14 30", s, 3, in: g)
        stroke("M10 30 L10 32 M14 30 L14 32", "#6b4426", 0.8, in: g)
        rect(9, 32, 6, 5, "#6b4426", in: g)
    }

    /// `pcCh`: a fairy chimney standing on the ground line.
    func chimney(_ x: CGFloat, _ h: CGFloat, _ col: String = "#c98d68", _ cap: String = "#7a4a30") {
        fill("M\(x - 4) 72 L\(x) \(72 - h) L\(x + 4) 72Z", col)
        ellipse(x, 72 - h, 3.4, 1.6, cap)
    }

    func hills(_ col: String = "#d7a27e") {
        fill("M6 72 L6 60 Q30 52 52 60 T100 58 T144 60 L144 72Z", col)
    }

    /// The valley: hills and three fairy chimneys.
    func valley() {
        hills()
        chimney(24, 20); chimney(41, 16); chimney(122, 22)
    }

    func star(_ x: CGFloat, _ y: CGFloat, _ rr: CGFloat, _ col: String, in g: GraphicsContext? = nil) {
        var p = Path()
        for i in 0..<10 {
            let a = -Double.pi / 2 + Double(i) * Double.pi / 5, q = i % 2 == 1 ? Double(rr) * 0.45 : Double(rr)
            let pt = CGPoint(x: ((Double(x) + cos(a) * q) * 10).rounded() / 10, y: ((Double(y) + sin(a) * q) * 10).rounded() / 10)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        (g ?? c).fill(p, with: .color(Color(hex: col)))
    }

    func crown(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat) {
        var g = c
        g.translateBy(x: x, y: y)
        g.scaleBy(x: k, y: k)
        let body = "M-14 8 L-16 -8 L-7 0 L0 -12 L7 0 L16 -8 L14 8Z"
        fill(body, "#ffc23d", in: g)
        stroke(body, "#c48a14", 1, in: g)
        rect(-14, 8, 28, 4, "#e8a820", in: g)
        circle(0, -12, 2, "#e5432f", in: g)
        circle(-16, -8, 1.6, "#14a39a", in: g)
        circle(16, -8, 1.6, "#14a39a", in: g)
    }

    func mesa() {
        fill("M6 72 L6 54 L18 54 L22 46 L52 46 L58 56 L80 56 L84 50 L104 50 L110 60 L144 60 L144 72Z", "#c8704a")
        fill("M6 72 L6 64 L144 66 L144 72Z", "#e0a070")
    }

    func cactus(_ x: CGFloat, _ k: CGFloat = 1) {
        var g = c
        g.translateBy(x: x, y: 72)
        g.scaleBy(x: k, y: k)
        let col = "#3f7a3a"
        rect(-2.5, -22, 5, 22, col, rx: 2.5, in: g)
        rect(-9, -15, 4, 9, col, rx: 2, in: g)
        rect(-9, -8, 8, 3, col, in: g)
        rect(5, -18, 4, 9, col, rx: 2, in: g)
        rect(1, -11, 8, 3, col, in: g)
    }

    /// `many`: n balloons scattered between y0 and y1; the first one in your colors.
    mutating func many(_ n: Int, _ sz: Double, _ y0: Double, _ y1: Double) {
        for i in 0..<n {
            let x = 14 + r.next() * 122, y = y0 + r.next() * (y1 - y0), k = sz * (0.7 + r.next() * 0.5)
            balloon(CGFloat(x), CGFloat(y), CGFloat(k), i == 0 ? c0 : Self.cols[i % 8], i == 0 ? c1 : "#ffffff")
        }
    }

    // MARK: Scenes

    mutating func draw(_ a: Achievement) {
        switch a {
        case .first:
            circle(112, 54, 9, "#fff0c8")
            valley()
            balloon(72, 26, 1, c0, c1)
            for x: CGFloat in [58, 88] {
                circle(x, 66, 1.6, "#2b2350")
                rect(x - 1, 67.5, 3, 4, "#2b2350")
            }
        case .mission:
            var rays = c
            rays.opacity = 0.25
            for i in 0..<8 {
                let a = Double(i) * 0.785
                fill("M75 36 L\(f(75 + cos(a) * 70)) \(f(36 + sin(a) * 70)) L\(f(75 + cos(a + 0.2) * 70)) \(f(36 + sin(a + 0.2) * 70))Z", "#ffffff", in: rays)
            }
            star(75, 34, 22, "#ffc23d")
            hills("#c9a07a")
            balloon(75, 20, 0.8, c0, c1)
        case .perfect10:
            valley()
            ellipse(75, 66, 22, 5, "#ffffff")
            ellipse(75, 66, 15, 3.4, "#e5432f")
            ellipse(75, 66, 8, 1.8, "#ffffff")
            balloon(75, 24, 0.95, c0, c1)
            let feather = "M104 22 Q114 16 120 24 Q112 22 106 30 Q104 26 104 22Z M104 22 L122 28"
            fill(feather, "#ffffff")
            stroke(feather, "#c9b8a0", 0.6)
        case .fleet5:
            hills("#c9a07a")
            chimney(30, 18); chimney(120, 20)
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(30, 30, 0.7), (52, 12, 0.85), (76, 26, 1.05), (100, 10, 0.8), (120, 30, 0.65)]
            for (i, s) in spots.enumerated() {
                balloon(s.0, s.1, s.2, i == 2 ? c0 : Self.cols[(i * 2) % 8], i == 2 ? c1 : "#ffffff")
            }
        case .fleet10:
            circle(40, 56, 10, "#fff0c8")
            valley()
            many(10, 0.6, 8, 40)
        case .fleet20:
            valley()
            many(20, 0.42, 6, 46)
        case .hotel, .hotelOwn:
            hills("#b07a5a")
            fill("M34 72 L40 30 Q75 14 110 30 L116 72Z", "#e6b88a")
            fill("M110 30 L116 72 L120 72 L114 32Z", "#b8865e")
            let windows: [(CGFloat, CGFloat)] = [(50, 40), (66, 36), (84, 36), (100, 40), (50, 56), (66, 54), (84, 54), (100, 56)]
            for (x, y) in windows {
                fill("M\(x - 4) \(y + 8) L\(x - 4) \(y + 2) Q\(x) \(y - 3) \(x + 4) \(y + 2) L\(x + 4) \(y + 8)Z", "#ffd27a")
            }
            rect(70, 64, 10, 8, "#6b4426")
            balloon(20, 10, 0.55, c0, c1)
            if a == .hotelOwn {
                // A golden key across the hotel.
                var g = c
                g.translateBy(x: 75, y: 24)
                g.rotate(by: .degrees(-25))
                g.stroke(Path(ellipseIn: CGRect(x: -22, y: -8, width: 16, height: 16)), with: .color(Color(hex: "#ffc23d")), lineWidth: 4)
                rect(-6, -2, 28, 4, "#ffc23d", in: g)
                rect(14, 2, 3, 6, "#ffc23d", in: g)
                rect(19, 2, 3, 4, "#ffc23d", in: g)
            }
        case .star45:
            for _ in 0..<26 {
                let x = r1(6, 138), y = r1(6, 50), rr = r1(0.4, 0.8)
                circle(x, y, rr, "#fff6d0")
            }
            for i in 0..<5 { star(39 + CGFloat(i) * 18, 34, 8, i < 4 ? "#ffc23d" : "#8a7a50") }
            var half = c
            half.clip(to: Path(CGRect(x: 111, y: 20, width: 4, height: 30)))
            star(111, 34, 8, "#ffc23d", in: half)
            hills("#3a2f5a")
        case .pax1k:
            hills("#c9a07a")
            fill("M40 -2 C40 20 60 30 64 40 L86 40 C90 30 110 20 110 -2Z", c0)
            stroke("M60 -2 C58 18 64 32 68 40 M90 -2 C92 18 86 32 82 40", c1, 5)
            stroke("M66 40 L60 50 M84 40 L90 50", "#6b4426")
            for i in 0..<9 {
                let x = 60 + CGFloat(i) * 3.8, lift = CGFloat(i % 2) * 1.5
                circle(x, 49 - lift, 2.4, Self.cols[i % 8])
                circle(x, 45.5 - lift, 1.6, "#3a2418")
            }
            rect(56, 50, 38, 12, "#8a5a32", rx: 2)
            stroke("M56 54 L94 54 M56 58 L94 58", "#6b4426", 0.8)
        case .pax10k:
            valley()
            let cup = "M58 22 L92 22 L90 38 Q75 50 60 38Z"
            fill(cup, "#ffc23d")
            stroke(cup, "#c48a14")
            stroke("M58 26 Q48 26 50 34 Q52 40 61 40 M92 26 Q102 26 100 34 Q98 40 89 40", "#ffc23d", 3)
            rect(72, 46, 6, 10, "#e8a820")
            rect(64, 56, 22, 6, "#8a5a32", rx: 1.5)
            balloon(75, 2, 0.55, c0, c1)
            text("10K", 75, 35, size: 9, "#8a5a10")
        case .winter:
            hills("#eef4fa")
            chimney(24, 20, "#d9c0a8", "#ffffff"); chimney(41, 16, "#d9c0a8", "#ffffff"); chimney(122, 22, "#d9c0a8", "#ffffff")
            fill("M20 52 L24 52 L22 54Z M37 56 L45 56 L41 58Z M118 50 L126 50 L122 52Z", "#ffffff")
            balloon(80, 18, 0.95, c0, c1)
            for _ in 0..<30 {
                let x = r1(6, 138), y = r1(6, 62), rr = r1(0.6, 0.9)
                circle(x, y, rr, "#ffffff")
            }
        case .fest:
            let bursts: [(Double, Double, String)] = [(40, 24, "#ffc23d"), (108, 18, "#ff6fa8"), (76, 12, "#3ad0c0")]
            for (x, y, col) in bursts {
                for i in 0..<12 {
                    let a = Double(i) * 0.52
                    stroke("M\(f(x + cos(a) * 4)) \(f(y + sin(a) * 4)) L\(f(x + cos(a) * 13)) \(f(y + sin(a) * 13))", col, 1.4, round: true)
                }
            }
            hills("#3a2f5a")
            stroke("M6 34 Q75 52 144 34", "#c9b8a0", 0.8)
            for i in 0..<13 {
                let x = 12 + Double(i) * 10, u = (x - 6) / 138, y = 34 + 18 * 4 * u * (1 - u) * 0.9
                fill("M\(f(x - 3)) \(f(y)) L\(f(x + 3)) \(f(y)) L\(f(x)) \(f(y + 6))Z", Self.cols[i % 8])
            }
            balloon(75, 40, 0.6, c0, c1)
        case .rivalDown:
            hills("#b07a5a")
            fill("M30 70 Q40 58 56 62 Q70 54 82 64 Q90 60 96 70Z", "#8a8494")
            stroke("M40 66 Q52 60 62 66 M66 62 Q76 60 86 68", "#6a6474")
            rect(96, 64, 8, 7, "#5a4a3a")
            balloon(110, 10, 0.8, c0, c1)
            stroke("M18 22 L36 34 L44 28 L60 44", "#e5432f", 2.5, round: true)
            stroke("M60 44 L54 44 M60 44 L60 38", "#e5432f", 2.5, round: true)
        case .boss:
            circle(75, 60, 14, "#ffd090")
            hills("#9a6a52")
            fill("M18 72 L18 50 L44 50 L44 72Z", "#7a5a48")
            rect(16, 46, 30, 5, "#5a3a28")
            stroke("M22 56 L40 66 M40 56 L22 66", "#e5432f", 1.6)
            // The old master's top hat.
            var g = c
            g.translateBy(x: 100, y: 40)
            ellipse(0, 12, 16, 3.5, "#1f1b2e", in: g)
            rect(-9, -8, 18, 20, "#1f1b2e", rx: 1.5, in: g)
            rect(-9, 6, 18, 3, "#c0283a", in: g)
            balloon(46, 8, 0.5, c0, c1)
        case .design:
            hills("#c9a07a")
            // A painter's palette.
            var pal = c
            pal.translateBy(x: 36, y: 44)
            pal.rotate(by: .degrees(-12))
            let board = "M-22 0 C-22 -16 14 -20 20 -6 C24 4 12 4 10 10 C8 18 -22 16 -22 0Z"
            fill(board, "#f2e2c0", in: pal)
            stroke(board, "#b89a74", in: pal)
            for (i, col) in ["#ff5e3a", "#ffc23d", "#14a39a", "#9b7be0", "#ff6fa8"].enumerated() {
                circle(-14 + CGFloat(i) * 6, -6 + CGFloat(i % 2) * 6, 3, col, in: pal)
            }
            // Your balloon with stars painted on.
            var b = c
            b.translateBy(x: 76, y: 4)
            b.scaleBy(x: 1.15, y: 1.15)
            fill("M0 14 C0 4 7 0 12 0 C17 0 24 4 24 14 C24 22 16 26 14 30 L10 30 C8 26 0 22 0 14Z", c0, in: b)
            for (x, y) in [(6.0, 8.0), (16, 6), (11, 16), (5, 20), (18, 18)] { star(CGFloat(x), CGFloat(y), 2.6, c1, in: b) }
            rect(9, 32, 6, 5, "#6b4426", in: b)
            stroke("M116 66 L134 30", "#8a5a32", 3, round: true)
            stroke("M134 30 L137 24", c0, 3, round: true)
        case .upgrade3:
            hills("#c9a07a")
            rect(30, 40, 40, 32, "#e6c49a")
            rect(70, 40, 14, 32, "#b8865e")
            fill("M30 40 L84 40 L76 34 L36 34Z", "#f0d8b0")
            for (x, y) in [(38.0, 48.0), (52, 48), (38, 60), (52, 60)] { rect(CGFloat(x), CGFloat(y), 8, 8, "#ffd27a") }
            // A crane lifting the level sign.
            stroke("M104 72 L104 12 M104 14 L58 14 M104 14 L120 14 L104 26", "#ffc23d", 2.5)
            stroke("M98 72 L104 60 L110 72", "#ffc23d", 2)
            stroke("M64 14 L64 24", "#2b2350")
            rect(58, 24, 12, 8, "#8a5a32")
            text("3", 64, 30.5, size: 6.5, "#ffffff")
        case .xl:
            hills()
            chimney(22, 12); chimney(128, 14)
            var g = c
            g.translateBy(x: 43, y: 2)
            g.scaleBy(x: 2.6, y: 2.6)
            fill("M0 14 C0 4 7 0 12 0 C17 0 24 4 24 14 C24 22 16 26 14 30 L10 30 C8 26 0 22 0 14Z", c0, in: g)
            stroke("M4 6 C4 14 7 22 10 30 M20 6 C20 14 17 22 14 30 M12 0 L12 30", c1, 1.6, in: g)
            stroke("M2 14 L22 14", "#ffc23d", 2, in: g)
        case .baronCap:
            circle(75, 56, 14, "#fff0c8")
            valley()
            chimney(60, 26); chimney(92, 24)
            balloon(32, 18, 0.55, Self.cols[2], "#ffffff")
            balloon(108, 30, 0.5, Self.cols[3], "#ffffff")
            balloon(75, 34, 0.65, c0, c1)
            crown(75, 20, 1.1)
        case .abq:
            circle(110, 40, 10, "#fff0c8")
            mesa()
            cactus(30); cactus(126, 0.8)
            balloon(70, 12, 0.9, c0, c1)
        case .baronAbq:
            mesa()
            cactus(132, 0.7)
            many(8, 0.5, 26, 44)
            crown(75, 18, 1.2)
        case .world:
            for _ in 0..<20 {
                let x = r1(6, 138), y = r1(6, 62)
                circle(x, y, 0.7, "#fff6d0")
            }
            circle(75, 40, 26, "#2a6ab8")
            fill("M58 26 Q66 20 72 26 Q70 34 62 36 Q56 32 58 26Z M78 22 Q90 20 94 30 Q88 34 82 30Z M80 40 Q90 38 92 48 Q84 58 78 52 Q76 46 80 40Z M56 44 Q62 42 64 50 Q58 56 54 50Z", "#5ab86a")
            c.stroke(Path(ellipseIn: CGRect(x: 37, y: 32, width: 76, height: 16)), with: .color(Color(hex: "#ffc23d")),
                     style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
            balloon(36, 30, 0.45, c0, c1)
            balloon(114, 34, 0.45, Self.cols[2], "#ffffff")
            balloon(75, 4, 0.4, Self.cols[5], "#ffffff")
        }
    }
}
