import SwiftUI
import BalloonBaronCore

/// A point on the town grid the full-screen town glides to when it opens.
struct TownFocus: Equatable {
    var gx: Double
    var gy: Double
}

/// Frame-to-frame state of a town canvas. Not observed: the canvas and the gestures mutate it.
final class TownCanvasModel {
    let t0 = Date.timeIntervalSinceReferenceDate
    var view = TownViewport(z: 0.3, ox: 0, oy: 0)
    var hits = TownHits()
    var placed = false
    /// Zone to glide to once the canvas knows its size.
    var pendingFocus: TownFocus?
    /// Pan and pinch in progress.
    var lastDrag: CGSize = .zero
    var pinchStart: (z: CGFloat, ox: CGFloat, oy: CGFloat)?
    /// Glide toward a zone: start time, start view, target zoom and grid point.
    var anim: (start: Double, from: TownViewport, z: CGFloat, at: TownFocus)?

    func time(_ date: Date) -> Double { date.timeIntervalSinceReferenceDate - t0 }

    /// Fit the town across the width (hotels on the left included); the valley fills the rest.
    func place(in size: CGSize) {
        guard !placed, size.width > 0 else { return }
        placed = true
        let z = min(max(size.width / 1450, 0.26), 0.9), c = TownGeo.iso(7, 8)
        view = TownViewport(z: z, ox: size.width / 2 - c.x * z, oy: size.height * 0.58 - c.y * z)
    }

    func focus(_ at: TownFocus, now: Double) {
        anim = (start: now, from: view, z: 0.65, at: at)
    }

    func step(now: Double, size: CGSize) {
        if let a = anim {
            let k = min(max((now - a.start) / 0.45, 0), 1), e = CGFloat(1 - pow(1 - k, 3))
            let c = TownGeo.iso(a.at.gx, a.at.gy)
            view.z = a.from.z + (a.z - a.from.z) * e
            view.ox = a.from.ox + (size.width / 2 - c.x * a.z - a.from.ox) * e
            view.oy = a.from.oy + (size.height * 0.55 - c.y * a.z - a.from.oy) * e
            if k >= 1 { anim = nil }
        }
        clamp(size)
    }

    /// Keep the town on screen however far you drag.
    func clamp(_ size: CGSize) {
        let w = size.width, h = size.height, c = TownGeo.iso(7.5, 7.5)
        let sx = c.x * view.z + view.ox, sy = c.y * view.z + view.oy
        let mx = 8 * TownGeo.TW / 2 * view.z, my = 8 * TownGeo.TH / 2 * view.z
        view.ox += min(max(sx, min(w * 0.5, -mx + w * 0.2)), max(w * 0.5, w * 0.8 + mx)) - sx
        view.oy += min(max(sy, min(h * 0.5, h * 0.3 - my)), max(h * 0.55, h * 0.8 + my)) - sy
    }

    func zoom(at p: CGPoint, to z: CGFloat, from start: (z: CGFloat, ox: CGFloat, oy: CGFloat)) {
        let nz = min(max(z, 0.25), 1.6), k = nz / start.z
        view = TownViewport(z: nz, ox: p.x - (p.x - start.ox) * k, oy: p.y - (p.y - start.oy) * k)
    }
}

/// Şirketim: the company town full screen. Drag to look around, pinch to zoom, tap a building to open it.
/// From afar the zones are written in the sand; tapping one glides in on it.
struct TownView: View {
    @Environment(GameStore.self) private var store
    @State private var model = TownCanvasModel()

    var body: some View {
        ZStack(alignment: .top) {
            if let s = store.state {
                TimelineView(.animation) { tl in
                    Canvas { ctx, sz in
                        let now = model.time(tl.date)
                        model.place(in: sz)
                        if let f = model.pendingFocus {
                            model.focus(f, now: now)
                            model.pendingFocus = nil
                        }
                        model.step(now: now, size: sz)
                        model.hits = TownPainter.render(&ctx, state: s, time: now, viewport: model.view, size: sz)
                    }
                }
                .ignoresSafeArea()
                .gesture(pan.simultaneously(with: pinch))
                .onTapGesture { p in tap(p) }
                .accessibilityHidden(true)
            }
            header
            VStack {
                Spacer()
                Text(loc("town.hint"))
                    .font(Theme.font(13))
                    .foregroundStyle(Color(red: 1, green: 240 / 255, blue: 225 / 255).opacity(0.85))
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .allowsHitTesting(false)
            }
        }
        .background(Color(hex: "#3a2a4a").ignoresSafeArea())
        .onAppear {
            model.pendingFocus = store.townFocus
            store.townFocus = nil
        }
    }

