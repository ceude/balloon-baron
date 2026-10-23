import SwiftUI
import BalloonBaronCore

/// The holding's open-plan office floor in the tower (prototype v68): a window over the town at sunrise, the cash
/// chart and the holding goals on a whiteboard, and a desk per department. A label opens that part of the holding
/// in a sheet that scrolls inside the screen (v73). Port of `openHQ`, `hqRender` and `hqScene`.
struct HoldingOfficeView: View {
    @Environment(GameStore.self) private var store
    @State private var unit: HoldingUnit?
    @State private var shown = false
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            // One layout for the drawing and the labels, in the safe area's coordinates; the floor runs on under
            // the home indicator.
            let ins = geo.safeAreaInsets
            let L = Layout(size: CGSize(width: geo.size.width, height: geo.size.height + ins.bottom))
            ZStack(alignment: .topLeading) {
                Color(hex: "#f3e2c6").ignoresSafeArea()
                if let s = store.state {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                        Canvas { ctx, _ in
                            var c = ctx
                            c.translateBy(x: 0, y: ins.top)
                            OfficePainter.draw(&c, L, s, t: tl.date.timeIntervalSince(start))
                        }
                    }
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    header(s)
                    ForEach(Array(HoldingUnit.allCases.enumerated()), id: \.element) { i, u in
                        spot(u, s, at: L.spot(u), delay: Double(i) * 0.05 + 0.2)
                    }
                }
            }
        }
        .opacity(shown ? 1 : 0)
        // Reduce Motion: a plain fade, without the zoom.
        .scaleEffect(shown || reduceMotion ? 1 : 1.08)
        .onAppear { withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.45)) { shown = true } }
        .sheet(item: $unit) { u in
            HoldingView(unit: u, onClose: { unit = nil })
                .environment(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func header(_ s: GameState) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(loc("holding.title", s.company)).font(Theme.font(22, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                (Text(loc("hq.cash") + " ") + Text(eurH(s.holding.cash)).font(Theme.font(16, .heavy, condensed: true)).foregroundColor(Theme.coral))
                    .font(Theme.font(12.5)).foregroundStyle(Theme.ink2)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 1, green: 250 / 255, blue: 243 / 255).opacity(0.94), in: RoundedRectangle(cornerRadius: 16))
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.ink.opacity(0.18)).offset(y: 4))
            Button {
                SoundEngine.shared.play(.click)
                withAnimation(.easeIn(duration: 0.25)) { shown = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { store.closePage() }
            } label: {
                Image(systemName: "xmark").font(.system(size: 18, weight: .heavy)).foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.line).offset(y: 3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc("world.close"))
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    /// A label over a desk: its name, its state (green when something is running), a red dot when it needs you.
    private func spot(_ u: HoldingUnit, _ s: GameState, at p: CGPoint, delay: Double) -> some View {
        let st = status(u, s)
        return Button {
            SoundEngine.shared.play(.click)
            unit = u
        } label: {
            VStack(spacing: 1) {
                (Text(loc("hq.\(u.rawValue)")) + Text(" ›").foregroundColor(Theme.coral))
                    .font(Theme.font(16, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                Text(st.text).font(Theme.font(11.5, st.on ? .bold : .regular)).foregroundStyle(st.on ? Theme.green : Theme.ink2)
            }
            .padding(.horizontal, 12).padding(.top, 6).padding(.bottom, 7)
            .background(Color(hex: "#fffaf3"), in: RoundedRectangle(cornerRadius: 13))
            .background(RoundedRectangle(cornerRadius: 13).fill(Theme.ink.opacity(0.25)).offset(y: 4))
            .overlay(alignment: .topTrailing) {
                if st.alert { Circle().fill(Theme.red).frame(width: 13, height: 13).overlay(Circle().stroke(.white, lineWidth: 2)).offset(x: 5, y: -5) }
            }
            .fixedSize()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(loc("hq.\(u.rawValue)"))
        .accessibilityValue(st.alert ? st.text + ", " + loc("a11y.attention") : st.text)
        .position(x: p.x, y: p.y - 22)
        .opacity(shown ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(delay), value: shown)
    }

    private func status(_ u: HoldingUnit, _ s: GameState) -> (text: String, on: Bool, alert: Bool) {
        let h = s.holding, d = s.day
        switch u {
        case .board: return (eurH(h.cash), false, false)
        case .window:
            let issue = s.parked.values.contains { $0.auto.issue != nil }
            return (issue ? loc("hq.s.issue") : loc("hq.s.regions", num(s.parked.count + 1)), false, issue)
        case .marketing:
            let tv = h.tvUntil > d, bb = (h.billboards[s.region] ?? 0) > d
            return (tv ? loc("hq.s.tv", num(h.tvUntil - d)) : bb ? loc("hq.s.billboards") : loc("hq.s.noCampaign"), tv || bb, false)
        case .deals:
            let c = (h.celebrity?.until ?? 0) > d ? h.celebrity : nil
            return (c.map { celebrityName($0.index) } ?? loc("hq.s.noFace"), c != nil, false)
        case .research:
            let top = h.research >= Holding.researchLevels.count
            return (top ? loc("hq.s.done") : loc("hq.s.level", num(h.research)), top, false)
        case .offices:
            return (loc("hq.s.offices", num(h.offices.count), num(Office.allCases.count)), h.offices.count == Office.allCases.count, false)
        case .records:
            if !s.recordsOpen { return (loc("hq.s.luxFirst"), false, false) }
            if let r = h.record { return (loc("hq.s.recordRun", r.kind.title, num(r.done - d)), true, false) }
            return (loc("hq.s.records", num(h.records?.count ?? 0), num(RecordAttempt.allCases.count)), false, false)
        case .shapes:
            if let a = h.adShape, a.until >= d { return (loc("hq.s.shapeRun", a.shape.title, num(a.until - d)), true, false) }
            return (loc("hq.s.noShape"), false, false)
        }
    }

    /// Where things stand on screen (also where the labels go).
    struct Layout {
        let w: CGFloat, h: CGFloat, top: CGFloat = 86
        // Three rows of desks (v105: record attempts and shaped balloons joined).
        var wall: CGFloat { top + (h - top) * 0.36 }
        var rowA: CGFloat { wall + (h - wall) * 0.24 }
        var rowB: CGFloat { wall + (h - wall) * 0.56 }
        var rowC: CGFloat { wall + (h - wall) * 0.88 }
        init(size: CGSize) { w = size.width; h = size.height }

        func spot(_ u: HoldingUnit) -> CGPoint {
            switch u {
            // Under the whiteboard, so the chart and the goals have the whole board.
            case .board: CGPoint(x: w * 0.2, y: wall - 10)
            case .window: CGPoint(x: w * 0.7, y: top + (wall - top) * 0.06 + 6)
            case .marketing: CGPoint(x: w * 0.27, y: rowA - 92)
            case .deals: CGPoint(x: w * 0.73, y: rowA - 92)
            case .research: CGPoint(x: w * 0.27, y: rowB - 92)
            case .offices: CGPoint(x: w * 0.73, y: rowB - 92)
            case .records: CGPoint(x: w * 0.27, y: rowC - 92)
            case .shapes: CGPoint(x: w * 0.73, y: rowC - 92)
            }
        }
    }
}

/// The office floor, drawn in code like the town.
private enum OfficePainter {
    static let marker = Color(hex: "#1d2a6e")
    /// The prototype's "Caveat Brush" (bundled, OFL); Japanese and Korean fall back to the system font.
    static let markerFont = "CaveatBrush-Regular"

    /// `markerFit`: the largest marker size up to `px` that fits in `maxW`.
    static func markerFit(_ c: GraphicsContext, _ s: String, maxW: CGFloat, px: CGFloat) -> (GraphicsContext.ResolvedText, CGFloat) {
        let at = { (p: CGFloat) in c.resolve(Text(s).font(.custom(markerFont, size: p)).foregroundColor(marker)) }
        let first = at(px), tw = first.measure(in: CGSize(width: 2000, height: 100)).width
        guard tw > maxW else { return (first, px) }
        let p = max(7, floor(px * maxW / tw))
        return (at(p), p)
    }

    static func draw(_ c: inout GraphicsContext, _ L: HoldingOfficeView.Layout, _ s: GameState, t: Double) {
        let w = L.w, h = L.h, top = L.top, wall = L.wall
        func rect(_ x: CGFloat, _ y: CGFloat, _ ww: CGFloat, _ hh: CGFloat, _ col: Color) { c.fill(Path(CGRect(x: x, y: y, width: ww, height: hh)), with: .color(col)) }
        // Back wall: warm plaster with panels, a cornice and a skirting board. The wall runs on up behind the status
        // bar and the floor down past the home indicator (`over`), so the office fills the whole screen.
        let over: CGFloat = 400
        c.fill(Path(CGRect(x: 0, y: -over, width: w, height: wall + over)),
               with: .linearGradient(Gradient(colors: [Color(hex: "#f6e7cf"), Color(hex: "#ecd4b0")]), startPoint: CGPoint(x: 0, y: -60), endPoint: CGPoint(x: 0, y: wall)))
        var panels = Path()
        var x: CGFloat = 0
        while x < w { panels.move(to: CGPoint(x: x, y: -over)); panels.addLine(to: CGPoint(x: x, y: wall)); x += 46 }
        c.stroke(panels, with: .color(Color(red: 160 / 255, green: 110 / 255, blue: 60 / 255).opacity(0.12)), lineWidth: 1)
        rect(0, top - 14, w, 6, Color(hex: "#d9b98e"))
        rect(0, wall - 10, w, 10, Color(hex: "#8a5a3a"))
        // Floor: wooden planks running back.
        c.fill(Path(CGRect(x: 0, y: wall, width: w, height: h - wall + over)),
               with: .linearGradient(Gradient(colors: [Color(hex: "#b98455"), Color(hex: "#d6a774")]), startPoint: CGPoint(x: 0, y: wall), endPoint: CGPoint(x: 0, y: h)))
        var planks = Path()
        let run = (h + over - wall) / (h - wall)
        for i in -8...8 {
            let x0 = w / 2 + CGFloat(i) * w * 0.04, x1 = w / 2 + CGFloat(i) * w * 0.16
            planks.move(to: CGPoint(x: x0, y: wall)); planks.addLine(to: CGPoint(x: x0 + (x1 - x0) * run, y: h + over))
        }
        for k in 1..<7 { let y = wall + (h - wall) * pow(CGFloat(k) / 7, 1.4); planks.move(to: CGPoint(x: 0, y: y)); planks.addLine(to: CGPoint(x: w, y: y)) }
        c.stroke(planks, with: .color(Color(red: 90 / 255, green: 50 / 255, blue: 25 / 255).opacity(0.18)), lineWidth: 1)
        window(&c, L, s, t: t)
        board(&c, L, s, t: t)
        desk(&c, cx: w * 0.27, y: L.rowA, kind: .marketing, k: 0, w: w, t: t)
        desk(&c, cx: w * 0.73, y: L.rowA, kind: .deals, k: 1, w: w, t: t)
        plant(&c, w * 0.5, L.rowA + 30, 0.8)
        desk(&c, cx: w * 0.27, y: L.rowB, kind: .research, k: 2, w: w, t: t)
        desk(&c, cx: w * 0.73, y: L.rowB, kind: .offices, k: 3, w: w, t: t)
        desk(&c, cx: w * 0.27, y: L.rowC, kind: .records, k: 4, w: w, t: t)
        desk(&c, cx: w * 0.73, y: L.rowC, kind: .shapes, k: 5, w: w, t: t)
        plant(&c, 12, h - 10, 1.1)
        plant(&c, w - 14, h - 6, 1)
    }

    /// The window over the town at sunrise, with chimneys, houses and drifting balloons.
    static func window(_ c: inout GraphicsContext, _ L: HoldingOfficeView.Layout, _ s: GameState, t: Double) {
        let w = L.w, top = L.top, wall = L.wall
        let x0 = w * 0.42, x1 = w - 12, y0 = top + (wall - top) * 0.1, y1 = wall - 22
        let frame = Path(roundedRect: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0), cornerRadius: 6)
        var g = c
        g.clip(to: frame)
        g.fill(frame, with: .linearGradient(Gradient(stops: [.init(color: Color(hex: "#7fa8d8"), location: 0), .init(color: Color(hex: "#f6c08a"), location: 0.55),
                                                            .init(color: Color(hex: "#ffdfae"), location: 1)]),
                                            startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: 0, y: y1)))
        let sx = x0 + (x1 - x0) * 0.72, sy = y1 - (y1 - y0) * 0.3
        g.fill(Path(ellipseIn: CGRect(x: sx - 16, y: sy - 16, width: 32, height: 32)), with: .color(Color(hex: "#fff3d0")))
        let hz = y1 - (y1 - y0) * 0.22
        var ridge = Path()
        ridge.move(to: CGPoint(x: x0, y: y1))
        var xx = x0
        while xx <= x1 + 10 { ridge.addLine(to: CGPoint(x: xx, y: hz - 6 - 5 * CGFloat(sin(Double(xx) * 0.05)))); xx += 10 }
        ridge.addLine(to: CGPoint(x: x1, y: y1))
        ridge.closeSubpath()
        g.fill(ridge, with: .color(Color(hex: "#d7a27e")))
        var R = Mulberry32(seed: 31)
        for _ in 0..<9 {
            let cx = x0 + CGFloat(R.next()) * (x1 - x0), hh = 16 + CGFloat(R.next()) * 26
            switch s.region {
            case .abq: windowButte(&g, cx, hz + 4, hh * 1.2, hh * 0.6)
            case .lux: windowPalm(&g, cx, hz + 6, hh)
            case .cap: ScenePainter.chimney(&g, cx, hz + 4, hh * 0.42, hh, body: Color(hex: "#e8b48e"), shade: Color(hex: "#c98d68"), cap: Color(hex: "#7a4e38"))
            }
        }
        for i in 0..<7 {
            let bx = x0 + 6 + CGFloat(i) * (x1 - x0) / 7, bw = 14 + CGFloat(R.next()) * 12, bh = 10 + CGFloat(R.next()) * 16
            g.fill(Path(CGRect(x: bx, y: y1 - bh, width: bw, height: bh)), with: .color(Color(hex: "#f1d6b0")))
            g.fill(Path(CGRect(x: bx + bw, y: y1 - bh + 2, width: 5, height: bh - 2)), with: .color(Color(hex: "#c9925f")))
            g.fill(Path(CGRect(x: bx + 4, y: y1 - bh + 5, width: 3, height: 4)), with: .color(Color(hex: "#ffd27a")))
        }
        let cols = [s.colors] + s.local.rivals.map(\.colors) + [["#14a39a", "#e8fff9"], ["#e0408a", "#ffd0e0"]]
        for i in 0..<7 {
            let span = Double(x1 - x0 + 40)
            let bx = x0 + CGFloat((R.next() * Double(x1 - x0) + t * (5 + Double(i) * 2)).truncatingRemainder(dividingBy: span)) - 20
            let by = y0 + 20 + CGFloat(R.next()) * (hz - y0 - 40)
            ScenePainter.balloon(&g, x: bx, y: by + CGFloat(sin(t * 0.5 + Double(i))) * 3, r: 5 + CGFloat(R.next()) * 6, colors: cols[i % cols.count], alpha: 0.95)
        }
        c.stroke(frame, with: .color(Color(hex: "#6a4a32")), lineWidth: 7)
        var bars = Path()
        for k in [1.0 / 3, 2.0 / 3] { bars.move(to: CGPoint(x: x0 + (x1 - x0) * CGFloat(k), y: y0)); bars.addLine(to: CGPoint(x: x0 + (x1 - x0) * CGFloat(k), y: y1)) }
        bars.move(to: CGPoint(x: x0, y: (y0 + y1) / 2)); bars.addLine(to: CGPoint(x: x1, y: (y0 + y1) / 2))
        c.stroke(bars, with: .color(Color(hex: "#6a4a32")), lineWidth: 4)
        c.fill(Path(CGRect(x: x0 - 8, y: y1 + 2, width: x1 - x0 + 16, height: 8)), with: .color(Color(hex: "#8a5a3a")))
        plant(&c, x0 + 22, y1 + 2, 0.55)
    }

    /// Albuquerque out of the window: a red sandstone butte (`butte`).
    static func windowButte(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        func poly(_ pts: [CGPoint], _ hex: String) {
            var p = Path(); p.move(to: pts[0]); for q in pts.dropFirst() { p.addLine(to: q) }; p.closeSubpath()
            c.fill(p, with: .color(Color(hex: hex)))
        }
        poly([CGPoint(x: x - w * 0.55, y: y), CGPoint(x: x - w * 0.42, y: y - h), CGPoint(x: x + w * 0.42, y: y - h), CGPoint(x: x + w * 0.55, y: y)], "#a65e38")
        poly([CGPoint(x: x - w * 0.55, y: y), CGPoint(x: x - w * 0.42, y: y - h), CGPoint(x: x + w * 0.05, y: y - h), CGPoint(x: x + w * 0.1, y: y)], "#d98e5e")
    }

    /// Luxor out of the window: a date palm in silhouette (`palmSil`).
    static func windowPalm(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ h: CGFloat) {
        let col = Color(hex: "#7a8a4a")
        var trunk = Path()
        trunk.move(to: CGPoint(x: x, y: y)); trunk.addQuadCurve(to: CGPoint(x: x + h * 0.04, y: y - h), control: CGPoint(x: x + h * 0.1, y: y - h * 0.5))
        c.stroke(trunk, with: .color(col), lineWidth: max(1.5, h * 0.06))
        var fronds = Path()
        for i in 0..<6 {
            let a = -Double.pi / 2 + (Double(i) - 2.5) * 0.6, ca = CGFloat(cos(a)), sa = CGFloat(sin(a))
            fronds.move(to: CGPoint(x: x + h * 0.04, y: y - h))
            fronds.addQuadCurve(to: CGPoint(x: x + h * 0.04 + ca * h * 0.45, y: y - h * 0.85 + sa * h * 0.25),
                                control: CGPoint(x: x + h * 0.04 + ca * h * 0.25, y: y - h * 1.1 + sa * h * 0.15))
        }
        c.stroke(fronds, with: .color(col), style: StrokeStyle(lineWidth: max(1.2, h * 0.05), lineCap: .round))
    }

    /// The whiteboard: the holding's cash over 14 days as a marker line, and its six goals in handwriting.
    static func board(_ c: inout GraphicsContext, _ L: HoldingOfficeView.Layout, _ s: GameState, t: Double) {
        let top = L.top, wall = L.wall, bx0: CGFloat = 12, bx1 = L.w * 0.39, by0 = top + (wall - top) * 0.14, by1 = wall - 70
        c.fill(Path(roundedRect: CGRect(x: bx0 - 4, y: by0 - 4, width: bx1 - bx0 + 8, height: by1 - by0 + 8), cornerRadius: 6), with: .color(Color(hex: "#c9ccd2")))
        c.fill(Path(roundedRect: CGRect(x: bx0, y: by0, width: bx1 - bx0, height: by1 - by0), cornerRadius: 4), with: .color(Color(hex: "#fbfcfd")))
        c.fill(Path(CGRect(x: bx0 + 10, y: by1 + 4, width: bx1 - bx0 - 20, height: 5)), with: .color(Color(hex: "#9aa0a8")))
        for (i, col) in ["#e5432f", "#2b5ab8", "#22a45d"].enumerated() {
            c.fill(Path(CGRect(x: bx0 + 20 + CGFloat(i) * 16, y: by1 + 1, width: 11, height: 4)), with: .color(Color(hex: col)))
        }
        let x = bx0 + 10, y = by0 + 14, w = bx1 - bx0 - 20, hh = by1 - by0 - 28
        // Goals in marker at the bottom; rows shrink on a short board, and the chart only draws when it still has room.
        let goals = HoldingGoal.allCases
        let row = min(max(floor((hh - 50) / CGFloat(goals.count)), 9), 15), fs = min(14, row - 1)
        let gy = y + hh - CGFloat(goals.count) * row + 6
        for (i, g) in goals.enumerated() {
            let d = s.done(g), yy = gy + CGFloat(i) * row, bs = min(8, fs * 0.6)
            c.stroke(Path(CGRect(x: x + 2, y: yy - bs, width: bs, height: bs)), with: .color(marker), lineWidth: 1.5)
            if d {
                var tick = Path()
                tick.move(to: CGPoint(x: x + 3, y: yy - bs * 0.5)); tick.addLine(to: CGPoint(x: x + 2 + bs * 0.5, y: yy - 1)); tick.addLine(to: CGPoint(x: x + 2 + bs * 1.3, y: yy - bs * 1.3))
                c.stroke(tick, with: .color(Color(hex: "#1f8a4c")), lineWidth: 2)
            }
            let (text, px) = markerFit(c, g.title, maxW: w - 18, px: fs)
            let tw = text.measure(in: CGSize(width: 2000, height: 40)).width
            c.draw(text, at: CGPoint(x: x + 15, y: yy - px * 0.2), anchor: .bottomLeading)
            if d {
                var strike = Path()
                strike.move(to: CGPoint(x: x + 14, y: yy - fs * 0.35)); strike.addLine(to: CGPoint(x: x + 16 + tw, y: yy - fs * 0.35 - 1))
                c.stroke(strike, with: .color(marker), lineWidth: 1.3)
            }
        }
        let ch = gy - y - fs - 16
        guard ch >= 22 else { return }
        var axes = Path()
        axes.move(to: CGPoint(x: x, y: y + ch)); axes.addLine(to: CGPoint(x: x + w, y: y + ch)); axes.move(to: CGPoint(x: x, y: y)); axes.addLine(to: CGPoint(x: x, y: y + ch))
        c.stroke(axes, with: .color(Color(hex: "#c9ccd2")), lineWidth: 1)
        let hist = Array(s.holding.history.suffix(14))
        guard hist.count >= 2 else {
            c.draw(Text(loc("hq.chartEmpty")).font(.custom(markerFont, size: 14)).foregroundColor(marker), at: CGPoint(x: x + 8, y: y + ch / 2), anchor: .leading)
            return
        }
        // Balance per day, worked back from today's cash.
        var bal: [Double] = [], b = Double(s.holding.cash)
        for e in hist.reversed() { bal.insert(b, at: 0); b -= Double(e.income - e.expense) }
        let lo = bal.min() ?? 0, hi = bal.max() ?? 1, span = max(1, hi - lo), drawn = min(max(t / 1.2, 0), 1)
        func P(_ i: Int) -> CGPoint { CGPoint(x: x + 6 + (w - 12) * CGFloat(i) / CGFloat(bal.count - 1), y: y + ch - 6 - CGFloat((bal[i] - lo) / span) * (ch - 14)) }
        let n = max(1, Int(drawn * Double(bal.count - 1)))
        var line = Path()
        for i in 0...n { if i == 0 { line.move(to: P(i)) } else { line.addLine(to: P(i)) } }
        c.stroke(line, with: .color(Theme.green), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        let e = P(n)
        c.fill(Path(ellipseIn: CGRect(x: e.x - 4, y: e.y - 4, width: 8, height: 8)), with: .color(Theme.green))
        c.draw(Text(loc("paper.day", num(hist[0].day))).font(.custom(markerFont, size: 12)).foregroundColor(marker), at: CGPoint(x: x + 4, y: y + ch + 11), anchor: .leading)
        c.draw(Text(loc("paper.day", num(hist[hist.count - 1].day))).font(.custom(markerFont, size: 12)).foregroundColor(marker), at: CGPoint(x: x + w, y: y + ch + 11), anchor: .trailing)
    }

    /// A desk with a person behind it, a monitor and the department's things on top.
    static func desk(_ c: inout GraphicsContext, cx: CGFloat, y: CGFloat, kind: HoldingUnit, k: Int, w: CGFloat, t: Double) {
        func fill(_ p: Path, _ hex: String) { c.fill(p, with: .color(Color(hex: hex))) }
        func rr(_ x: CGFloat, _ y: CGFloat, _ ww: CGFloat, _ hh: CGFloat, _ r: CGFloat) -> Path { Path(roundedRect: CGRect(x: x, y: y, width: ww, height: hh), cornerRadius: r) }
        let dw = min(w * 0.4, 170), dh: CGFloat = 14, x = cx - dw / 2
        fill(rr(cx - 22 + CGFloat(k) * 8, y - 66, 34, 40, 8), "#3d3560")
        let bob = CGFloat(sin(t * 2 + Double(k))) * 1.2, px = cx - 6 + CGFloat(k) * 8
        fill(rr(px - 13, y - 44 + bob, 26, 30, 9), ["#ff5e3a", "#14a39a", "#9b7be0", "#ffc23d", "#5aa9e6", "#e0408a"][k])
        fill(Path(ellipseIn: CGRect(x: px - 10, y: y - 64 + bob, width: 20, height: 20)), "#e0a47a")
        var hair = Path()
        hair.addArc(center: CGPoint(x: px, y: y - 58 + bob), radius: 10, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        fill(hair, ["#3a2418", "#1f1b2e", "#7a4a24", "#2b2350", "#c9a040", "#1f1b2e"][k])
        fill(rr(x, y - dh, dw, dh, 5), "#e8c495")
        fill(Path(CGRect(x: x + 6, y: y, width: dw - 12, height: 34)), "#b07a48")
        fill(Path(CGRect(x: x + 6, y: y + 30, width: dw - 12, height: 4)), "#9a6a3c")
        let mx = cx + dw * 0.18
        fill(rr(mx - 26, y - dh - 42, 52, 34, 4), "#2b2350")
        fill(Path(CGRect(x: mx - 3, y: y - dh - 9, width: 6, height: 9)), "#2b2350")
        c.fill(Path(CGRect(x: mx - 22, y: y - dh - 38, width: 44, height: 26)),
               with: .linearGradient(Gradient(colors: [Color(hex: "#6aa5d8"), Color(hex: "#bfe0ff")]), startPoint: CGPoint(x: 0, y: y - dh - 38), endPoint: CGPoint(x: 0, y: y - dh - 12)))
        switch kind {
        case .marketing:
            var play = Path(); play.move(to: CGPoint(x: mx - 6, y: y - dh - 32)); play.addLine(to: CGPoint(x: mx + 8, y: y - dh - 25)); play.addLine(to: CGPoint(x: mx - 6, y: y - dh - 18)); play.closeSubpath()
            fill(play, "#ff5e3a")
            var mega = Path(); mega.move(to: CGPoint(x: x + 18, y: y - dh - 8)); mega.addLine(to: CGPoint(x: x + 40, y: y - dh - 18)); mega.addLine(to: CGPoint(x: x + 40, y: y - dh)); mega.closeSubpath()
            fill(mega, "#ffc23d")
        case .deals:
            var star = Path()
            for i in 0..<10 {
                let a = -Double.pi / 2 + Double(i) * Double.pi / 5, r: CGFloat = i % 2 == 1 ? 5 : 11
                let p = CGPoint(x: mx + CGFloat(cos(a)) * r, y: y - dh - 25 + CGFloat(sin(a)) * r)
                if i == 0 { star.move(to: p) } else { star.addLine(to: p) }
            }
            star.closeSubpath()
            fill(star, "#ffc23d")
            fill(Path(CGRect(x: x + 16, y: y - dh - 12, width: 28, height: 12)), "#ffffff")
        case .research:
            var graph = Path(); graph.move(to: CGPoint(x: mx - 18, y: y - dh - 16)); graph.addLine(to: CGPoint(x: mx - 6, y: y - dh - 26)); graph.addLine(to: CGPoint(x: mx + 4, y: y - dh - 20)); graph.addLine(to: CGPoint(x: mx + 18, y: y - dh - 34))
            c.stroke(graph, with: .color(Theme.green), lineWidth: 2)
            let fx = x + 22
            var flask = Path(); flask.move(to: CGPoint(x: fx - 3, y: y - dh - 22)); flask.addLine(to: CGPoint(x: fx + 3, y: y - dh - 22)); flask.addLine(to: CGPoint(x: fx + 10, y: y - dh)); flask.addLine(to: CGPoint(x: fx - 10, y: y - dh)); flask.closeSubpath()
            fill(flask, "#3ad0c0")
            for (i, col) in ["#ff5e3a", "#ffc23d", "#5aa9e6"].enumerated() { fill(Path(CGRect(x: x + 40 + CGFloat(i) * 9, y: y - dh - 4 - CGFloat(i) * 2, width: 12, height: 5)), col) }
        case .offices:
            fill(Path(ellipseIn: CGRect(x: mx - 10, y: y - dh - 35, width: 20, height: 20)), "#2b5ab8")
            let gx = x + 26
            fill(Path(CGRect(x: gx - 7, y: y - dh - 3, width: 14, height: 3)), "#7a4a24")
            fill(Path(ellipseIn: CGRect(x: gx - 11, y: y - dh - 26, width: 22, height: 22)), "#5aa9e6")
            fill(Path(ellipseIn: CGRect(x: gx - 7, y: y - dh - 21, width: 10, height: 8)), "#7aa04a")
        case .records:
            var climb = Path(); climb.move(to: CGPoint(x: mx - 18, y: y - dh - 14)); climb.addQuadCurve(to: CGPoint(x: mx + 16, y: y - dh - 36), control: CGPoint(x: mx, y: y - dh - 16))
            c.stroke(climb, with: .color(Color(hex: "#e5432f")), lineWidth: 2)
            // A model of the pressurised capsule under its balloon.
            let gx = x + 26
            fill(Path(ellipseIn: CGRect(x: gx - 10, y: y - dh - 22, width: 20, height: 20)), "#c9ccd2")
            fill(Path(ellipseIn: CGRect(x: gx - 0.5, y: y - dh - 17.5, width: 7, height: 7)), "#2b5ab8")
            var rope = Path(); rope.move(to: CGPoint(x: gx, y: y - dh - 22)); rope.addLine(to: CGPoint(x: gx, y: y - dh - 34))
            c.stroke(rope, with: .color(Color(hex: "#7a4a24")), lineWidth: 1.2)
            fill(Path(ellipseIn: CGRect(x: gx - 7, y: y - dh - 47, width: 14, height: 14)), "#ffc23d")
        case .shapes:
            AdShapeArt.draw(&c, .bottle, center: CGPoint(x: mx, y: y - dh - 25), size: 30)
            AdShapeArt.draw(&c, .rocket, center: CGPoint(x: x + 26, y: y - dh - 14), size: 26)
        default: break
        }
        // A coffee cup with a curl of steam.
        fill(Path(CGRect(x: cx + dw * 0.4 - 6, y: y - dh - 9, width: 9, height: 9)), "#ffffff")
        var steam = Path()
        steam.move(to: CGPoint(x: cx + dw * 0.4 - 2, y: y - dh - 12))
        steam.addQuadCurve(to: CGPoint(x: cx + dw * 0.4 - 2, y: y - dh - 24), control: CGPoint(x: cx + dw * 0.4 + 2 + CGFloat(sin(t * 3)) * 2, y: y - dh - 18))
        c.stroke(steam, with: .color(.white.opacity(0.6)), lineWidth: 1.2)
    }

    static func plant(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ k: CGFloat) {
        var pot = Path()
        pot.move(to: CGPoint(x: x - 12 * k, y: y - 22 * k)); pot.addLine(to: CGPoint(x: x + 12 * k, y: y - 22 * k)); pot.addLine(to: CGPoint(x: x + 9 * k, y: y)); pot.addLine(to: CGPoint(x: x - 9 * k, y: y)); pot.closeSubpath()
        c.fill(pot, with: .color(Color(hex: "#c0583a")))
        for i in 0..<7 {
            let a = -Double.pi / 2 + Double(i - 3) * 0.38
            var leaf = c
            leaf.translateBy(x: x + CGFloat(cos(a)) * 16 * k, y: y - 22 * k + CGFloat(sin(a)) * 22 * k)
            leaf.rotate(by: .radians(a + .pi / 2))
            leaf.fill(Path(ellipseIn: CGRect(x: -5 * k, y: -14 * k, width: 10 * k, height: 28 * k)), with: .color(Color(hex: i % 2 == 1 ? "#4f8a3a" : "#6faa4a")))
        }
    }
}
