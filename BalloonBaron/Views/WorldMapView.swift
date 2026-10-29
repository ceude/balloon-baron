import SwiftUI
import BalloonBaronCore

/// The company's regions on a world map, with a card per region below it.
struct WorldMapView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            WorldPageHeader(title: loc("map.title")) { store.closePage() }
            ScrollView {
                if let game = store.game {
                    VStack(spacing: 14) {
                        worldMap(game.state)
                        ForEach(MapPin.allCases, id: \.self) { pin in
                            regionCard(pin, game)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Theme.paper.ignoresSafeArea())
    }

    // MARK: Map

    private func worldMap(_ s: GameState) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    let land = WorldOutline.path.applying(CGAffineTransform(scaleX: size.width / 100, y: size.height / 42.3))
                    ctx.fill(land, with: .color(Color.white.opacity(0.16)))
                    ctx.stroke(land, with: .color(Color.white.opacity(0.28)), style: StrokeStyle(lineWidth: 0.6, lineJoin: .round))
                }
                .accessibilityHidden(true)
                ForEach(MapPin.allCases, id: \.self) { pin in
                    pinView(pin, s, size: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(100 / 42.3, contentMode: .fit)
        .background(LinearGradient(colors: [Color(hex: "#2a2156"), Color(hex: "#3d3070")], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func pinView(_ pin: MapPin, _ s: GameState, size: CGSize) -> some View {
        let status = MapPinStatus(pin, s)
        let side = labelSide(pin)
        let x = (pin.lon + 130) / 260 * Double(size.width)
        let y = (70 - pin.lat) / 110 * Double(size.height)
        return Circle()
            .fill(status.dot)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .background(Circle().fill(status.dot.opacity(status.glows ? 0.35 : 0)).frame(width: 22, height: 22))
            .overlay(alignment: side.alignment) {
                pinLabel(pin, status, side)
                    .fixedSize()
                    .offset(side.offset)
            }
            .accessibilityElement(children: .combine)
            .position(x: CGFloat(x), y: CGFloat(y))
            .opacity(status == .soon ? 0.6 : 1)
    }

    private func pinLabel(_ pin: MapPin, _ status: MapPinStatus, _ side: LabelSide) -> some View {
        VStack(alignment: side.textAlignment, spacing: 0) {
            Text(pin.title)
                .font(Theme.font(13, .bold, condensed: true))
                .foregroundStyle(.white)
            if !pin.mystery {
                Text(status.pinText)
                    .font(Theme.font(10))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
        .multilineTextAlignment(side == .below ? .center : side == .left ? .trailing : .leading)
    }

    private enum LabelSide {
        case right, left, below

        var alignment: Alignment {
            switch self {
            case .right: .leading
            case .left: .trailing
            case .below: .top
            }
        }
        var offset: CGSize {
            switch self {
            case .right: CGSize(width: 18, height: 0)
            case .left: CGSize(width: -18, height: 0)
            case .below: CGSize(width: 0, height: 16)
            }
        }
        var textAlignment: HorizontalAlignment {
            switch self {
            case .right: .leading
            case .left: .trailing
            case .below: .center
            }
        }
    }

    private func labelSide(_ pin: MapPin) -> LabelSide {
        switch pin {
        case .cap, .abq, .mara: .right
        case .lux, .bri: .left
        case .asia: .below
        }
    }

    // MARK: Region cards

    private func regionCard(_ pin: MapPin, _ game: Game) -> some View {
        let s = game.state
        let status = MapPinStatus(pin, s)
        let r = pin.region
        return HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(pin.mystery ? loc("map.newRegion", pin.land) : loc("map.place", pin.title, pin.land))
                        .font(Theme.font(18, .heavy, condensed: true))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    WorldTag(text: status.tagText, kind: status.tagKind)
                    if let r, s.isBaron(r) {
                        WorldTag(text: loc("map.baron"), kind: .green)
                    }
                }
                Text(subtitle(pin, status, s))
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let r {
                actions(r, status, game)
            }
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
        .opacity(status == .soon || status == .locked ? 0.65 : 1)
    }

    private func subtitle(_ pin: MapPin, _ status: MapPinStatus, _ s: GameState) -> String {
        switch status {
        case .here:
            return loc("map.here.\(pin.rawValue)")
        case .auto, .problem:
            guard let r = pin.region, let auto = s.parked[r]?.auto else { return "" }
            let daily = auto.today != 0 ? auto.today : Int(auto.base.rounded())
            var text = loc("map.autoSub", eurH(daily))
            if let open = auto.issue { text += " " + loc("map.problemSub", open.kind.title) }
            return text
        case .open:
            let fee = eurH(pin.region?.entryFee ?? Holding.entryFee)
            let sub = pin == .lux || pin == .bri ? loc("map.openSub.\(pin.rawValue)", money(pin.region?.startCash ?? 0, in: pin.region ?? .cap), fee) : loc("map.openSub", fee)
            return pin.region.map(s.needsPack) == true ? sub + " " + loc("map.tourNote", storePrice(.worldTour)) : sub
        case .locked:
            return loc(pin == .lux || pin == .bri ? "map.lockedSub.\(pin.rawValue)" : "map.lockedSub")
        case .soon:
            return pin.mystery ? loc("map.mysterySub", pin.land) : loc("map.soonSub.\(pin.rawValue)")
        }
    }

    @ViewBuilder
    private func actions(_ r: RegionID, _ status: MapPinStatus, _ game: Game) -> some View {
        switch status {
        case .auto, .problem:
            VStack(spacing: 6) {
                if status == .problem {
                    WorldPillButton(title: loc("map.decide"), style: .coral) { store.issueRegion = r }
                }
                WorldPillButton(title: loc("map.go"), style: .light) { store.goTo(r) }
            }
            .fixedSize()
        case .open:
            if game.state.needsPack(r) {
                WorldPillButton(title: loc("map.openTour", storePrice(.worldTour))) { store.showTourOffer = true }
                    .fixedSize()
            } else {
                WorldPillButton(title: loc("map.enter", eurH(r.entryFee)), enabled: game.canEnterRegion(r)) { store.goTo(r) }
                    .fixedSize()
            }
        default:
            EmptyView()
        }
    }
}

/// Where a pin stands for the player.
private enum MapPinStatus: Equatable {
    case here, auto, problem, open, locked, soon

    init(_ pin: MapPin, _ s: GameState) {
        guard let r = pin.region, !pin.mystery else { self = .soon; return }
        if r == s.region {
            self = .here
        } else if let p = s.parked[r] {
            self = p.auto.issue != nil ? .problem : .auto
        } else if r != .cap && s.regionOpen(r) {
            self = .open
        } else {
            self = .locked
        }
    }

    var dot: Color {
        switch self {
        case .here, .auto, .problem: Theme.sun
        case .open: Theme.coral
        case .locked, .soon: Color(hex: "#9a8fb8")
        }
    }

    var glows: Bool { self != .locked && self != .soon }

    /// Second line of the pin label on the map.
    var pinText: String {
        switch self {
        case .here: loc("map.here")
        case .auto, .problem: loc("map.auto")
        case .open: loc("map.unlocked")
        case .locked, .soon: loc("map.soon")
        }
    }

    var tagText: String {
        switch self {
        case .here: loc("map.here")
        case .auto: loc("map.auto")
        case .problem: loc("map.problem")
        case .open: loc("map.unlocked")
        case .locked: loc("map.locked")
        case .soon: loc("map.soon")
        }
    }

    var tagKind: WorldTag.Kind {
        switch self {
        case .here: .green
        case .auto, .open: .yellow
        case .problem: .red
        case .locked, .soon: .neutral
        }
    }
}

/// Continents from the prototype, in a 100 × 42.3 box (longitude −130…130, latitude 70…−40).
enum WorldOutline {
    static let shapes: [String] = [
        "M-14.7 1.5 L-12.3 -0.0 L-4.3 -0.0 L0.7 -0.0 L5.8 -1.1 L13.4 -0.7 L19.3 -1.1 L21.2 2.6 L25.4 3.9 L28.8 7.0 L24.7 9.6 L23.1 10.7 L20.8 13.4 L18.8 14.9 L19.3 17.3 L18.4 15.8 L15.8 15.4 L12.8 16.5 L12.8 18.4 L14.6 20.0 L16.2 18.8 L16.5 20.8 L18.0 23.0 L19.7 23.5 L17.3 22.3 L14.6 21.1 L9.6 19.3 L7.6 18.0 L6.9 15.8 L5.0 14.2 L2.4 11.6 L2.4 8.5 L-0.4 5.7 L-3.9 3.9 L-8.4 4.2 L-10.8 5.0 L-13.4 3.5 Z",
        "M19.7 23.5 L22.3 22.3 L26.2 22.8 L30.1 25.0 L33.1 27.6 L36.6 29.2 L35.0 32.3 L34.2 35.3 L31.6 36.9 L29.6 39.9 L27.7 41.5 L25.8 43.0 L24.7 45.4 L23.4 46.9 L22.3 47.6 L21.5 46.1 L21.9 42.3 L22.7 38.4 L23.1 33.8 L20.8 32.3 L18.8 28.9 L19.3 26.9 L20.4 24.3 Z",
        "M28.8 3.9 L33.1 3.9 L41.6 -0.0 L42.2 -3.1 L36.6 -5.0 L26.9 -4.6 L23.1 -2.7 L28.8 -0.0 Z",
        "M46.1 13.1 L46.5 10.3 L49.2 10.0 L48.1 8.5 L50.8 7.3 L53.0 6.1 L53.5 5.0 L51.9 4.6 L53.9 2.6 L56.1 0.4 L59.6 -0.4 L61.9 -0.0 L65.4 1.1 L66.9 0.8 L73.1 0.4 L73.1 5.7 L69.2 8.8 L68.4 10.7 L65.4 11.2 L63.8 11.2 L61.2 11.2 L60.0 11.6 L58.9 12.7 L58.4 11.6 L57.3 10.7 L56.1 12.3 L56.1 11.2 L54.6 10.0 L53.0 10.0 L51.1 10.3 L50.0 11.9 L48.1 13.1 Z",
        "M73.1 0.4 L76.9 -1.1 L80.7 -1.1 L88.5 -2.7 L93.5 -1.5 L100.0 -0.4 L107.7 -0.4 L115.4 -0.0 L119.2 1.5 L118.4 3.1 L112.7 3.9 L110.4 7.3 L111.5 3.9 L104.6 4.2 L101.9 5.7 L104.3 7.7 L103.9 9.2 L100.8 10.3 L99.6 13.4 L98.5 12.7 L96.9 11.6 L96.5 14.9 L95.8 17.3 L92.4 18.8 L91.5 20.8 L92.0 22.8 L90.4 23.5 L89.6 26.5 L88.5 24.6 L87.7 23.5 L87.7 20.8 L86.1 20.4 L85.4 18.4 L83.8 18.4 L80.7 21.1 L79.6 23.9 L78.1 20.4 L77.7 18.8 L75.8 17.7 L73.8 17.3 L71.9 16.9 L71.6 17.7 L72.7 18.4 L69.9 20.4 L67.3 21.9 L66.5 21.1 L65.0 18.4 L63.4 16.2 L63.0 14.7 L63.8 13.1 L61.5 12.7 L60.4 12.3 L60.0 11.6 L61.2 11.2 L63.8 11.2 L65.4 11.2 L68.4 10.7 L69.2 8.8 L73.1 5.7 Z",
        "M43.5 18.8 L43.5 21.1 L45.4 23.9 L47.0 25.4 L49.2 25.0 L51.9 24.6 L53.5 25.4 L53.9 27.4 L54.6 29.2 L55.0 31.6 L54.6 33.8 L55.8 37.3 L56.9 39.9 L57.8 40.4 L60.0 39.9 L62.3 37.7 L63.4 35.3 L65.8 32.7 L65.4 30.7 L65.0 28.9 L66.5 26.9 L68.4 25.0 L69.7 22.8 L66.5 22.3 L65.0 20.8 L63.8 18.4 L62.7 15.8 L61.2 14.9 L57.8 14.7 L55.8 14.7 L53.9 12.7 L51.1 12.7 L47.6 13.1 L46.1 15.4 L44.2 16.5 Z",
        "M93.9 35.3 L93.9 39.9 L95.4 40.4 L97.6 39.7 L100.8 38.8 L103.0 40.4 L104.3 41.5 L106.5 41.5 L107.7 41.2 L108.8 37.7 L108.8 36.6 L106.2 34.2 L104.6 31.1 L104.3 33.5 L102.3 31.6 L100.0 31.6 L98.0 32.7 L96.9 33.8 Z",
        "M47.6 7.7 L50.4 7.3 L50.8 6.6 L49.2 5.4 L48.9 4.5 L47.6 4.6 L48.1 5.7 L48.9 6.1 L48.1 7.0 Z",
        "M100.0 14.9 L101.1 13.8 L103.9 13.4 L104.6 11.6 L104.3 9.6 L105.4 10.0 L103.9 12.3 L102.3 13.1 L100.4 13.8 Z",
        "M86.6 25.0 L87.7 25.4 L90.7 29.2 L89.2 28.5 Z",
        "M92.0 26.1 L95.0 24.3 L95.8 26.5 L94.6 28.5 L92.4 28.1 Z",
        "M100.4 27.4 L104.3 28.1 L107.7 30.7 L104.3 30.4 L101.5 28.5 Z",
        "M66.9 36.6 L68.1 36.6 L69.2 32.7 L68.8 31.6 L66.9 33.5 Z",
        "M116.2 40.4 L118.4 41.5 L116.9 42.7 L114.7 44.5 L115.8 43.8 Z"
    ]

    static let path: Path = {
        var p = Path()
        for shape in shapes {
            let tokens = shape.split(separator: " ")
            var i = 0
            while i < tokens.count {
                let tok = tokens[i]
                i += 1
                if tok == "Z" {
                    p.closeSubpath()
                    continue
                }
                guard let c = tok.first, c == "M" || c == "L", i < tokens.count,
                      let x = Double(tok.dropFirst()), let y = Double(tokens[i]) else { continue }
                i += 1
                let pt = CGPoint(x: x, y: y)
                if c == "M" { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
        return p
    }()
}