    private var header: some View {
        HStack {
            Text(loc("town.title"))
                .font(Theme.font(34, .heavy, condensed: true))
                .foregroundStyle(Color(hex: "#fff6ea"))
                .shadow(color: Color(red: 20 / 255, green: 12 / 255, blue: 40 / 255).opacity(0.55), radius: 8, y: 2)
            Spacer()
            Button {
                SoundEngine.shared.play(.click)
                store.closePage()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc("fleetPage.close"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var pan: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                model.anim = nil
                model.view.ox += v.translation.width - model.lastDrag.width
                model.view.oy += v.translation.height - model.lastDrag.height
                model.lastDrag = v.translation
            }
            .onEnded { _ in model.lastDrag = .zero }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                model.anim = nil
                let start = model.pinchStart ?? (z: model.view.z, ox: model.view.ox, oy: model.view.oy)
                if model.pinchStart == nil { model.pinchStart = start }
                model.zoom(at: v.startLocation, to: start.z * v.magnification, from: start)
            }
            .onEnded { _ in model.pinchStart = nil }
    }

    private func tap(_ p: CGPoint) {
        let hit = model.hits.hit(p)
        if let z = hit.zone {
            SoundEngine.shared.play(.click)
            model.focus(TownFocus(gx: z.at.0, gy: z.at.1), now: model.time(Date()))
        } else if let b = hit.building {
            SoundEngine.shared.play(.click)
            store.tapTown(b.tap)
        }
    }
}

/// The town on the home screen, sitting on the dock with its back corner under the weather card.
/// No panning here: a zone opens Şirketim zoomed on it, a building opens itself, open ground opens Şirketim.
struct HomeTownView: View {
    @Environment(GameStore.self) private var store
    /// Top of the dock and bottom of the weather card, in screen coordinates.
    let dockTop: CGFloat
    let weatherBottom: CGFloat
    let hudBottom: CGFloat
    @State private var model = TownCanvasModel()

    var body: some View {
        if let s = store.state {
            TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                Canvas { ctx, sz in
                    let h = dockTop > 0 ? min(dockTop, sz.height) : sz.height * 0.6
                    model.view = viewport(width: sz.width, dockTop: h)
                    var clipped = ctx
                    clipped.clip(to: Path(CGRect(x: 0, y: 0, width: sz.width, height: h)))
                    model.hits = TownPainter.render(&clipped, state: s, time: model.time(tl.date), viewport: model.view,
                                                    size: CGSize(width: sz.width, height: h))
                }
            }
            .ignoresSafeArea()
            .onTapGesture { p in tap(p) }
            .accessibilityElement()
            .accessibilityLabel(loc("town.title"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { store.openTown(nil) }
        }
    }

    private func viewport(width w: CGFloat, dockTop: CGFloat) -> TownViewport {
        let back = max(hudBottom + 20, weatherBottom - 16), front = dockTop - 6
        let z = min(max((front - back) / 1024, 0.15), w / 1500)
        let c = TownGeo.iso(7, 8)
        return TownViewport(z: z, ox: w / 2 - c.x * z, oy: front - TownGeo.iso(15.5, 15.5).y * z)
    }

    private func tap(_ p: CGPoint) {
        guard dockTop <= 0 || p.y < dockTop else { return }
        SoundEngine.shared.play(.click)
        let hit = model.hits.hit(p)
        if let z = hit.zone {
            store.openTown(TownFocus(gx: z.at.0, gy: z.at.1))
        } else if let b = hit.building {
            store.tapTown(b.tap)
        } else {
            store.openTown(nil)
        }
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
