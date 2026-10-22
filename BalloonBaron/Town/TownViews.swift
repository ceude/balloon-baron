import SwiftUI
import BalloonBaronCore

/// Frame-to-frame state of the home town canvas. Not observed: the canvas and the gestures mutate it.
final class TownCanvasModel {
    enum Mode { case home, zoomed, leaving }
    let t0 = Date.timeIntervalSinceReferenceDate
    var mode = Mode.home
    var view = TownViewport(z: 0.3, ox: 0, oy: 0)
    /// What the home screen shows; zooming starts from it and returns to it.
    var home = TownViewport(z: 0.3, ox: 0, oy: 0)
    var size: CGSize = .zero
    var hits = TownHits()
    /// Pan and pinch in progress.
    var lastDrag: CGSize = .zero
    var pinchStart: TownViewport?
    /// A glide: start time, start view and target view.
    var anim: (start: Double, from: TownViewport, to: TownViewport)?

    func time(_ date: Date) -> Double { date.timeIntervalSinceReferenceDate - t0 }
    var now: Double { time(Date()) }

    func glide(to target: TownViewport) {
        anim = (start: now, from: view, to: target)
    }

    /// Glide in on a grid point, at a zoom that shows building names.
    func focus(_ gx: Double, _ gy: Double) {
        let z: CGFloat = 0.65, c = TownGeo.iso(gx, gy)
        glide(to: TownViewport(z: z, ox: size.width / 2 - c.x * z, oy: size.height * 0.55 - c.y * z))
    }

    /// The grid point under a screen point, kept inside the walls.
    func grid(_ p: CGPoint) -> (Double, Double) {
        let wx = (p.x - view.ox) / view.z, wy = (p.y - view.oy) / view.z
        let a = Double(wx / (TownGeo.TW / 2)), b = Double(wy / (TownGeo.TH / 2))
        return (min(max((a + b) / 2, 0), 15), min(max((b - a) / 2, 0), 15))
    }

    func step(now: Double) {
        if let a = anim {
            let k = min(max((now - a.start) / 0.45, 0), 1), e = CGFloat(1 - pow(1 - k, 3))
            view.z = a.from.z + (a.to.z - a.from.z) * e
            view.ox = a.from.ox + (a.to.ox - a.from.ox) * e
            view.oy = a.from.oy + (a.to.oy - a.from.oy) * e
            if k >= 1 {
                anim = nil
                if mode == .leaving { mode = .home }
            }
        } else if mode == .zoomed {
            clamp()
        }
    }

    /// Keep the town on screen however far you drag.
    func clamp() {
        let w = size.width, h = size.height, c = TownGeo.iso(7.5, 7.5)
        let sx = c.x * view.z + view.ox, sy = c.y * view.z + view.oy
        let mx = 16 * TownGeo.TW / 2 * view.z, my = 8 * TownGeo.TH / 2 * view.z
        view.ox += min(max(sx, min(w * 0.5, w * 0.85 - mx)), max(w * 0.5, w * 0.15 + mx)) - sx
        view.oy += min(max(sy, min(h * 0.5, h * 0.3 - my)), max(h * 0.55, h * 0.8 + my)) - sy
    }
}

/// The company town on the home screen, sitting on the dock with its back corner under the weather card.
/// Tapping it zooms in right there: the home screen's controls slide away (`zoomed`), and you can drag and pinch.
/// Pinching back out to the home view, or the round X, glides back and the controls return.
/// A building opens itself; from afar a zone written in the sand glides in on that zone.
struct HomeTownView: View {
    @Environment(GameStore.self) private var store
    /// Top of the dock and bottom of the weather card, in screen coordinates.
    let dockTop: CGFloat
    let weatherBottom: CGFloat
    let hudBottom: CGFloat
    @Binding var zoomed: Bool
    @State private var model = TownCanvasModel()
    /// Where this view's own (safe-area) frame starts on screen. The canvas ignores the safe area and draws in
    /// screen coordinates, while tap and pinch locations arrive in the view's frame; adding this lines them up.
    @State private var origin: CGPoint = .zero

