import SwiftUI
import BalloonBaronCore

/// While passengers gather the town's camera sits on your booking office: they walk up from the road and queue
/// in front (one figure stands for several in a big company). Taking off, open safari jeeps pull up, everyone
/// climbs in and the jeeps drive off; then the flight opens. Port of `collectItems` and `leaveCollect`.
/// A plain class shared by the collect card (which counts) and the town canvas (which draws); not observed.
final class CollectScene {
    struct Person { var i: Int; var t0: Double; var from: (Double, Double); var color: String }

    static let queueMax = 30, jeepSeats = 6, jeepRowY = 14.95
    static let kiosk = (9.3, 13.4)

    /// Seats filled so far and the day's total.
    var shown = 0, total = 0
    /// Painter time when take-off was pressed.
    var leaveAt: Double?
    var people: [Person] = []
    /// When take-off was pressed (the canvas turns it into painter time).
    var leaveDate: Date?
    /// The camera's glide from the home view: start time and start view; and the view it settles on.
    var from: (t: Double, view: TownViewport)?
    var target: TownViewport?
    /// The horizon to keep when the glide starts from the morning's town (the night's camera).
    var hzFix: CGFloat?
    /// Top of the collect card on screen, so the camera centres the office above it.
    var cardTop: CGFloat = 0

    func reset() {
        shown = 0; total = 0; leaveAt = nil; leaveDate = nil; people = []; from = nil; target = nil; hzFix = nil
    }

    static func queueSpot(_ i: Int) -> (Double, Double) { (8.85 + Double(i % 6) * 0.24, 13.72 + Double(i / 6) * 0.19) }
    static func stop(_ j: Int) -> (Double, Double) { (9.05 + Double(j) * 0.95, jeepRowY) }

    /// Point at distance `s` along a path of grid points, and the direction there.
    static func walk(_ pts: [(Double, Double)], _ s0: Double) -> (p: (Double, Double), dir: (Double, Double)) {
        var s = s0
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i], d = hypot(b.0 - a.0, b.1 - a.1)
            if s <= d || i == pts.count - 1 {
                let k = min(max(s / max(d, 1e-6), 0), 1)
                return ((a.0 + (b.0 - a.0) * k, a.1 + (b.1 - a.1) * k), (b.0 - a.0, b.1 - a.1))
            }
            s -= d
        }
        return (pts[pts.count - 1], (1, 0))
    }

    static func easeIO(_ k: Double) -> Double { k < 0.5 ? 2 * k * k : 1 - pow(-2 * k + 2, 2) / 2 }

    /// The camera on the kiosk, centred between the top bar and the collect card.
    static func view(size: CGSize, top: CGFloat, bottom: CGFloat) -> TownViewport {
        let z = min(max(size.width / 520, 0.7), 1.1), c = TownGeo.iso(kiosk.0 + 0.2, kiosk.1 + 0.35)
        return TownViewport(z: z, ox: size.width / 2 - c.x * z, oy: (top + bottom) / 2 + 30 - c.y * z)
    }
}

