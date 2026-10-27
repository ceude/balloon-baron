import Metal
import QuartzCore
import SceneKit
import SwiftUI

/// Builds the film set in the background, once, as soon as a new company is on its way (the title screen), so the
/// film starts at once after it. Main thread.
final class OpeningLoader {
    static let shared = OpeningLoader()
    private(set) var world: OpeningWorld?
    private var building = false
    private var waiting: [(OpeningWorld) -> Void] = []

    /// SceneKit renders with Metal; without it the 2D setup plays.
    static let supported = MTLCreateSystemDefaultDevice() != nil

    func preload() {
        guard world == nil, !building, OpeningLoader.supported else { return }
        building = true
        // Phones with less memory get smaller shadows and no grain.
        let lite = ProcessInfo.processInfo.physicalMemory < 3_500_000_000
        DispatchQueue.global(qos: .userInitiated).async {
            let w = OpeningWorld(lite: lite)
            DispatchQueue.main.async {
                self.building = false
                self.world = w
                let ws = self.waiting
                self.waiting = []
                for f in ws { f(w) }
            }
        }
    }

    func whenReady(_ f: @escaping (OpeningWorld) -> Void) {
        if let world { f(world); return }
        waiting.append(f)
        preload()
    }

    /// The film is over: its geometry and textures go.
    func release() {
        world = nil
        waiting = []
    }
}

/// Calls back on every screen refresh (CADisplayLink needs an Objective-C target).
private final class FrameTicker: NSObject {
    private var link: CADisplayLink?
    private let tick: () -> Void

    init(_ tick: @escaping () -> Void) {
        self.tick = tick
        super.init()
        let l = CADisplayLink(target: self, selector: #selector(step))
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc private func step() { tick() }

    func stop() {
        link?.invalidate()
        link = nil
    }
}

/// The opening's flow (`startOpen` … `openBegin`): the flight, Hezarfen's line, the name card over the held last frame,
/// the colour pick in the sky, the lift-off with the company's name and Day 1, then the town.
@Observable
final class OpeningFlow {
    enum Stage { case loading, film, talk, name, pick, liftOff, done }

    private(set) var stage = Stage.loading
    /// The take on screen and its time, for the captions, the bars and the fade.
    private(set) var part = OpeningPart.a
    private(set) var t = 0.0
    /// The balloon chosen in the sky (an index into `PickBalloon.all`).
    var pick = 0
    private(set) var company = ""
    /// The 3D film couldn't start: the 2D setup takes over.
    private(set) var fallback = false
    /// The cream flash into the town (`#fade`).
    private(set) var cream = false
    private(set) var film: OpeningFilm?

    @ObservationIgnored weak var view: SCNView?
    @ObservationIgnored private var ticker: FrameTicker?
    @ObservationIgnored private var burning = false
    @ObservationIgnored var onFinish: () -> Void = {}

    var filmReady: Bool { stage != .loading }

    /// Waits for the film set; after six seconds without it the 2D setup plays instead.
    func load() {
        guard film == nil, !fallback else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            guard let self, self.stage == .loading, self.film == nil else { return }
            self.fallback = true
            self.stop()
        }
        OpeningLoader.shared.whenReady { [weak self] w in
            guard let self, self.stage == .loading, self.film == nil, !self.fallback else { return }
            self.film = OpeningFilm(world: w)
            self.ticker = FrameTicker { [weak self] in self?.tick() }
        }
    }

    /// The view is up and its shaders compiled: roll (once).
    func viewPrepared() {
        guard stage == .loading, film != nil, !fallback else { return }
        stage = .film
        film?.start(.a)
        SoundEngine.shared.filmMusic(.a)
    }

    private func tick() {
        guard let film else { return }
        let (p, tt) = film.clock()
        part = p
        t = tt
        switch stage {
        case .film:
            if p == .a && tt > 28.5 { talk() }
        case .liftOff:
            let burn = OpeningFilm.heroBurns(tt)
            if burn != burning {
                burning = burn
                SoundEngine.shared.burner(burn)
            }
            if tt > 12.5 { begin() }
        default:
            break
        }
    }

    /// "Geç": the flight jumps to Hezarfen; the lift-off to the town.
    func skip() {
        if stage == .film { talk() } else if stage == .liftOff { begin() }
    }

    /// `openTalk`: Hezarfen's one line over the flight's last frame, held; the music down to its bed.
    private func talk() {
        guard stage == .film else { return }
        stage = .talk
        film?.seek(29)
        SoundEngine.shared.filmMusic(.bed)
    }

    /// "Adını koyalım": the name card.
    func toName() {
        guard stage == .talk else { return }
        stage = .name
    }

    /// The pick card on or off: the camera turns up to the sky, or back down to the field.
    func setPicking(_ on: Bool) {
        guard stage == .name || stage == .pick else { return }
        stage = on ? .pick : .name
        let size = view?.bounds.size ?? .zero
        film?.setPick(on, aspect: size.height > 0 ? Double(size.width / size.height) : 0.46)
        if on { film?.select(pick) }
    }

    func choose(_ i: Int) {
        guard i != pick else { return }
        pick = i
        film?.select(i)
        SoundEngine.shared.play(.tick)
    }

    /// A tap on the film: one of the balloons in the sky?
    func tapped(_ pt: CGPoint) {
        guard stage == .pick, let film, let view, let i = film.pickTarget(at: pt, in: view) else { return }
        choose(i)
    }

    /// `openLiftOff`: the envelope fills in the company's colours on the field and goes up.
    func liftOff(company: String, colors: [String]) {
        guard stage == .pick || stage == .name, let film else { return }
        self.company = company
        stage = .liftOff
        film.setPick(false, aspect: 0.46)
        film.prepareHero(name: company.uppercased(with: Locale.current), colors: colors)
        film.start(.b)
        SoundEngine.shared.filmMusic(.b)
    }

    /// `openBegin`: the music fades, a cream flash, and the town.
    func begin() {
        guard stage == .liftOff else { return }
        stage = .done
        SoundEngine.shared.filmMusic(nil)
        SoundEngine.shared.burner(false)
        burning = false
        withAnimation(.easeInOut(duration: 0.45)) { cream = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) { [weak self] in
            guard let self else { return }
            self.stop()
            self.onFinish()
        }
    }

    /// Stops following the film's clock.
    func stop() {
        ticker?.stop()
        ticker = nil
    }

    deinit { ticker?.stop() }
}

/// The new-company screens: the 3D opening film, or the 2D setup when the film can't play (Reduce Motion, no Metal, or
/// the film set not ready in time).
struct OpeningGate: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flow = OpeningFlow()

