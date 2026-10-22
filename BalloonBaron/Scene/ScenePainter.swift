import SwiftUI
import BalloonBaronCore

/// A balloon drifting in the background (rivals, your own fleet, Fiesta crowds). Positions in meters.
struct BackgroundBalloon {
    var x: Double
    var alt: Double
    var colors: [String]
    var phase: Double
    var scale: Double
}

/// Maps world meters to screen points, like the prototype's `sx` / `sy`.
struct SceneCamera {
    let size: CGSize
    let groundY: CGFloat
    let topY: CGFloat
    let camX: Double
    let kx: CGFloat
    var ky: CGFloat { (groundY - topY) / 650 }
    var viewHeight: CGFloat { groundY - topY }

    init(size: CGSize, groundY: CGFloat, topY: CGFloat, focusX: Double, focusAt: CGFloat = 0.36) {
        self.size = size
        self.groundY = groundY
        self.topY = topY
        kx = min(max(size.width / 900, 0.4), 1.4)
        camX = focusX - Double(size.width * focusAt / kx)
    }

    func sx(_ wx: Double) -> CGFloat { CGFloat(wx - camX) * kx }
    func sy(_ alt: Double) -> CGFloat { groundY - CGFloat(alt) * ky }
}

/// Port of the prototype's canvas drawing: sky, sun, ridges, fairy chimneys (mesas and cottonwoods
/// in Albuquerque), snow, and balloons with designs and sponsor banners.
enum ScenePainter {
    // MARK: Colors