    var body: some View {
        if let s = store.state {
            ZStack(alignment: .topTrailing) {
                TimelineView(.animation(minimumInterval: zoomed ? nil : 1 / 30)) { tl in
                    Canvas { ctx, sz in
                        let h = dockTop > 0 ? min(dockTop, sz.height) : sz.height * 0.6
                        model.size = sz
                        model.home = homeViewport(width: sz.width, dockTop: h)
                        if model.mode == .home { model.view = model.home } else { model.step(now: model.time(tl.date)) }
                        // At home the town stops at the dock; zoomed in it fills the screen.
                        let now = model.time(tl.date)
                        var c = ctx
                        if store.collecting {
                            renderCollect(&c, s, sz, now)
                        } else {
                            store.collectScene.from = nil
                            // Zoomed in, the horizon stays where the home screen had it.
                            var v = model.view
                            if model.mode != .home { v.hzCap = TownGeo.horizon(model.home, height: sz.height) }
                            model.hits = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz)
                        }
                    }
                }
                .ignoresSafeArea()
                .gesture(pan, including: zoomed ? .all : .none)
                .simultaneousGesture(pinch, including: store.collecting ? .none : .all)
                .onTapGesture { p in tap(CGPoint(x: p.x + origin.x, y: p.y + origin.y)) }
                .background {
                    GeometryReader { g in
                        let o = g.frame(in: .global).origin
                        Color.clear
                            .onAppear { origin = o }
                            .onChange(of: o) { _, v in origin = v }
                    }
                }
                .accessibilityElement()
                .accessibilityLabel(loc("town.title"))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { zoomIn(at: (7, 8)) }
                if zoomed {
                    Button {
                        SoundEngine.shared.play(.click)
                        zoomOut()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 46, height: 46)
                            .background(Color(red: 1, green: 250 / 255, blue: 243 / 255).opacity(0.95), in: Circle())
                            .background(Circle().fill(Theme.ink.opacity(0.35)).offset(y: 4))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, max(6, hudBottom - origin.y + 8))
                    .padding(.trailing, 14)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .accessibilityLabel(loc("town.zoomOut"))
                }
            }
        }
    }

    /// The camera glides from what the home showed to your office in 0.8 s and stays there while the jeeps leave.
    private func renderCollect(_ c: inout GraphicsContext, _ s: GameState, _ sz: CGSize, _ now: Double) {
        let sc = store.collectScene
        if sc.leaveAt == nil, let d = sc.leaveDate { sc.leaveAt = model.time(d) }
        if sc.leaveDate == nil || sc.target == nil {
            sc.target = CollectScene.view(size: sz, top: hudBottom, bottom: sc.cardTop > 0 ? sc.cardTop : sz.height)
        }
        if sc.from == nil { sc.from = (now, model.view) }
        guard let to = sc.target, let from = sc.from else { return }
        let k = CGFloat(CollectScene.easeIO(min(max((now - from.t) / 0.8, 0), 1)))
        var v = TownViewport(z: from.view.z + (to.z - from.view.z) * k, ox: from.view.ox + (to.ox - from.view.ox) * k,
                             oy: from.view.oy + (to.oy - from.view.oy) * k)
        v.noLabels = true
        v.hzCap = TownGeo.horizon(model.home, height: sz.height)
        _ = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz, collect: sc)
    }

    private func homeViewport(width w: CGFloat, dockTop: CGFloat) -> TownViewport {
        let back = max(hudBottom + 20, weatherBottom - 16), front = dockTop - 6
        let z = min(max((front - back) / 1024, 0.15), w / 1500)
        let c = TownGeo.iso(7, 8)
        return TownViewport(z: z, ox: w / 2 - c.x * z, oy: front - TownGeo.iso(15.5, 15.5).y * z)
    }

    /// `instant`: a pinch that started on the home screen carries on zooming by itself.
    private func zoomIn(at g: (Double, Double), instant: Bool = false) {
        guard model.mode == .home else { return }
        model.view = model.home
        model.mode = .zoomed
        if !instant { model.focus(g.0, g.1) }
        withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.38)) { zoomed = true }
    }

    private func zoomOut() {
        guard model.mode == .zoomed else { return }
        model.mode = .leaving
        model.pinchStart = nil
        model.glide(to: model.home)
        withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.38)) { zoomed = false }
    }

    private func tap(_ p: CGPoint) {
        guard !store.collecting else { return }
        switch model.mode {
        case .leaving:
            return
        case .home:
            guard dockTop <= 0 || p.y < dockTop else { return }
            SoundEngine.shared.play(.click)
            let hit = model.hits.hit(p)
            if let z = hit.zone { zoomIn(at: z.at) } else if let b = hit.building { store.tapTown(b.tap) } else { zoomIn(at: model.grid(p)) }
        case .zoomed:
            let hit = model.hits.hit(p)
            if let z = hit.zone {
                SoundEngine.shared.play(.click)
                model.focus(z.at.0, z.at.1)
            } else if let b = hit.building {
                SoundEngine.shared.play(.click)
                store.tapTown(b.tap)
            }
        }
    }

    private var pan: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                guard model.mode == .zoomed else { return }
                model.anim = nil
                model.view.ox += v.translation.width - model.lastDrag.width
                model.view.oy += v.translation.height - model.lastDrag.height
                model.lastDrag = v.translation
            }
            .onEnded { _ in model.lastDrag = .zero }
    }

    /// Pinching out to the home screen's zoom returns home.
    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                // Two fingers on the home town zoom in right away, once they have opened a little.
                if model.mode == .home {
                    guard v.magnification > 1.04 else { return }
                    zoomIn(at: (7, 8), instant: true)
                }
                guard model.mode == .zoomed else { return }
                model.anim = nil
                let start = model.pinchStart ?? model.view
                if model.pinchStart == nil { model.pinchStart = start }
                let z = min(max(start.z * v.magnification, model.home.z), 1.6), k = z / start.z
                let p = CGPoint(x: v.startLocation.x + origin.x, y: v.startLocation.y + origin.y)
                model.view = TownViewport(z: z, ox: p.x - (p.x - start.ox) * k, oy: p.y - (p.y - start.oy) * k)
                if z <= model.home.z * 1.04 { zoomOut() }
            }
            .onEnded { _ in model.pinchStart = nil }
    }
}