    var body: some View {
        if reduceMotion || !OpeningLoader.supported || flow.fallback {
            SetupView()
        } else {
            OpeningView(flow: flow)
        }
    }
}

/// The opening film with its letterbox, captions, Hezarfen's line, the setup cards and "Geç".
struct OpeningView: View {
    @Environment(GameStore.self) private var store
    let flow: OpeningFlow
    @State private var talkShown = false

    private static let night = Color(hex: "#0b0818")

    var body: some View {
        ZStack {
            Self.night.ignoresSafeArea()
            if let film = flow.film {
                FilmSceneView(film: film, flow: flow)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            FilmTimeline(flow: flow)
            if flow.stage == .talk { talkCard }
            if flow.stage == .name || flow.stage == .pick { SetupView(opening: flow) }
            if flow.stage == .film || flow.stage == .liftOff { skipButton }
            // until the first frame of the film
            Self.night
                .opacity(flow.filmReady ? 0 : 1)
                .ignoresSafeArea()
                .allowsHitTesting(!flow.filmReady)
                .animation(.easeOut(duration: 0.6), value: flow.filmReady)
            Color(hex: "#fff6ea")
                .opacity(flow.cream ? 1 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            flow.onFinish = {
                store.finishOpening()
                OpeningLoader.shared.release()
            }
            flow.load()
        }
        .onDisappear {
            flow.stop()
            SoundEngine.shared.burner(false)
            if flow.stage != .done { SoundEngine.shared.filmMusic(nil) }
        }
    }

    /// `openSkip`: "Geç ›" at the top right.
    private var skipButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    SoundEngine.shared.play(.click)
                    flow.skip()
                } label: {
                    Text(loc("opening.skip"))
                        .font(Theme.font(14, .bold))
                        .foregroundStyle(Color(hex: "#fff6e6"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(red: 11 / 255, green: 8 / 255, blue: 24 / 255).opacity(0.55), in: Capsule())
                        .overlay(Capsule().stroke(Color(red: 1, green: 246 / 255, blue: 230 / 255).opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(loc("opening.skip.a11y"))
            }
            Spacer()
        }
        .padding(.top, 14)
        .padding(.trailing, 14)
    }

    /// `openTalk`: Hezarfen's one line, low on the screen, and the way to the name card.
    private var talkCard: some View {
        GeometryReader { g in
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    HezarfenAvatar(size: 40)
                    (Text(loc("hez.name") + ": ").font(Theme.font(13.5, .bold)).foregroundColor(Theme.ink)
                        + Text(loc("opening.hez")).font(Theme.font(13.5)).foregroundColor(Theme.ink2))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(red: 1, green: 250 / 255, blue: 243 / 255).opacity(0.96), in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.3), radius: 13, y: 10)
                BigButton(title: loc("opening.name")) { flow.toName() }
            }
            .frame(width: min(g.size.width * 0.92, 440))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, g.size.height * 0.09)
            .opacity(talkShown ? 1 : 0)
            .offset(y: talkShown ? 0 : 16)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { talkShown = true } }
    }
}

