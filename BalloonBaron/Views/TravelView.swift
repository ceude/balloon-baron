import SwiftUI
import BalloonBaronCore

/// Moving to another region (`showTravel`): a short flight across the world map, the company balloon gliding from
/// one city to the other on an arc (about 3 s). The region has already switched underneath; popups wait for it.
struct TravelView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let travel: GameStore.Travel
    @State private var start = Date()
    @State private var shown = false

    private static let duration = 3.0

    var body: some View {
        let colors = store.state?.colors ?? Rules.palettes[0]
        ZStack {
            LinearGradient(colors: [Color(hex: "#1b1840"), Color(hex: "#5a3a6e"), Color(hex: "#f0a070")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                (Text(travel.from.title) + Text("  →  ").foregroundColor(Theme.sun) + Text(travel.to.title))
                    .font(Theme.font(30, .heavy, condensed: true))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                TimelineView(.animation) { tl in
                    map(progress: progress(tl.date), colors: colors)
                }
                .aspectRatio(100 / 42.3, contentMode: .fit)
                .frame(maxWidth: 640)
                Text(loc("travel.sub", travel.to.title))
                    .font(Theme.font(15))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
        }
        .opacity(shown ? 1 : 0)
        .accessibilityElement(children: .combine)
        .task {
            start = Date()
            withAnimation(.easeOut(duration: 0.4)) { shown = true }
            try? await Task.sleep(for: .seconds(reduceMotion ? 1.2 : Self.duration + 0.35))
            withAnimation(.easeIn(duration: 0.4)) { shown = false }
            try? await Task.sleep(for: .seconds(0.45))
            store.travel = nil
            store.showNextHezarfen()
        }
    }

    private func progress(_ now: Date) -> Double {
        if reduceMotion { return 1 }
        let k = min(1, max(0, now.timeIntervalSince(start) / Self.duration))
        return k < 0.5 ? 2 * k * k : 1 - pow(-2 * k + 2, 2) / 2
    }

    private func point(_ r: RegionID, _ size: CGSize) -> CGPoint {
        let pin = MapPin(rawValue: r.rawValue)
        return CGPoint(x: CGFloat(((pin?.lon ?? 0) + 130) / 260) * size.width, y: CGFloat((70 - (pin?.lat ?? 0)) / 110) * size.height)
    }

    private func control(_ a: CGPoint, _ b: CGPoint, height: CGFloat) -> CGPoint {
        let x: CGFloat = (a.x + b.x) / 2
        let y: CGFloat = min(a.y, b.y) - height * 0.21
        return CGPoint(x: x, y: y)
    }

    /// The point at `k` (0…1) on the quadratic arc from `a` over `c` to `b`.
    private func bezier(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ k: CGFloat) -> CGPoint {
        let u: CGFloat = 1 - k
        let wa: CGFloat = u * u, wc: CGFloat = 2 * u * k, wb: CGFloat = k * k
        let x: CGFloat = wa * a.x + wc * c.x + wb * b.x
        let y: CGFloat = wa * a.y + wc * c.y + wb * b.y
        return CGPoint(x: x, y: y)
    }

    private func map(progress e: Double, colors: [String]) -> some View {
        GeometryReader { geo in
            let a = point(travel.from, geo.size), b = point(travel.to, geo.size)
            let mid = control(a, b, height: geo.size.height)
            let pos = bezier(a, mid, b, CGFloat(e))
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    let land = WorldOutline.path.applying(CGAffineTransform(scaleX: size.width / 100, y: size.height / 42.3))
                    ctx.fill(land, with: .color(Color.white.opacity(0.16)))
                    ctx.stroke(land, with: .color(Color.white.opacity(0.28)), style: StrokeStyle(lineWidth: 0.6, lineJoin: .round))
                    var arc = Path()
                    arc.move(to: a)
                    arc.addQuadCurve(to: b, control: mid)
                    ctx.stroke(arc, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 5]))
                    ctx.stroke(arc.trimmedPath(from: 0, to: CGFloat(e)), with: .color(Color(hex: "#ffd27a")), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    for p in [a, b] {
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 9, y: p.y - 9, width: 18, height: 18)), with: .color(Theme.sun.opacity(0.35)))
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)), with: .color(Theme.sun))
                        ctx.stroke(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)), with: .color(.white), lineWidth: 2)
                    }
                }
                ForEach([travel.from, travel.to], id: \.self) { r in
                    let p = point(r, geo.size)
                    Text(r.title)
                        .font(Theme.font(13, .heavy, condensed: true))
                        .foregroundStyle(.white)
                        .fixedSize()
                        .position(x: p.x, y: p.y + 16)
                }
                DesignBalloon(colors: colors)
                    .frame(width: 30, height: 38)
                    .rotationEffect(.degrees(sin(Date().timeIntervalSinceReferenceDate * 3.3) * 4), anchor: .bottom)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                    .position(x: pos.x, y: pos.y - 19)
            }
        }
        .background(LinearGradient(colors: [Color(hex: "#2a2156"), Color(hex: "#3d3070")], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.35), radius: 15, y: 10)
    }
}