/// The small card for the agencies and for buildings that open later (`townCard` in the prototype).
struct TownCardView: View {
    @Environment(GameStore.self) private var store
    let card: TownCard

    var body: some View {
        if let s = store.state {
            ModalCard {
                switch card {
                case .influencer:
                    let wait = s.local.influencerCooldown - s.day
                    CardText.title(loc("town.b.influencer"))
                    CardText.lead(wait > 0 ? loc("town.card.influWait", num(wait)) : loc("marketPage.influencerBody") + " " + loc("town.card.influCap"))
                    action(loc("town.card.influAction", eur(s.influencerCost)), disabled: wait > 0 || s.cash < s.influencerCost) {
                        store.act { _ = $0.runInfluencer() }
                    }
                case .guide:
                    let wait = s.local.guideCooldown - s.day
                    CardText.title(loc("town.b.guide"))
                    CardText.lead(wait > 0 ? loc("town.card.guideWait", num(wait)) : loc("marketPage.guideBody"))
                    action(loc("town.card.guideAction", eur(Rules.guideCost)), disabled: wait > 0 || s.cash < Rules.guideCost) {
                        store.act { _ = $0.runGuideFlight() }
                    }
                case .locked(let name, let day):
                    CardText.title(name)
                    CardText.lead(loc("town.card.locked", num(day)))
                }
                Button(loc("fleetPage.close")) { store.closeTownCard() }
                    .buttonStyle(ChunkyButtonStyle(kind: .ghost))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func action(_ title: String, disabled: Bool, run: @escaping () -> Void) -> some View {
        Button(title) {
            SoundEngine.shared.play(.coin)
            run()
            store.closeTownCard()
        }
        .buttonStyle(ChunkyButtonStyle(kind: .big))
        .disabled(disabled)
    }
}