/// What follows the film's clock, redrawn every frame on its own: the letterbox, the captions and the fade to black.
private struct FilmTimeline: View {
    let flow: OpeningFlow

    var body: some View {
        ZStack {
            letterbox
            captions
            // the film's own fade to black at the end of the lift-off
            Color.black
                .opacity(flow.stage == .done ? 1 : (flow.part == .b ? oClamp((flow.t - 11.6) / 0.8, 0, 1) : 0))
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    /// The letterbox: 7% bars that open at the end of the lift-off.
    private var letterbox: some View {
        let on = !(flow.part == .b && flow.t > 11)
        return GeometryReader { g in
            VStack(spacing: 0) {
                Rectangle().fill(Color(hex: "#06040e")).frame(height: g.size.height * 0.07)
                    .scaleEffect(x: 1, y: on ? 1 : 0, anchor: .top)
                Spacer(minLength: 0)
                Rectangle().fill(Color(hex: "#06040e")).frame(height: g.size.height * 0.07)
                    .scaleEffect(x: 1, y: on ? 1 : 0, anchor: .bottom)
            }
            .animation(.easeInOut(duration: 0.8), value: on)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// `OPEN3D_CAPS`: a place and a line over the flight; the company's name and Day 1 over the lift-off.
    private var captions: some View {
        let list: [(Double, Double, String, String)] = flow.part == .a
            ? [(1, 5.5, loc("opening.cap1.title"), loc("opening.cap1.sub")), (9, 13.5, loc("opening.cap2.title"), loc("opening.cap2.sub")),
               (19.5, 24.5, loc("opening.cap3.title"), loc("opening.cap3.sub"))]
            : [(5.5, 12.2, flow.company.uppercased(with: Locale.current), loc("hud.day", num(1)))]
        let t = flow.t
        let c = flow.stage == .loading ? nil : list.first { t > $0.0 - 0.6 && t < $0.1 + 0.6 }
        let a = c.map { oClamp(min(t - $0.0, $0.1 - t) * 1.2 + 0.5, 0, 1) } ?? 0
        return GeometryReader { g in
            let big = min(52, max(30, g.size.width * 0.11)), small = min(21, max(15, g.size.width * 0.046))
            VStack(spacing: 4) {
                Text(c?.2 ?? " ")
                    .font(Theme.font(big, .heavy, condensed: true))
                    .tracking(big * 0.32)
                    .padding(.leading, big * 0.32)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(c?.3 ?? " ")
                    .font(.system(size: small, weight: .bold, design: .serif).italic())
                    .foregroundStyle(Color(hex: "#ffd27a"))
            }
            .foregroundStyle(Color(hex: "#fff6e6"))
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.55), radius: 9, y: 2)
            .padding(.horizontal, 12)
            .frame(width: g.size.width)
            .offset(y: g.size.height * 0.22)
            .opacity(a)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityHidden(a < 0.5)
    }
}

/// The SceneKit view the film plays in. A tap goes to the colour pick.
private struct FilmSceneView: UIViewRepresentable {
    let film: OpeningFilm
    let flow: OpeningFlow

    func makeCoordinator() -> Coordinator { Coordinator(flow: flow) }

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero, options: [SCNView.Option.preferredRenderingAPI.rawValue: NSNumber(value: SCNRenderingAPI.metal.rawValue)])
        v.backgroundColor = UIColor(red: 11 / 255, green: 8 / 255, blue: 24 / 255, alpha: 1)
        v.antialiasingMode = .multisampling4X
        v.preferredFramesPerSecond = 60
        v.rendersContinuously = true
        // The prototype caps the pixel ratio at 2: a 3× screen would more than double the fill for little gain.
        v.contentScaleFactor = min(2, UIScreen.main.scale)
        v.scene = film.world.scene
        v.pointOfView = film.world.cameraNode
        v.delegate = film
        v.isPlaying = true
        v.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(_:))))
        flow.view = v
        // Compile the shaders and upload the textures before the first frame, so the flight doesn't stutter as it starts
        // (`viewPrepared` starts the film once, whichever comes first).
        let flow = self.flow
        v.prepare([film.world.scene]) { _ in DispatchQueue.main.async { flow.viewPrepared() } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { flow.viewPrepared() }
        return v
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        uiView.isPlaying = false
        uiView.delegate = nil
        uiView.scene = nil
    }

    final class Coordinator: NSObject {
        let flow: OpeningFlow
        init(flow: OpeningFlow) { self.flow = flow }

        @objc func tap(_ g: UITapGestureRecognizer) {
            guard let v = g.view else { return }
            flow.tapped(g.location(in: v))
        }
    }
}