    static func rgb(_ hex: String) -> (Double, Double, Double) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0
        return (Double((v >> 16) & 0xff), Double((v >> 8) & 0xff), Double(v & 0xff))
    }

    /// `mix(a, b, k)`: blend two hex colors.
    static func mix(_ a: String, _ b: String, _ k: Double) -> Color {
        let k = min(max(k, 0), 1), x = rgb(a), y = rgb(b)
        return Color(red: (x.0 + (y.0 - x.0) * k) / 255, green: (x.1 + (y.1 - x.1) * k) / 255, blue: (x.2 + (y.2 - x.2) * k) / 255)
    }

    static func mixHex(_ a: String, _ b: String, _ k: Double) -> String {
        let k = min(max(k, 0), 1), x = rgb(a), y = rgb(b)
        let r = Int((x.0 + (y.0 - x.0) * k).rounded()), g = Int((x.1 + (y.1 - x.1) * k).rounded()), bl = Int((x.2 + (y.2 - x.2) * k).rounded())
        return String(format: "#%02x%02x%02x", r, g, bl)
    }

    // MARK: Shapes

    static func ell(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: Color) {
        let rx = max(0.1, rx), ry = max(0.1, ry)
        ctx.fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), with: .color(c))
    }

    static func rect(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(c))
    }

    static func chimney(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat,
                        body: Color, shade: Color?, cap: Color) {
        var p = Path()
        p.move(to: CGPoint(x: x - w / 2, y: base))
        p.addQuadCurve(to: CGPoint(x: x - w * 0.12, y: base - hgt), control: CGPoint(x: x - w * 0.32, y: base - hgt * 0.55))
        p.addLine(to: CGPoint(x: x + w * 0.12, y: base - hgt))
        p.addQuadCurve(to: CGPoint(x: x + w / 2, y: base), control: CGPoint(x: x + w * 0.32, y: base - hgt * 0.55))
        p.closeSubpath()
        ctx.fill(p, with: .color(body))
        if let shade {
            var s = Path()
            s.move(to: CGPoint(x: x + w * 0.05, y: base - hgt))
            s.addLine(to: CGPoint(x: x + w * 0.12, y: base - hgt))
            s.addQuadCurve(to: CGPoint(x: x + w / 2, y: base), control: CGPoint(x: x + w * 0.32, y: base - hgt * 0.55))
            s.addLine(to: CGPoint(x: x + w * 0.1, y: base))
            s.closeSubpath()
            ctx.fill(s, with: .color(shade))
        }
        ell(&ctx, x, base - hgt, w * 0.25, w * 0.1, cap)
        ell(&ctx, x, base - hgt - w * 0.07, w * 0.15, w * 0.09, cap)
    }

    static func mesa(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat, body: Color, cap: Color) {
        var p = Path()
        p.move(to: CGPoint(x: x - w / 2, y: base))
        p.addLine(to: CGPoint(x: x - w * 0.32, y: base - hgt))
        p.addLine(to: CGPoint(x: x + w * 0.3, y: base - hgt))
        p.addLine(to: CGPoint(x: x + w / 2, y: base))
        p.closeSubpath()
        ctx.fill(p, with: .color(body))
        rect(&ctx, x - w * 0.33, base - hgt - 2, w * 0.64, 4, cap)
    }

    static func tree(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat, crown: Color, trunk: Color) {
        rect(&ctx, x - w * 0.07, base - hgt * 0.45, w * 0.14, hgt * 0.45, trunk)
        ell(&ctx, x, base - hgt * 0.62, w * 0.5, hgt * 0.3, crown)
        ell(&ctx, x - w * 0.22, base - hgt * 0.5, w * 0.3, hgt * 0.2, crown)
        ell(&ctx, x + w * 0.2, base - hgt * 0.78, w * 0.3, hgt * 0.2, crown)
    }

    static func heart(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ c: Color) {
        ctx.fill(BalloonPainter.heart(x, y, s), with: .color(c))
    }

    /// Sponsor banner text and colors, per region.
    static func banner(_ sp: Sponsor, region: RegionID) -> String {
        let cap = ["HALI EVİ", "BAĞLAR", "PERİ BANK", "TURBO!"], abq = ["GREEN CHILE", "WINERY", "TURQUOISE", "ROUTE 66!"]
        let i = Sponsor.allCases.firstIndex(of: sp) ?? 0
        return (region == .abq ? abq : cap)[i]
    }

    /// `balloon(x, y, R, …)`: y is the bottom of the basket.
    static func balloon(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r R: CGFloat, colors: [String], burn: Bool = false,
                        alpha: Double = 1, ad: Sponsor? = nil, design: Design? = nil, region: RegionID = .cap, time T: Double = 0) {
        guard R > 0.5 else { return }
        var c = ctx
        c.opacity = alpha
        let top = y - R * 2.55, cy = top + R
        let main = Color(hex: design?.colors.first ?? colors.first ?? "#ff5e3a")
        let env = design?.shape.map { BalloonPainter.envelope($0, x: x, cy: cy, r: R) } ?? BalloonPainter.envelope(x: x, cy: cy, r: R)
        c.fill(env, with: .color(main))
        var inner = c
        inner.clip(to: env)
        if let d = design, d.colors.count >= 3 {
            BalloonPainter.paint(&inner, pattern: d.pattern, colors: d.colors, x: x, cy: cy, r: R, top: top)
        } else {
            BalloonPainter.stripes(&inner, color: Color(hex: colors.count > 1 ? colors[1] : "#ffc23d"), x: x, cy: cy, r: R)
        }
        if let ad {
            let col = ad.colors
            rect(&inner, x - R, cy + R * 0.12, R * 2, R * 0.52, Color(hex: col.bg))
            let text = Text(banner(ad, region: region))
                .font(.custom("BarlowCondensed-ExtraBold", size: max(7, (R * 0.36).rounded())))
                .foregroundColor(Color(hex: col.fg))
            inner.draw(text, at: CGPoint(x: x, y: cy + R * 0.38), anchor: .center)
        }
        let shade = Gradient(stops: [
            .init(color: Color.white.opacity(0.18), location: 0),
            .init(color: Color.black.opacity(0), location: 0.6),
            .init(color: Color(red: 40 / 255, green: 10 / 255, blue: 40 / 255).opacity(0.35), location: 1)
        ])
        inner.fill(Path(CGRect(x: x - R, y: top, width: R * 2, height: R * 3)),
                   with: .linearGradient(shade, startPoint: CGPoint(x: x - R, y: 0), endPoint: CGPoint(x: x + R, y: 0)))
        if design?.shape == .hezarfen { BalloonPainter.hezarfenFace(&c, x: x, cy: cy, r: R) }
        let by = cy + R * 1.55, bb = y - R * 0.32
        var ropes = Path()
        ropes.move(to: CGPoint(x: x - R * 0.22, y: by)); ropes.addLine(to: CGPoint(x: x - R * 0.24, y: bb))
        ropes.move(to: CGPoint(x: x + R * 0.22, y: by)); ropes.addLine(to: CGPoint(x: x + R * 0.24, y: bb))
        c.stroke(ropes, with: .color(Color(red: 60 / 255, green: 35 / 255, blue: 30 / 255).opacity(0.8)), lineWidth: 1)
        rect(&c, x - R * 0.3, bb, R * 0.6, R * 0.32, Color(hex: "#6b4426"))
        if burn {
            let f = 1 + sin(T * 40) * 0.2
            ell(&c, x, by + R * 0.02, R * 0.1, R * 0.28 * f, Color(red: 1, green: 200 / 255, blue: 90 / 255).opacity(0.95))
            ell(&c, x, by + R * 0.06, R * 0.05, R * 0.14 * f, Color(hex: "#fff4cc"))
        }
    }

    // MARK: Scenery

    /// `scenery()`: sky, sun, distant ridges and chimneys, background balloons, ground, river and snow.
    /// `p` is time of day, 0 = dawn, 1 = bright morning. Returns the view height above the ground.
    @discardableResult
    static func scenery(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double, region: RegionID, winter: Bool,
                        time T: Double, background: [BackgroundBalloon], inFlight: Bool) -> CGFloat {
        let W = cam.size.width, H = cam.size.height, groundY = cam.groundY, topY = cam.topY, kx = cam.kx, camX = cam.camX
        let desert = region == .abq
        let sky = desert
            ? Gradient(stops: [.init(color: mix("#1d2450", "#6aa5d8", p), location: 0), .init(color: mix("#7a4a6a", "#f6c08a", p), location: 0.55),
                               .init(color: mix("#f39a5a", "#ffe6b0", p), location: 1)])
            : Gradient(stops: [.init(color: mix("#1b1840", "#5f8fc6", p), location: 0), .init(color: mix("#6b3e6e", "#f0b48c", p), location: 0.55),
                               .init(color: mix("#f08a4a", "#ffe2ac", p), location: 1)])
        ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: groundY)),
                 with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: groundY)))

        let sunX = W * 0.7 - CGFloat(camX) * kx * 0.02, sunY = groundY - (groundY - topY) * (0.04 + CGFloat(p) * 0.5), sr = min(W, H) * 0.05
        let glow = Gradient(colors: [Color(red: 1, green: 220 / 255, blue: 150 / 255).opacity(0.55), Color(red: 1, green: 200 / 255, blue: 140 / 255).opacity(0)])
        ctx.fill(Path(CGRect(x: sunX - sr * 6, y: sunY - sr * 6, width: sr * 12, height: sr * 12)),
                 with: .radialGradient(glow, center: CGPoint(x: sunX, y: sunY), startRadius: 0, endRadius: sr * 6))
        ell(&ctx, sunX, sunY, sr, sr, Color(hex: "#fff0c8"))

        let vh = groundY - topY
        if desert {
            // Sandia mountains, watermelon pink at sunrise.
            var m = Path()
            m.move(to: CGPoint(x: W * 0.15, y: groundY))
            var x = W * 0.15
            while x <= W + 40 {
                let wx = Double(x / kx + CGFloat(camX) * 0.08) * 0.006
                let k = min(max((x - W * 0.15) / (W * 0.3), 0), 1)
                m.addLine(to: CGPoint(x: x, y: groundY - vh * CGFloat(0.13 + 0.05 * sin(wx * 1.3 + 1) + 0.02 * sin(wx * 5.1)) * k))
                x += 18
            }
            m.addLine(to: CGPoint(x: W + 40, y: groundY))
            m.closeSubpath()
            ctx.fill(m, with: .color(mix("#4e2c4c", "#d98a96", p)))
        }
        var ridge = Path()
        ridge.move(to: CGPoint(x: 0, y: groundY))
        var rx: CGFloat = -20
        while rx <= W + 40 {
            let wx = Double(rx / kx + CGFloat(camX) * 0.15) * 0.01
            ridge.addLine(to: CGPoint(x: rx, y: groundY - vh * CGFloat(0.11 + 0.06 * sin(wx * 1.7) + 0.035 * sin(wx * 4.3))))
            rx += 40
        }
        ridge.addLine(to: CGPoint(x: W, y: groundY))
        ridge.closeSubpath()
        ctx.fill(ridge, with: .color(desert ? mix("#5a3a40", "#c99a74", p) : mix("#4a3050", "#c9967e", p)))

        var r = Mulberry32(seed: 5)
        for i in 0..<40 {
            let wx = Double(i) * 130 + r.next() * 60 - 600
            let x = CGFloat(wx - camX * 0.45) * kx
            let hh = vh * CGFloat(0.07 + r.next() * 0.1), ww = hh * CGFloat(0.4 + r.next() * 0.2)
            if x < -60 || x > W + 60 { continue }
            let snow = Color(hex: "#eef2f8")
            if desert {
                mesa(&ctx, x, groundY + 2, ww * 2.6, hh * 0.6, body: mix("#5e3a3a", "#c98a5e", p), cap: winter ? snow : mix("#4a2c2c", "#a86a44", p))
            } else {
                chimney(&ctx, x, groundY + 2, ww, hh, body: mix("#5c3a4a", "#d9a07a", p), shade: nil, cap: winter ? snow : mix("#3e2836", "#9a6448", p))
            }
        }

        let par = inFlight ? 0.7 : 1.0
        for b in background {
            let xx = CGFloat(b.x - camX * par) * kx
            guard xx > -50 && xx < W + 50 else { continue }
            let yy = cam.sy(b.alt + sin(T * 0.4 + b.phase) * 6)
            balloon(&ctx, x: xx, y: yy, r: max(6, vh * 0.045 * CGFloat(b.scale) * (inFlight ? 0.75 : 1)), colors: b.colors,
                    alpha: inFlight ? 0.45 : 0.92, region: region)
        }

        let ground = winter
            ? Gradient(colors: [mix("#c9d3e2", "#eef3fa", p), mix("#7d879c", "#b9c4d6", p)])
            : desert ? Gradient(colors: [mix("#6a4a30", "#d8b07a", p), mix("#3a2a1e", "#a07848", p)])
            : Gradient(colors: [mix("#5a3a32", "#c48a62", p), mix("#2e1e22", "#7a5040", p)])
        ctx.fill(Path(CGRect(x: 0, y: groundY, width: W, height: H - groundY)),
                 with: .linearGradient(ground, startPoint: CGPoint(x: 0, y: groundY), endPoint: CGPoint(x: 0, y: H)))
        if desert {
            // Rio Grande.
            rect(&ctx, 0, groundY + (H - groundY) * 0.42, W, max(3, (H - groundY) * 0.07), mix("#2e4a66", "#7fb6d6", p))
        }
        if winter {
            rect(&ctx, 0, 0, W, groundY, Color(red: 200 / 255, green: 220 / 255, blue: 1).opacity(0.12))
            for i in 0..<90 {
                let fi = Double(i)
                let sx2 = CGFloat((fi * 97.3 + T * (14 + Double(i % 4) * 6)).truncatingRemainder(dividingBy: Double(W + 20))) - 10 + CGFloat(sin(T + fi) * 6)
                let sy2 = CGFloat((fi * 53.7 + T * (26 + Double(i % 5) * 9)).truncatingRemainder(dividingBy: Double(H)))
                let rr = 1 + CGFloat(i % 3) * 0.6
                ell(&ctx, sx2, sy2, rr, rr, Color.white.opacity(0.85))
            }
        }
        return vh
    }

    /// Moves background balloons with the wind and wraps them around the view.
    static func drift(_ bg: inout [BackgroundBalloon], weather: Weather, cam: SceneCamera, dt: Double, time T: Double, inFlight: Bool) {
        let par = inFlight ? 0.7 : 1.0, cx = cam.camX * par, span = Double(cam.size.width / cam.kx)
        for i in bg.indices {
            bg[i].x += FlightWorld.wind(at: bg[i].alt, time: T * 6, weather) * dt * (inFlight ? FlightWorld.timeScale : 2)
            if bg[i].x > cx + span + 900 { bg[i].x = cx - 600 }
            if bg[i].x < cx - 900 { bg[i].x = cx + span + 500 }
        }
    }

    /// `buildWorld()`'s background balloons: rivals' fleets, the rest of yours, and Fiesta crowds.
    static func backgroundBalloons(_ s: GameState) -> [BackgroundBalloon] {
        var owners: [[String]] = []
        for r in s.rivals where r.alive { for _ in r.balloons { owners.append(r.colors) } }
        for _ in 0..<max(0, s.balloons.count - 1) { owners.append(s.colors) }
        if s.fiesta != nil {
            let sw = Studio.swatches
            for i in 0..<30 { owners.append([sw[i % sw.count], sw[(i + 3) % sw.count]]) }
        }
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: s.weather?.seed ?? 1) &+ 99)
        let n = min(s.fiesta != nil ? Rules.fiestaBalloons : 18, owners.count)
        return (0..<n).map { i in
            BackgroundBalloon(x: -400 + r.next() * 3800, alt: 60 + r.next() * 500, colors: owners[i % owners.count],
                              phase: r.next() * 6, scale: 0.55 + r.next() * 0.3)
        }
    }

    /// The landing field: green strip, two flags, the chase truck and trailer.
    static func landingField(_ ctx: inout GraphicsContext, cam: SceneCamera, target tx: Double, p: Double) {
        let gy = cam.groundY
        let x0 = cam.sx(tx - FlightWorld.landingZone), x1 = cam.sx(tx + FlightWorld.landingZone)
        rect(&ctx, x0, gy - 2, x1 - x0, 7, mix("#4b5a34", "#a7b46a", p))
        for fx in [tx - FlightWorld.landingZone, tx + FlightWorld.landingZone] { flag(&ctx, cam.sx(fx), gy, 22) }
        let trx = cam.sx(tx + 35)
        rect(&ctx, trx, gy - 13, 22, 9, Color(hex: "#f2eee6"))
        rect(&ctx, trx + 14, gy - 18, 9, 6, Color(hex: "#f2eee6"))
        rect(&ctx, trx - 18, gy - 10, 16, 6, Color(hex: "#7b5a3c"))
        for wx in [trx + 4, trx + 18, trx - 10] { ell(&ctx, wx, gy - 3, 3, 3, Color(hex: "#1d1418")) }
    }

    static func flag(_ ctx: inout GraphicsContext, _ X: CGFloat, _ gy: CGFloat, _ h: CGFloat) {
        var pole = Path()
        pole.move(to: CGPoint(x: X, y: gy)); pole.addLine(to: CGPoint(x: X, y: gy - h))
        ctx.stroke(pole, with: .color(Color(hex: "#2a1a14")), lineWidth: 1.5)
        var f = Path()
        f.move(to: CGPoint(x: X, y: gy - h)); f.addLine(to: CGPoint(x: X + 11, y: gy - h + 4)); f.addLine(to: CGPoint(x: X, y: gy - h + 8))
        f.closeSubpath()
        ctx.fill(f, with: .color(Color(hex: "#ffc23d")))
    }

    /// Fairy chimneys (or cottonwoods) along the flight path, in front of the far scenery.
    static func obstacles(_ ctx: inout GraphicsContext, cam: SceneCamera, _ obs: [Obstacle], region: RegionID, p: Double) {
        let W = cam.size.width
        for c in obs {
            let x = cam.sx(c.x)
            if x < -80 || x > W + 80 { continue }
            if region == .abq {
                tree(&ctx, x, cam.groundY + 1, CGFloat(c.w) * cam.kx * 1.4, CGFloat(c.h) * cam.ky,
                     crown: mix(mixHex("#2e4a2a", "#7a9a52", p), "#9ab060", c.tone * 0.3), trunk: mix("#3a2a1e", "#6a4a30", p))
            } else {
                chimney(&ctx, x, cam.groundY + 1, CGFloat(c.w) * cam.kx, CGFloat(c.h) * cam.ky,
                        body: mix(mixHex("#6a4038", "#e2b48a", p), "#d6a27a", c.tone * 0.3),
                        shade: mix("#4a2c2a", "#b07a58", p), cap: mix("#3a2420", "#7e5038", p))
            }
        }
    }
}
