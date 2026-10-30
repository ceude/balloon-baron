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
    /// A glide: start time, start view, target view, length, easing, and what runs when it arrives.
    var anim: (start: Double, from: TownViewport, to: TownViewport, dur: Double, inOut: Bool, done: (() -> Void)?)?
    /// The view came from the night (the morning keeps the night's camera): it clamps and sets its horizon like the night.
    var night = false
    /// Gliding home from the night's camera: its horizon at the start, and how far the glide has come (0 … 1).
    var hzFrom: CGFloat?
    var glided: CGFloat = 0
    /// Reduce Motion: glides cut straight to where they're going.
    var instant = false
    /// v125: the region's contract place (town grid point): dragging can bring it to the middle of the screen.
    var contractSpot: (Double, Double)?
    /// v125: the first offer's scene: its camera glide (start time and view, target), and the view it last showed.
    var cine: (t0: Double, from: TownViewport, card: Bool)?
    var cineView: TownViewport?

    func time(_ date: Date) -> Double { date.timeIntervalSinceReferenceDate - t0 }
    var now: Double { time(Date()) }

    /// `inOut` eases in as well as out (a glide that starts from rest and leads into another); `done` runs on the
    /// main queue once the view arrives.
    func glide(to target: TownViewport, dur: Double = 0.45, inOut: Bool = false, done: (() -> Void)? = nil) {
        anim = (start: now, from: view, to: target, dur: instant ? 0.001 : dur, inOut: inOut, done: done)
    }

    /// Glide in on a grid point, at a zoom that shows building names.
    func focus(_ gx: Double, _ gy: Double, dur: Double = 0.45, inOut: Bool = false, done: (() -> Void)? = nil) {
        let z: CGFloat = 0.65, c = TownGeo.iso(gx, gy)
        glide(to: TownViewport(z: z, ox: size.width / 2 - c.x * z, oy: size.height * 0.55 - c.y * z), dur: dur, inOut: inOut, done: done)
    }

    /// The grid point under a screen point, kept inside the walls.
    func grid(_ p: CGPoint) -> (Double, Double) {
        let wx = (p.x - view.ox) / view.z, wy = (p.y - view.oy) / view.z
        let a = Double(wx / (TownGeo.TW / 2)), b = Double(wy / (TownGeo.TH / 2))
        return (min(max((a + b) / 2, 0), 15), min(max((b - a) / 2, 0), 15))
    }

    func step(now: Double) {
        if let a = anim {
            let k = min(max((now - a.start) / a.dur, 0), 1)
            let e = CGFloat(a.inOut ? (k < 0.5 ? 4 * k * k * k : 1 - pow(-2 * k + 2, 3) / 2) : 1 - pow(1 - k, 3))
            view.z = a.from.z + (a.to.z - a.from.z) * e
            view.ox = a.from.ox + (a.to.ox - a.from.ox) * e
            view.oy = a.from.oy + (a.to.oy - a.from.oy) * e
            glided = e
            if k >= 1 {
                anim = nil
                if mode == .leaving { mode = .home; night = false; hzFrom = nil }
                if let done = a.done { DispatchQueue.main.async(execute: done) }
            }
        } else if mode == .zoomed {
            if night { NightCamera.clamp(&view, size) } else { clamp() }
        }
    }

    /// Keep the town on screen however far you drag.
    func clamp() {
        let w = size.width, h = size.height, c = TownGeo.iso(7.5, 7.5)
        let sx = c.x * view.z + view.ox, sy = c.y * view.z + view.oy
        let mx = 16 * TownGeo.TW / 2 * view.z, my = 8 * TownGeo.TH / 2 * view.z
        // The home screen's own framing is always allowed, so dragging from it never jumps.
        let hx = c.x * home.z + home.ox, hy = c.y * home.z + home.oy
        var x0 = min(w * 0.5, w * 0.85 - mx, hx), x1 = max(w * 0.5, w * 0.15 + mx, hx)
        var y0 = min(h * 0.5, h * 0.3 - my, hy), y1 = max(h * 0.55, h * 0.8 + my, hy)
        // v125.5: the contract place outside town can be dragged to the middle of the screen and round it, any direction
        if let sp = contractSpot {
            let p = TownGeo.iso(sp.0, sp.1), ex = w / 2 + (c.x - p.x) * view.z, ey = h * 0.5 + (c.y - p.y) * view.z
            x0 = min(x0, ex - 0.3 * w); x1 = max(x1, ex + 0.3 * w)
            y0 = min(y0, ey - 0.25 * h); y1 = max(y1, ey + 0.25 * h)
        }
        view.ox += min(max(sx, x0), x1) - sx
        view.oy += min(max(sy, y0), y1) - sy
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
    /// The morning after the night: the town keeps the night's camera and the home screen's controls stay over it
    /// (`zoomed` stays false) until you zoom in.
    @State private var hold = false
    /// Gliding into the holding tower: the X hides and the town ignores touches until the office opens.
    @State private var diving = false
    /// The town has been fully covered for a moment (after the page, night or cover finished coming in).
    @State private var asleep = false
    /// Where this view's own (safe-area) frame starts on screen. The canvas ignores the safe area and draws in
    /// screen coordinates, while tap and pinch locations arrive in the view's frame; adding this lines them up.
    @State private var origin: CGPoint = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let s = store.state {
            ZStack(alignment: .topTrailing) {
                // Full frame rate whenever the camera moves. While something opaque covers the town it isn't drawn
                // at all; that starts only once the cover has fully come in, and ends the moment it starts to go.
                // Everything in the town runs on the clock, so it carries on from the right moment.
                TimelineView(.animation(minimumInterval: moving ? nil : 1 / 30, paused: asleep)) { tl in
                    Canvas { ctx, sz in
                        let h = dockTop > 0 ? min(dockTop, sz.height) : sz.height * 0.6
                        model.size = sz
                        model.instant = reduceMotion
                        model.contractSpot = Self.contractSpot(s)
                        model.home = homeViewport(width: sz.width, dockTop: h)
                        if model.mode == .home { model.view = model.home } else { model.step(now: model.time(tl.date)) }
                        // At home the town stops at the dock; zoomed in it fills the screen.
                        let now = model.time(tl.date)
                        var c = ctx
                        if store.contractScene != nil {
                            renderContractScene(&c, s, sz, now)
                        } else if let hi = store.homeIntro {
                            // v121.5: the opening film's landing, pulling back to the home view as the night lifts
                            let v = hi.viewport(home: model.home, size: sz, now: tl.date), n = hi.night(tl.date)
                            let night = n.k > 0.001 || n.sunrise > 0.001
                                ? TownNight(k: n.k, event: nil, t0: now, sunrise: n.sunrise, fieldShown: true) : nil
                            _ = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz, night: night)
                        } else if store.collecting && store.collectAnimation {
                            renderCollect(&c, s, sz, now)
                        } else if let e = store.morningEvent {
                            renderEvent(&c, s, sz, now, spot: e.townSpot, strike: e == .strike)
                        } else if store.issueScene {
                            // The office sits in the top third, above the decision card that comes up low.
                            renderEvent(&c, s, sz, now, spot: MorningEvent.strike.townSpot, strike: s.local.openIssue?.kind == .raise, focusY: 0.3)
                        } else if model.mode == .home, let f = store.homeFocus, let b = Town.buildings(s).first(where: { $0.id == f.id }) {
                            store.collectScene.from = nil
                            renderFocus(&c, s, sz, now, f, b, date: tl.date)
                        } else {
                            renderHome(&c, s, sz, now)
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(store.homeIntro == nil)
                .gesture(pan)
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
                // The buildings are only drawn; VoiceOver lists them as actions that open what a tap opens.
                .accessibilityActions {
                    if !store.collecting && store.morningEvent == nil {
                        ForEach(Town.buildings(s), id: \.id) { b in
                            Button(b.name) { store.tapTown(b.tap) }
                        }
                    }
                }
                .onChange(of: store.hqDive) { _, dive in if dive { diveIntoTower() } }
                .onChange(of: covered) { _, c in
                    if c { SoundEngine.shared.contractHum(0, level: 0) }
                    if c { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { if covered { asleep = true } } } else { asleep = false }
                }
                .onChange(of: store.night) { old, new in if old != nil, new == nil { startMorning() } }
                .onChange(of: store.collecting) { _, on in if on { collectFromHere(); SoundEngine.shared.contractHum(0, level: 0) } }
                .onChange(of: store.contractScene == nil) { _, ended in if ended { endContractScene() } }
                .onDisappear { SoundEngine.shared.contractHum(0, level: 0) }
                .onChange(of: store.page) { old, new in
                    // Leaving the office, the camera steps back out in front of the tower (`closeHQ`).
                    if old == .holding, new == nil, model.mode == .zoomed { model.focus(Self.tower.0, Self.tower.1) }
                }
                if zoomed && !diving {
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

    /// The town as the home screen and the zoomed view show it.
    /// Zoomed in, the horizon stays where the home screen had it; from the night it stays the night's, and gliding home
    /// it slides down to the home screen's. Pilots asking for a raise wait outside the office until you answer.
    private func renderHome(_ c: inout GraphicsContext, _ s: GameState, _ sz: CGSize, _ now: Double) {
        store.collectScene.from = nil
        var v = model.view
        if model.mode != .home {
            let homeHz = TownGeo.horizon(model.home, height: sz.height)
            if let f = model.hzFrom { v.hzFix = f + (homeHz - f) * model.glided }
            else if model.night { v.hzFix = NightCamera.horizon(v, sz) }
            else { v.hzCap = homeHz }
        }
        model.hits = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz, strike: s.local.openIssue?.kind == .raise)
        contractTick(s, v, sz, now)
    }

    private static func contractSpot(_ s: GameState) -> (Double, Double)? {
        guard s.contractConfig != nil, let p = ContractPlace.of(s.region) else { return nil }
        return p.center
    }

    /// v125 `ctrScene`: the camera leaves town for the off-map place (3.6 s, zoom 0.86, the place in the middle); when
    /// the card opens it moves the place to the top fifth of the screen (0.9 s).
    private func renderContractScene(_ c: inout GraphicsContext, _ s: GameState, _ sz: CGSize, _ now: Double) {
        guard let P = ContractPlace.of(s.region) else { return }
        let T = ContractTown.shared
        let card = store.contractCard != nil
        if model.cine == nil {
            model.cine = (now, model.mode == .home ? model.home : model.view, false)
            T.cineArrive = now + 1.6
        }
        if let ci = model.cine, ci.card != card, let cur = model.cineView { model.cine = (now, cur, card) }
        guard let ci = model.cine else { return }
        let z: CGFloat = 0.86, p = TownGeo.iso(P.center.0, P.center.1)
        let to = TownViewport(z: z, ox: sz.width / 2 - p.x * z, oy: sz.height * (card ? 0.2 : 0.5) - p.y * z)
        let dur = card ? 0.9 : 3.6
        let k = reduceMotion ? 1 : CGFloat(ContractGeo.easeIO3(min(max((now - ci.t0) / dur, 0), 1)))
        var v = TownViewport(z: ci.from.z + (to.z - ci.from.z) * k, ox: ci.from.ox + (to.ox - ci.from.ox) * k, oy: ci.from.oy + (to.oy - ci.from.oy) * k)
        v.noLabels = true
        v.hzCap = TownGeo.horizon(model.home, height: sz.height)
        model.cineView = v
        _ = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz)
        contractTick(s, v, sz, now)
    }

    /// The scene is over: the camera glides back home from where it was.
    private func endContractScene() {
        model.cine = nil
        guard let v = model.cineView else { return }
        model.cineView = nil
        model.view = v
        model.mode = .leaving
        model.glide(to: model.home, dur: 0.8, inOut: true)
    }

    /// v125 `ctrHumTick`: near the screen's middle the job's vehicle pulls in (the first time you look on its first day),
    /// a finished job's vehicle leaves, and the place's ambient sound follows how close it is.
    private func contractTick(_ s: GameState, _ v: TownViewport, _ sz: CGSize, _ now: Double) {
        guard let K = s.contractConfig, let P = ContractPlace.of(s.region) else { return }
        let T = ContractTown.shared, kind = K.kind == .bus ? 0 : K.kind == .ship ? 1 : 2
        let p = v.screen(TownGeo.iso(P.center.0, P.center.1))
        let d = hypot(p.x - sz.width / 2, p.y - sz.height / 2) / max(sz.width, sz.height)
        if let dp = s.local.contracts?.depart {
            if let t1 = T.departT, now - t1 > 9 {
                if !T.pending {
                    T.pending = true
                    DispatchQueue.main.async {
                        store.act { $0.clearContractDepart() }
                        T.departT = nil
                        T.pending = false
                    }
                }
            } else if T.departT == nil && s.day >= dp.from && d < 0.42 {
                T.departT = now
                DispatchQueue.main.async { SoundEngine.shared.contractArrive(kind, leaving: true) }
            }
        }
        if let due = s.contractDue, d < 0.42, !T.pending {
            T.pending = true
            T.arriveT[due.id] = now
            T.departT = nil
            DispatchQueue.main.async {
                SoundEngine.shared.contractArrive(kind)
                store.act { $0.markContractArrived() }
                T.pending = false
            }
        }
        let on = !ContractGeo.vehicles(s, now).isEmpty
        let level = on ? min(max(1.2 - Double(d) * 2.2, 0), 1) * min(max(Double(v.z) / 0.6, 0.3), 1) : 0
        DispatchQueue.main.async { SoundEngine.shared.contractHum(kind, level: level) }
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
        let k = reduceMotion ? 1 : CGFloat(CollectScene.easeIO(min(max((now - from.t) / 0.8, 0), 1)))
        var v = TownViewport(z: from.view.z + (to.z - from.view.z) * k, ox: from.view.ox + (to.ox - from.view.ox) * k,
                             oy: from.view.oy + (to.oy - from.view.oy) * k)
        v.noLabels = true
        if let f = sc.hzFix { v.hzFix = f } else { v.hzCap = TownGeo.horizon(model.home, height: sz.height) }
        _ = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz, collect: sc)
    }

    /// A morning event: the camera goes to where it happens, the names hide, and the card comes up from below.
    private func renderEvent(_ c: inout GraphicsContext, _ s: GameState, _ sz: CGSize, _ now: Double, spot: (Double, Double), strike: Bool,
                             focusY: CGFloat = 0.55) {
        let sc = store.collectScene
        if sc.from == nil { sc.from = (now, model.view) }
        guard let from = sc.from else { return }
        let z: CGFloat = 1.15, p = TownGeo.iso(spot.0, spot.1 + 1.2)
        let to = TownViewport(z: z, ox: sz.width / 2 - p.x * z, oy: sz.height * focusY - p.y * z)
        let k = reduceMotion ? 1 : CGFloat(CollectScene.easeIO(min(max((now - from.t) / 0.65, 0), 1)))
        var v = TownViewport(z: from.view.z + (to.z - from.view.z) * k, ox: from.view.ox + (to.ox - from.view.ox) * k,
                             oy: from.view.oy + (to.oy - from.view.oy) * k)
        v.noLabels = true
        if model.night { v.hzFix = NightCamera.horizon(v, sz) } else { v.hzCap = TownGeo.horizon(model.home, height: sz.height) }
        _ = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz, strike: strike)
    }

    /// v122: a guided action glides the home view to the building that just opened (`HOMEF`): it comes closer and to
    /// the middle in 0.9 s, pulses with a gold ring, and glides back in 0.7 s once its card or page opens.
    private func renderFocus(_ c: inout GraphicsContext, _ s: GameState, _ sz: CGSize, _ now: Double, _ f: HomeFocus, _ b: TownBuilding, date: Date) {
        func ease(_ t: Double) -> CGFloat {
            let t = min(max(t, 0), 1)
            return CGFloat(t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2)
        }
        let e: CGFloat = reduceMotion ? (f.out == nil ? 1 : 0)
            : f.out.map { 1 - ease(date.timeIntervalSince($0) / 0.7) } ?? ease(date.timeIntervalSince(f.t0) / 0.9)
        let H = model.home, cp = TownGeo.iso(b.gx + b.w / 2, b.gy + b.d / 2), top = CGFloat(Town.labelTop(b)) * 0.8
        let zf = max(H.z, min(0.62, H.z * 2.4)), z = exp(log(H.z) + (log(zf) - log(H.z)) * e)
        let hx = cp.x * H.z + H.ox, hy = cp.y * H.z + H.oy
        let px = hx + (sz.width / 2 - hx) * e, py = hy + (sz.height * 0.52 - hy) * e
        var v = TownViewport(z: z, ox: px - cp.x * z, oy: py - cp.y * z)
        v.hzCap = TownGeo.horizon(H, height: sz.height)
        model.hits = TownPainter.render(&c, state: s, time: now, viewport: v, size: sz)
        let rx = CGFloat(max(b.w, b.d)) * TownGeo.TW * 0.42 * z + 12, my = py - top * z * 0.45, r = max(rx, top * z * 0.6 + 10)
        store.focusBox.pos = CGRect(x: px - r, y: my - r, width: r * 2, height: r * 2)
        if e > 0.9 {
            let k = CGFloat(now * 1.3).truncatingRemainder(dividingBy: 1)
            let w = rx * (1 + k * 0.4)
            c.stroke(Path(ellipseIn: CGRect(x: px - w, y: py - w * 0.5, width: w * 2, height: w)),
                     with: .color(Color(red: 1, green: 210 / 255, blue: 122 / 255).opacity(Double(1 - k))), lineWidth: 4)
        }
    }

    private func homeViewport(width w: CGFloat, dockTop: CGFloat) -> TownViewport {
        let back = max(hudBottom + 20, weatherBottom - 16), front = dockTop - 6
        let z = min(max((front - back) / 1024, 0.15), w / 1500)
        let c = TownGeo.iso(7.5, 7.5) // v121.6: the town's middle on the screen's middle
        return TownViewport(z: z, ox: w / 2 - c.x * z, oy: front - TownGeo.iso(15.5, 15.5).y * z)
    }

    /// `morningTown`: zoomed or not, dragged left or right, the town stays where the night's camera was and the
    /// day's controls and cards come in over it. Dragging or zooming out keeps them; zooming in ends the hold.
    private func startMorning() {
        guard let v = store.morningCamera else { return }
        store.morningCamera = nil
        // A new day starts from the home screen (`hideAll`), or from the night's camera when it was closer.
        model.anim = nil
        model.hzFrom = nil
        if zoomed { zoomed = false }
        guard v.z > model.home.z * 1.04 else {
            model.mode = .home
            model.night = false
            hold = false
            return
        }
        model.view = v
        model.mode = .zoomed
        model.night = true
        hold = true
    }

    /// `endHold`: from here on the controls slide away as usual.
    private func endHold() {
        guard hold else { return }
        hold = false
        withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.38)) { zoomed = true }
    }

    /// Collecting passengers from a zoomed-in town: the camera glides on from where it is (with its horizon),
    /// and afterwards the home screen's view is back.
    private func collectFromHere() {
        guard model.mode != .home else { return }
        let sc = store.collectScene
        sc.from = (model.now, model.view)
        sc.hzFix = model.night ? NightCamera.horizon(model.view, model.size) : nil
        model.mode = .home
        model.anim = nil
        model.night = false
        model.hzFrom = nil
        hold = false
        if zoomed { zoomed = false }
    }

    /// The holding tower (`HQ_TOWER`).
    private static let tower = (10.0, 2.0)

    /// `openHQ`: glide to the tower (from the home screen), dive into it, then open the office floor.
    /// Two smooth stages, one after the other: glide to the tower, then dive into it; the office opens on arrival.
    private func diveIntoTower() {
        store.hqDive = false
        // Reduce Motion: no flight into the tower, the office just opens.
        guard model.mode != .leaving, !reduceMotion else { store.page = .holding; return }
        diving = true
        let dive = {
            let z: CGFloat = 1.5, c = TownGeo.iso(Self.tower.0, Self.tower.1), sz = model.size
            model.glide(to: TownViewport(z: z, ox: sz.width / 2 - c.x * z, oy: sz.height * 0.62 - (c.y - 160) * z), dur: 0.5, inOut: true) {
                diving = false
                store.page = .holding
            }
        }
        if model.mode == .home {
            model.view = model.home
            model.mode = .zoomed
            withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.38)) { zoomed = true }
            model.focus(Self.tower.0, Self.tower.1, dur: 0.5, inOut: true, done: dive)
        } else {
            endHold()
            dive()
        }
    }

    /// Something opaque is over the town: a page, the night, the flight or the day's report.
    private var covered: Bool {
        store.page != nil || store.night != nil || store.flightPax != nil || store.report != nil || store.showIntro
            || (store.replayingOpening && store.homeIntro == nil)
    }

    /// The camera is (or may be) moving: zoomed in, gliding, collecting, a morning event, the morning's hold.
    private var moving: Bool {
        zoomed || hold || diving || model.mode != .home || store.collecting || store.morningEvent != nil || store.homeIntro != nil
            || store.homeFocus != nil || store.contractScene != nil
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
        hold = false
        if model.night { model.hzFrom = NightCamera.horizon(model.view, model.size); model.glided = 0 }
        model.mode = .leaving
        model.pinchStart = nil
        model.glide(to: model.home)
        withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.38)) { zoomed = false }
    }

    private func tap(_ p: CGPoint) {
        guard !store.collecting, !diving, store.contractScene == nil else { return }
        switch model.mode {
        case .leaving:
            return
        case .home:
            guard dockTop <= 0 || p.y < dockTop else { return }
            // v122: while it glides to a building for a guided action, only that building takes a tap
            if store.homeFocus?.active == true { store.homeFocusTap(p); return }
            SoundEngine.shared.play(.click)
            let hit = model.hits.hit(p)
            if let z = hit.zone { zoomIn(at: z.at) } else if let b = hit.building { store.tapTown(b.tap) } else { zoomIn(at: model.grid(p)) }
        case .zoomed:
            let hit = model.hits.hit(p)
            if let z = hit.zone {
                SoundEngine.shared.play(.click)
                endHold()
                model.focus(z.at.0, z.at.1)
            } else if model.hits.contract.count > 2, TownGeo.inPoly(p, model.hits.contract) {
                // v125: the contract place: what's booked
                SoundEngine.shared.play(.click)
                store.contractCard = .status
            } else if let b = hit.building {
                SoundEngine.shared.play(.click)
                store.tapTown(b.tap)
            } else if model.hits.onField(p), store.state?.unlocked.contains(.fleet) == true {
                SoundEngine.shared.play(.click)
                store.tapTown(.page(.fleet, section: nil))
            }
        }
    }

    private var pan: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                guard !diving, !store.collecting, store.morningEvent == nil, store.contractScene == nil else { return }
                // One finger on the home town drags it at the home screen's size, the controls staying over it
                // (like the morning's hold); zooming out comes back home, zooming in zooms as usual.
                if model.mode == .home {
                    model.anim = nil
                    model.view = model.home
                    model.mode = .zoomed
                    model.night = false
                    model.hzFrom = nil
                    hold = true
                }
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
                guard !diving else { return }
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
                if z > start.z * 1.001 { endHold() }
                let p = CGPoint(x: v.startLocation.x + origin.x, y: v.startLocation.y + origin.y)
                model.view = TownViewport(z: z, ox: p.x - (p.x - start.ox) * k, oy: p.y - (p.y - start.oy) * k)
                // Closing in on the home screen's size returns home (even already there, after a drag).
                if z <= model.home.z * 1.04 && v.magnification < 1 { zoomOut() }
            }
            .onEnded { _ in model.pinchStart = nil }
    }
}

/// The small card for the agencies and for buildings that open later (`townCard` in the prototype).
struct TownCardView: View {
    @Environment(GameStore.self) private var store
    let card: TownCard

    var body: some View {
        if store.state != nil {
            ModalCard(onClose: { store.closeTownCard() }) {
                // v122: the guide office and the agency open their own screens (`GuideOfficeView`, `AgencyView`)
                switch card {
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
}