extension TownPainter {
    /// The queue, the passenger count over it and, after take-off, the jeeps.
    func collectItems(_ sc: CollectScene) -> [TownItem] {
        var items: [TownItem] = []
        let tt = t, total = sc.total
        let want = total <= CollectScene.queueMax ? sc.shown : Int((Double(sc.shown) / Double(max(1, total)) * Double(CollectScene.queueMax)).rounded())
        let shirts = ["#2b2350", "#ff5e3a", "#14a39a", "#ffc23d", "#9b7be0", "#5aa9e6", "#ff6fa8"]
        while sc.people.count < want {
            let i = sc.people.count
            let a = abs(sin(Double(i) * 12.9898) * 43758.5).truncatingRemainder(dividingBy: 1), b = abs(sin(Double(i) * 78.233) * 24634.6).truncatingRemainder(dividingBy: 1)
            sc.people.append(.init(i: i, t0: tt, from: (8 + (a - 0.5) * 0.5, 9.5 + b * 2), color: shirts[i % shirts.count]))
        }
        let P = sc.people.count, J = min(max(Int((Double(P) / Double(CollectScene.jeepSeats)).rounded(.up)), 1), 5)
        let tl = sc.leaveAt.map { tt - $0 } ?? -1
        func jeepOf(_ i: Int) -> Int { min(J - 1, i * J / max(1, P)) }
        for p in sc.people {
            let spot = CollectScene.queueSpot(p.i), j = jeepOf(p.i)
            var pos: (Double, Double)
            let tb = tl - (1.15 + Double(p.i) * 0.025)
            if tb > 0 {
                let k = min(max(tb / 0.55, 0), 1), st = CollectScene.stop(j)
                if k >= 1 { continue }
                pos = (spot.0 + (st.0 - spot.0) * k, spot.1 + (st.1 - 0.25 - spot.1) * k)
            } else {
                let k = min(max((tt - p.t0) / 1.3, 0), 1)
                let len = abs(p.from.1 - spot.1) + abs(8 - spot.0)
                pos = CollectScene.walk([p.from, (8, spot.1), spot], CollectScene.easeIO(k) * len).p
            }
            let at = pos, col = p.color, ph = Double(p.i)
            items.append(TownItem(depth: at.0 + at.1, draw: { pp in let q = TownGeo.iso(at.0, at.1); pp.person(q.x, q.y, col, tt, ph) }))
        }
        // The passenger count over the queue, so a big day still reads right.
        if sc.shown > 0 {
            let left = tl > 0 ? max(0, sc.shown - Int((Double(sc.shown) * min(max((tl - 1.15) / 1.2, 0), 1)).rounded())) : sc.shown
            let text = loc("collect.queue", num(left))
            items.append(TownItem(depth: 99, draw: { pp in
                let q = TownGeo.iso(9.4, 13.9)
                let r = pp.c.resolve(Text(text).font(.custom("BarlowCondensed-ExtraBold", size: 19)).foregroundColor(Color(hex: "#2b2350")))
                let w = r.measure(in: CGSize(width: 400, height: 40)).width + 22
                pp.c.fill(Path(roundedRect: CGRect(x: q.x - w / 2, y: q.y - 70, width: w, height: 28), cornerRadius: 14),
                          with: .color(Color(red: 1, green: 250 / 255, blue: 243 / 255).opacity(0.95)))
                pp.c.draw(r, at: CGPoint(x: q.x, y: q.y - 56), anchor: .center)
            }))
        }
        if sc.leaveAt != nil {
            for j in 0..<J {
                let tin = tl - Double(j) * 0.12, tout = tl - 2 - Double(j) * 0.12, st = CollectScene.stop(j)
                let r: (p: (Double, Double), dir: (Double, Double))
                if tout > 0 {
                    r = CollectScene.walk([st, (8, CollectScene.jeepRowY), (8, 22)], pow(tout, 1.6) * 7)
                } else {
                    let len = 4.75 + abs(st.0 - 8)
                    r = CollectScene.walk([(8, 10.2), (8, CollectScene.jeepRowY), st], CollectScene.easeIO(min(max(tin, 0), 1)) * len)
                }
                let alongX = abs(r.dir.0) > abs(r.dir.1), pos = r.p
                let boarded = sc.people.filter { jeepOf($0.i) == j && tl > 1.15 + Double($0.i) * 0.025 + 0.55 }.count
                items.append(TownItem(depth: pos.0 + pos.1 + 0.3, draw: { pp in pp.jeep(pos.0, pos.1, alongX, tt, min(CollectScene.jeepSeats, boarded)) }))
            }
        }
        return items
    }

    /// Open-top safari jeep: khaki body, a coral stripe, roll bar, heading along gx or gy.
    mutating func jeep(_ gx: Double, _ gy: Double, _ alongX: Bool, _ tt: Double, _ passengers: Int) {
        let w = alongX ? 0.78 : 0.4, d = alongX ? 0.4 : 0.78, x0 = gx - w / 2, y0 = gy - d / 2
        let (A, B, C, D) = corners(x0, y0, w, d), shake = 1 + CGFloat(sin(tt * 20)) * 0.4
        let mid = lp(A, C, 0.5)
        blobShadow(mid.x + 10, mid.y + 6, 34, 9, 0.2)
        for (u, vv) in [(0.18, 0.0), (0.82, 0), (0.18, 1), (0.82, 1)] as [(CGFloat, CGFloat)] {
            let p = alongX ? lp(lp(D, C, u), lp(A, B, u), vv) : lp(lp(B, C, u), lp(A, D, u), vv)
            ellipse(p.x, p.y - 4, 5, 4, hex("#2a1e18"))
        }
        let keep = c
        c.translateBy(x: 0, y: -shake)
        let f = block(x0, y0, w, d, 16, lit: "#c9b27a", shade: "#8f7a48", top: "#5a4a30", courses: false)
        for (p, q) in [(f.D, f.C), (f.C, f.B)] {
            var fc = face(p, q, 16)
            fc.fill(Path(CGRect(x: 0, y: 0.55, width: 1, height: 0.14)), with: .color(hex("#ff5e3a")))
        }
        let cols = ["#ff5e3a", "#14a39a", "#ffc23d", "#9b7be0", "#5aa9e6", "#ff6fa8"]
        for i in 0..<passengers {
            let k = (CGFloat(i) + 0.5) / CGFloat(CollectScene.jeepSeats)
            let p = alongX ? lp(lp(f.d, f.c, k), lp(f.a, f.b, k), 0.5) : lp(lp(f.b, f.c, k), lp(f.a, f.d, k), 0.5)
            ellipse(p.x, p.y - 11, 3, 3, hex("#3a2418"))
            rect(p.x - 3, p.y - 8, 6, 7, hex(cols[i % 6]))
        }
        let r0 = alongX ? lp(f.d, f.a, 0.5) : lp(f.b, f.a, 0.5), r1 = alongX ? lp(f.c, f.b, 0.5) : lp(f.c, f.d, 0.5)
        var bar = Path()
        bar.move(to: r0); bar.addLine(to: upp(r0, 18)); bar.addLine(to: upp(r1, 18)); bar.addLine(to: r1)
        c.stroke(bar, with: .color(hex("#3a3028")), lineWidth: 2.5)
        c = keep
    }
}

extension TownPainter {
    /// Pilots on strike in front of your office, waving placards.
    func strikers() -> [TownItem] {
        let n = min(8, max(3, s.local.pilots.count)), signs = (0..<4).map { loc("strike.sign.\($0)") }, tt = t
        return (0..<n).map { i in
            let gx = 8.4 + Double(i % 4) * 0.55, gy = 13.6 + Double(i / 4) * 0.45
            return TownItem(depth: gx + gy, draw: { p in
                let q0 = TownGeo.iso(gx, gy), bob = CGFloat(abs(sin(tt * 4 + Double(i)))) * 4
                let keep = p.c
                p.c.translateBy(x: q0.x, y: q0.y)
                p.c.scaleBy(x: 1.5, y: 1.5)
                p.person(0, 0, "#2b5ab8", tt, Double(i))
                p.line(p.pt(4, -10), p.pt(4, -34 - bob), p.hex("#5a3a20"), 1.5)
                let card = CGRect(x: -10, y: -50 - bob, width: 28, height: 17)
                p.c.fill(Path(card), with: .color(p.hex("#fffaf3")))
                p.c.stroke(Path(card), with: .color(p.hex("#e5432f")), lineWidth: 1.5)
                p.c.draw(Text(signs[i % 4]).font(.custom("BarlowCondensed-ExtraBold", size: 9)).foregroundColor(p.hex("#e5432f")),
                         at: CGPoint(x: 4, y: -41.5 - bob), anchor: .center)
                p.c = keep
            })
        }
    }
}
