import SwiftUI
import BalloonBaronCore

// Popups of the morning, ported from prototype v77–v85: the rival bosses, the paper, morning events,
// the rescue plan, postcards and the album.

// MARK: Rival bosses

/// A shape of a portrait drawn from SVG path data (100×100 viewBox).
struct ArtItem {
    var path: Path
    var fill: Color?
    var stroke: Color?
    var width: CGFloat = 1

    static func fill(_ d: String, _ hex: String) -> ArtItem { ArtItem(path: HezarfenAvatar.svgPath(d), fill: Color(hex: hex)) }
    static func line(_ d: String, _ hex: String, _ w: CGFloat) -> ArtItem { ArtItem(path: HezarfenAvatar.svgPath(d), stroke: Color(hex: hex), width: w) }
    static func dot(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ hex: String) -> ArtItem {
        ArtItem(path: Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), fill: Color(hex: hex))
    }
    static func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ hex: String) -> ArtItem {
        ArtItem(path: Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)), fill: Color(hex: hex))
    }
    static func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, _ hex: String) -> ArtItem {
        ArtItem(path: Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r), fill: Color(hex: hex))
    }

    func draw(in ctx: inout GraphicsContext) {
        if let fill { ctx.fill(path, with: .color(fill)) }
        if let stroke { ctx.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)) }
    }
}

/// The region's rival boss: Kenan Arslan (Göreme Sky), Dale Whitaker (Sandia Sky Rides) or Nabil Haddad (Theban Skies).
/// Port of `BOSS_AV`.
struct BossAvatar: View {
    let region: RegionID
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let k = sz.width / 100
            ctx.scaleBy(x: k, y: k)
            let (ring, bg, art) = Self.look(region)
            ctx.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100)), with: .color(Color(hex: ring)))
            var g = ctx
            g.clip(to: Path(ellipseIn: CGRect(x: 2, y: 2, width: 96, height: 96)))
            g.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)),
                   with: .linearGradient(Gradient(colors: bg.map(Color.init(hex:))), startPoint: CGPoint(x: 50, y: 0), endPoint: CGPoint(x: 50, y: 100)))
            for item in art { item.draw(in: &g) }
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 15 / 255, green: 8 / 255, blue: 35 / 255).opacity(0.5), radius: size * 0.1, y: size * 0.095)
        .accessibilityElement()
        .accessibilityLabel(loc("boss.\(region.rawValue).name"))
    }

    /// Outer ring, background gradient and the portrait.
    private static func look(_ r: RegionID) -> (String, [String], [ArtItem]) {
        switch r {
        case .cap: ("#5aa9e6", ["#3d5a8c", "#9fc0e0"], kenan)
        case .abq: ("#5aa9e6", ["#e08a4a", "#f6d08a"], dale)
        case .lux: ("#1f6f8b", ["#1f6f8b", "#e8c47a"], nabil)
        }
    }

    private static let kenan: [ArtItem] = [
        .fill("M14 100 C16 78 30 70 50 70 C70 70 84 78 86 100Z", "#1f2a44"),
        .fill("M42 70 L50 86 L58 70Z", "#ffffff"),
        .fill("M48 72 L52 72 L54 92 L50 96 L46 92Z", "#c0283a"),
        .fill("M30 74 L38 72 L44 90Z M70 74 L62 72 L56 90Z", "#2c3a5c"),
        .box(43, 58, 14, 14, 4, "#d9a07a"),
        .oval(50, 44, 18, 21, "#e2ad86"),
        .fill("M31 40 C31 22 42 18 52 18 C64 18 70 26 69 40 C66 31 58 28 50 29 C42 29 35 32 31 40Z", "#3a3a44"),
        .line("M33 37 C33 30 37 26 40 25", "#9aa0a8", 3),
        .line("M38 40 Q43 37 47 40 M53 40 Q57 37 62 40", "#2a2018", 2.2),
        .dot(43, 44, 1.8, "#1f1b2e"), .dot(57, 44, 1.8, "#1f1b2e"),
        .fill("M38 53 C43 49 47 51 50 51 C53 51 57 49 62 53 C58 55 54 54 50 54 C46 54 42 55 38 53Z", "#3a3a44"),
        .line("M45 58 Q52 60 56 57", "#8a4a3a", 1.8),
        .dot(64, 82, 3, "#ffc23d")
    ]

    private static let dale: [ArtItem] = [
        .fill("M14 100 C16 78 30 70 50 70 C70 70 84 78 86 100Z", "#8a5a34"),
        .fill("M40 70 L50 82 L60 70Z", "#f3e8d0"),
        .fill("M46 74 L54 74 L50 80Z", "#14a39a"),
        .dot(50, 77, 2.4, "#c0c6cc"),
        .box(43, 58, 14, 14, 4, "#c98a62"),
        .oval(50, 46, 18, 20, "#e0a07a"),
        .fill("M18 36 C26 33 74 33 82 36 C82 40 74 40 50 40 C26 40 18 40 18 36Z", "#f1ddb0"),
        .fill("M31 37 C31 20 40 14 50 14 C60 14 69 20 69 37Z", "#f6e6c0"),
        .fill("M31 33 L69 33 L69 37 L31 37Z", "#5a3418"),
        .line("M38 44 Q43 42 47 44 M53 44 Q57 42 62 44", "#5a3a20", 2),
        .dot(43, 48, 1.8, "#1f1b2e"), .dot(57, 48, 1.8, "#1f1b2e"),
        .line("M41 57 Q50 63 59 56", "#6a3a2a", 2),
        .line("M55 58 L64 56", "#f3e8d0", 2.2),
        .dot(65, 56, 1.4, "#ff8a3d")
    ]

    private static let nabil: [ArtItem] = [
        .fill("M14 100 C16 78 30 70 50 70 C70 70 84 78 86 100Z", "#f4efe4"),
        .fill("M38 72 L50 90 L62 72Z", "#e2d8c4"),
        .fill("M26 80 C30 76 36 74 40 74 L44 100 L22 100Z M74 80 C70 76 64 74 60 74 L56 100 L78 100Z", "#2a3a5a"),
        .box(43, 58, 14, 14, 4, "#a8704a"),
        .oval(50, 44, 18, 21, "#b97a50"),
        .fill("M31 40 C30 22 41 17 51 17 C63 17 70 25 69 40 C67 30 58 26 50 27 C42 27 34 31 31 40Z", "#1f1a1a"),
        .line("M64 26 C67 29 68 33 68 37", "#8a8a90", 2.5),
        .fill("M37 42 L48 42 L47 47 L38 47Z M52 42 L63 42 L62 47 L53 47Z", "#2a2018"),
        .line("M48 43.5 L52 43.5", "#c9a040", 1.6),
        .fill("M39 53 C44 50 47 51.5 50 51.5 C53 51.5 56 50 61 53 C57 55 53 54.5 50 54.5 C47 54.5 43 55 39 53Z", "#1f1a1a"),
        .line("M45 58 Q50 60.5 55 58", "#6a3a2a", 1.8),
        .dot(32, 88, 3, "#c9a040")
    ]
}

// MARK: The morning paper

/// A sheet of newsprint on old parchment: masthead, the lead story with a halftone photo, two more below. Port of `showPaper`.
struct PaperView: View {
    @Environment(GameStore.self) private var store
    let items: [PaperItem]

    private let ink = Color(hex: "#1f1c18"), ink2 = Color(hex: "#3a352c")
    private func serif(_ size: CGFloat, _ w: Font.Weight = .regular) -> Font { .system(size: size, weight: w, design: .serif) }

    var body: some View {
        let s = store.state
        let company = s?.company ?? ""
        ZStack {
            Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                sheet(company: company, day: s?.day ?? 1, region: s?.region ?? .cap)
                Button(loc("paper.fold")) {
                    SoundEngine.shared.play(.click)
                    store.closePaper()
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
            }
            .padding(16)
            .background(parchment, in: RoundedRectangle(cornerRadius: 24))
            .compositingGroup()
            .shadow(color: .black.opacity(0.35), radius: 25, y: 10)
            .padding(16)
            .frame(maxWidth: 440)
        }
    }

    private var parchment: some ShapeStyle {
        RadialGradient(colors: [Color(hex: "#ead39c"), Color(hex: "#b48a4a")], center: .center, startRadius: 40, endRadius: 360)
    }

    private func sheet(company: String, day: Int, region: RegionID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 4) {
                Text(loc("paper.mast.\(region.rawValue)"))
                    .font(serif(29, .black)).foregroundStyle(ink)
                HStack {
                    Text(loc("paper.day", num(day)))
                    Spacer()
                    Text(loc("paper.edition"))
                    Spacer()
                    Text(loc("paper.price.\(region.rawValue)"))
                }
                .font(serif(11.5).italic()).foregroundStyle(ink2)
                .padding(.top, 3)
                .overlay(alignment: .top) { Rectangle().fill(ink).frame(height: 1) }
            }
            .padding(.bottom, 4)
            .overlay(alignment: .bottom) { VStack(spacing: 2) { Rectangle().fill(ink).frame(height: 1); Rectangle().fill(ink).frame(height: 1) } }
            if let lead = items.first {
                Text(lead.headline(company))
                    .font(serif(25, .black)).foregroundStyle(ink)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                PaperPhoto().frame(height: 96).overlay(Rectangle().stroke(ink, lineWidth: 1)).accessibilityHidden(true)
                if let sub = lead.subline(company) {
                    Text(sub).font(serif(15)).foregroundStyle(ink2).fixedSize(horizontal: false, vertical: true)
                }
            }
            if items.count > 1 {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(items.dropFirst().enumerated()), id: \.offset) { i, x in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(x.headline(company)).font(serif(15, .bold)).foregroundStyle(ink)
                            if let sub = x.subline(company) { Text(sub).font(serif(13)).foregroundStyle(ink2) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        // The column rule rides on the column: a bare Rectangle in the HStack would stretch the paper to the full screen.
                        .overlay(alignment: .leading) {
                            if i > 0 { Rectangle().fill(ink.opacity(0.4)).frame(width: 1).offset(x: -5) }
                        }
                    }
                }
                .padding(.top, 6)
                .overlay(alignment: .top) { Rectangle().fill(ink).frame(height: 1) }
            }
        }
        .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 14)
        .background(Color(hex: "#efeadd"))
        .shadow(color: Color(hex: "#3c280a").opacity(0.35), radius: 3, y: 2)
        .rotationEffect(.degrees(-0.6))
    }
}

/// Balloons over the chimneys, printed as halftone dots. Port of `paperPhoto`.
struct PaperPhoto: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, ink = Color(hex: "#2a2620")
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "#e9e4d6")))
            // Density field: sky light, hills medium, chimneys and balloons dark.
            func tone(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
                let u = x / w * 300, v = y / h * 110
                if hypot(u - 230, v - 70) < 20 { return 0 }
                for (bx, by, k) in [(110.0, 20.0, 1.0), (150, 38, 0.7), (70, 30, 0.55), (190, 18, 0.5), (255, 34, 0.4)] {
                    let dx = (u - bx) / k, dy = (v - by) / k
                    if dy > -20 && dy < 22 && abs(dx) < 16 - max(0, dy - 6) * 0.55 { return 1.85 }
                    if dy >= 25 && dy < 31 && abs(dx) < 4 { return 1.85 }
                }
                for (cx, top) in [(40.0, 62.0), (78, 70), (206, 56), (257, 72)] where v > top && abs(u - cx) < (v - top) / 5 { return 1.85 }
                let hill = 84 - 10 * sin(u * 0.04)
                if v > hill { return 1.35 }
                return 0.75
            }
            let step: CGFloat = 4 * w / 300
            var y: CGFloat = step / 2
            while y < h {
                var x: CGFloat = step / 2
                while x < w {
                    let r = tone(x, y) * w / 300
                    if r > 0 { ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(ink)) }
                    x += step
                }
                y += step
            }
        }
    }
}

extension PaperItem {
    private var key: String {
        switch self {
        case .vip: "vip"
        case .wedding: "wedding"
        case .documentary: "documentary"
        case .pressGood: "pressGood"
        case .pressBad: "pressBad"
        case .accident(_, _, let severe): severe ? "accidentSevere" : "accident"
        case .redCaught: "redCaught"
        case .antitrust: "antitrust"
        case .seized: "seized"
        case .festival: "festival"
        case .rivalAccident: "rivalAccident"
        case .rivalRedCaught: "rivalRedCaught"
        case .rivalBankrupt: "rivalBankrupt"
        case .newEntrant: "newEntrant"
        case .hotelLost: "hotelLost"
        case .record: "record"
        case .passedBoss: "passedBoss"
        case .upgrade: "upgrade"
        case .worldBaron: "worldBaron"
        case .night(let n): "night.\(n.key)"
        case .inspectorFine: "inspectorFine"
        case .worldRecord(let r): "worldRecord.\(r.rawValue)"
        case .deed(let d): "deed.\(d.rawValue)"
        case .milestone(let d): d == 365 ? "year" : "milestone"
        }
    }

    func headline(_ company: String) -> String {
        switch self {
        case .vip, .wedding, .documentary, .pressGood, .pressBad, .worldBaron, .deed: loc("paper.\(key)", company)
        case .accident: loc("paper.\(key)", company)
        case .redCaught: loc("paper.redCaught", company)
        case .antitrust: loc("paper.antitrust", company)
        case .seized: loc("paper.seized", company)
        case .festival(let i): loc("paper.festival", festivalName(i))
        case let .rivalAccident(r, _): loc("paper.rivalAccident", r)
        case let .rivalRedCaught(r, _): loc("paper.rivalRedCaught", r)
        case let .rivalBankrupt(r, _): loc("paper.rivalBankrupt", r)
        case let .newEntrant(r): loc("paper.newEntrant", r)
        case let .hotelLost(h, r): loc("paper.hotelLost", h.title, r)
        case .record(let n): loc("paper.record", company, num(n))
        case .passedBoss(let r): loc("paper.passedBoss", company, r)
        case .upgrade(let b, _): loc("paper.upgrade", company, b.title)
        case .night(let n): n.headline
        case .inspectorFine: loc("paper.inspectorFine", company)
        case .worldRecord: loc("paper.worldRecord", company)
        case .milestone(let d): d == 365 ? loc("paper.year", company) : loc("paper.milestone", company, num(d))
        }
    }

    func subline(_ company: String) -> String? {
        switch self {
        case .vip, .wedding: nil
        case let .accident(b, days, _): loc("paper.accident.sub", bname(b), num(days))
        case .redCaught(let fine): loc("paper.redCaught.sub", eur(fine))
        case let .antitrust(share, fine): loc("paper.antitrust.sub", num(share), eur(fine))
        case .seized(let b): loc("paper.seized.sub", bname(b))
        case let .rivalAccident(_, n): loc("paper.rivalAccident.sub", num(n))
        case let .rivalRedCaught(_, fine): loc("paper.rivalRedCaught.sub", eur(fine))
        case let .rivalBankrupt(_, n): loc("paper.rivalBankrupt.sub", num(n))
        case let .upgrade(b, lv): b.levelTitle(lv)
        case .night(let n): n.subline
        case .inspectorFine(let fine): loc("paper.inspectorFine.sub", eur(fine))
        default: loc("paper.\(key).sub")
        }
    }
}

extension NightEvent {
    var key: String {
        switch self {
        case .lanterns: "lanterns"
        case .balloonGlow: "glow"
        case .snow: "snow"
        case .fireworks: "fireworks"
        case .shootingStar: "shooting"
        }
    }

    /// Text key: in Luxor the glow night is the Nile night, the cruise ships lit up.
    private var textKey: String { self == .balloonGlow && currentRegion == .lux ? "glow.lux" : key }

    /// The line under "Night of day N".
    var line: String {
        switch self {
        case .lanterns(let f): loc("night.lanterns", festivalName(f))
        case .fireworks(let h): loc("night.fireworks", h.title)
        default: loc("night.\(textKey)")
        }
    }

    var headline: String {
        if case .fireworks(let h) = self { return loc("paper.night.fireworks", h.title) }
        return loc("paper.night.\(textKey)")
    }

    var subline: String { loc("paper.night.\(textKey).sub") }
}

// MARK: Morning events

/// A morning event card: what happened at one of your buildings and your two choices. Port of `eventCard`.
struct MorningEventView: View {
    @Environment(GameStore.self) private var store
    let event: MorningEvent

    var body: some View {
        let g = store.game
        let o = g?.eventOffer(event) ?? EventOffer()
        let s = g?.state
        ZStack(alignment: .bottom) {
            Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.18).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text(loc("event.tag"))
                    .font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
                CardText.title(event.title)
                CardText.lead(lead(o, s))
                Button(accept(o)) {
                    SoundEngine.shared.play(.coin)
                    store.answerEvent(event, accept: true)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
                .disabled(event == .fuel && (s?.cash ?? 0) < o.stock)
                Button {
                    SoundEngine.shared.play(.click)
                    store.answerEvent(event, accept: false)
                } label: {
                    Text(loc("event.\(event.rawValue).no")).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .ghost))
            }
            .padding(.horizontal, 20).padding(.vertical, 22)
            .frame(maxWidth: 420, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(alignment: .top) { UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24).fill(Theme.sun).frame(height: 6) }
            .compositingGroup()
            .shadow(color: .black.opacity(0.35), radius: 25, y: 10)
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
    }

    private func lead(_ o: EventOffer, _ s: GameState?) -> String {
        let region = s?.region ?? .cap
        switch event {
        case .strike: return loc("event.strike.lead", eur(o.wages))
        case .vip: return loc("event.vip.lead", regionalHotel(.palace, region), o.balloon.map(bname) ?? "", eur(o.pay))
        case .wedding: return loc("event.wedding.lead", regionalHotel(.mansion, region), o.balloon.map(bname) ?? "", eur(o.pay))
        case .doc: return loc("event.doc.lead", region.title)
        case .fuel: return loc("event.fuel.lead", eur(o.stock))
        case .press: return loc("event.press.lead", loc("paper.mast.\(region.rawValue)"))
        }
    }

    private func accept(_ o: EventOffer) -> String {
        switch event {
        case .strike: return loc("event.strike.yes", eur(o.raise))
        case .vip, .wedding: return loc("event.vip.yes", eur(o.pay))
        case .fuel: return loc("event.fuel.yes", eur(o.stock))
        default: return loc("event.\(event.rawValue).yes")
        }
    }

    private func regionalHotel(_ h: Hotel, _ r: RegionID) -> String { h.title }
}

// MARK: Rescue plan

/// When cash first dips below zero: Hezarfen's plan with the moves that help right now. Port of `showRescue`.
struct RescueView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let s = store.state
        return ModalCard {
            if let s {
                HStack(alignment: .center, spacing: 10) {
                    HezarfenAvatar(size: 40)
                    Text(loc("rescue.hez", eur(Rules.seizeBelow)))
                        .font(Theme.font(13.5)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
                CardText.title(loc("rescue.title"))
                options(s)
                Button {
                    SoundEngine.shared.play(.click)
                    store.closeRescue()
                } label: {
                    Text(loc("rescue.myself")).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .ghost))
            }
        }
    }

    @ViewBuilder
    private func options(_ s: GameState) -> some View {
        let idle = s.idlePilots
        let sellable = s.local.balloons.filter { $0.id != s.local.flagship }.sorted { $0.size.cost < $1.size.cost }
        let loanIndex = s.unlocked.contains(.bank) && s.local.loans.count < Rules.maxLoans
            ? Rules.loans.indices.reversed().first { s.local.balloons.count >= Rules.loans[$0].balloonsNeeded && Rules.loans[$0].minDailyNet == 0 } : nil
        if let g = store.game, g.rescueGuideOK {
            option(loc("rescue.guide", eur(Rules.guideCost)), loc("rescue.guide.sub", eur(s.cash - Rules.guideCost))) { _ = $0.runGuideFlight(inRescue: true) }
        }
        if let h = store.game?.rescueHotel {
            option(loc("rescue.hotel", h.title, eur(h.dailyFee * 3)), loc("rescue.hotel.sub", num(h.guests), eur(s.cash - h.dailyFee * 3))) { _ = $0.signHotel(h, inRescue: true) }
        }
        if !idle.isEmpty {
            option(loc("rescue.fire", num(idle.count)), loc("rescue.fire.sub", eur(idle.reduce(0) { $0 + $1.wage }))) { $0.fireIdlePilots() }
        }
        if let b = sellable.first {
            let v = store.game?.sellValue(b) ?? 0
            option(loc("rescue.sell", b.title), loc("rescue.sell.sub", eur(v))) { _ = $0.sellBalloon(b.id) }
        }
        if let rp = store.game?.rescuePrice {
            option(loc(rp.price < s.price ? "rescue.priceDown" : "rescue.priceUp", eur(rp.price)),
                   loc("rescue.price.sub", num(rp.pax), num(rp.seats), eur(rp.income), eur(rp.now))) { $0.setPrice(rp.price) }
        }
        if let i = loanIndex {
            let l = Rules.loans[i]
            option(loc("rescue.loan", eur(l.amount)), loc("rescue.loan.sub", eur(l.installment), num(l.days))) { _ = $0.takeLoan(i) }
        }
    }

    private func option(_ title: String, _ sub: String, _ f: @escaping (inout Game) -> Void) -> some View {
        Button {
            SoundEngine.shared.play(.coin)
            store.rescueMove(f)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Theme.font(15.5, .bold)).foregroundStyle(Theme.ink)
                Text(sub).font(Theme.font(13)).foregroundStyle(Theme.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}


// MARK: Temporary flagship

/// The flagship you fly is in repair: fly another balloon until it's back? The biggest that can fly is
/// picked; a dropdown (three rows tall, scrolling for the rest) changes it. Port of `showTempFlag` (v110).
struct TempFlagView: View {
    @Environment(GameStore.self) private var store
    @State private var pick: Int?
    @State private var open = false

    var body: some View {
        let g = store.game
        let list = g?.tempFlagshipCandidates ?? []
        let fb = g.flatMap { $0.state.balloon($0.state.flagship) }
        let chosen = list.first { $0.id == pick } ?? list.first
        return ModalCard {
            if let fb, let chosen, let day = g?.state.day {
                CardText.title(loc("tempFlag.title"))
                CardText.lead(loc("tempFlag.lead", fb.title, num(fb.damagedUntil - day)))
                Button {
                    SoundEngine.shared.play(.click)
                    withAnimation(.easeOut(duration: 0.15)) { open.toggle() }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(chosen.title).font(Theme.font(15.5, .bold)).foregroundStyle(Theme.ink)
                            Text(loc("tempFlag.seats", chosen.size.title, num(chosen.size.capacity)))
                                .font(Theme.font(13)).foregroundStyle(Theme.ink2)
                        }
                        Spacer(minLength: 8)
                        if list.count > 1 {
                            HStack(spacing: 4) {
                                if !open { Text(loc("tempFlag.change")).font(Theme.font(13, .bold)) }
                                Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(Theme.ink2)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .disabled(list.count < 2)
                if open {
                    let others = list.filter { $0.id != chosen.id }
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(others) { b in
                                Button {
                                    SoundEngine.shared.play(.click)
                                    pick = b.id
                                    withAnimation(.easeOut(duration: 0.15)) { open = false }
                                } label: {
                                    HStack {
                                        Text(b.title).font(Theme.font(15, .bold)).foregroundStyle(Theme.ink)
                                        Spacer(minLength: 8)
                                        Text(loc("tempFlag.seats", b.size.title, num(b.size.capacity)))
                                            .font(Theme.font(13)).foregroundStyle(Theme.ink2)
                                    }
                                    .padding(.horizontal, 14).frame(height: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                if b.id != others.last?.id { Divider() }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(others.count), 3.4) * 44)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 2))
                }
                HStack(spacing: 10) {
                    Button {
                        SoundEngine.shared.play(.click)
                        store.answerTempFlag(nil)
                    } label: { Text(loc("tempFlag.no")).frame(maxWidth: .infinity) }
                    .buttonStyle(ChunkyButtonStyle(kind: .ghost))
                    Button(loc("tempFlag.yes")) {
                        SoundEngine.shared.play(.click)
                        store.answerTempFlag(chosen.id)
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
                }
            }
        }
    }
}

// MARK: Postcards

/// A postcard: a small painted scene, the title, and a postmark with the day it was earned.
struct PostcardArt: View {
    let achievement: Achievement
    /// Day earned; nil draws it locked.
    let day: Int?
    let colors: [String]

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 150
            ctx.scaleBy(x: k, y: k)
            ctx.fill(Path(roundedRect: CGRect(x: 1, y: 1, width: 148, height: 94), cornerRadius: 6), with: .color(Theme.paper))
            ctx.stroke(Path(roundedRect: CGRect(x: 1, y: 1, width: 148, height: 94), cornerRadius: 6), with: .color(Theme.line), lineWidth: 1)
            var art = ctx
            let frame = Path(roundedRect: CGRect(x: 6, y: 6, width: 138, height: 66), cornerRadius: 3)
            art.clip(to: frame)
            let sky = achievement.sky
            art.fill(frame, with: .linearGradient(Gradient(stops: [.init(color: Color(hex: sky[0]), location: 0), .init(color: Color(hex: sky[1]), location: 0.6),
                                                                  .init(color: Color(hex: sky[2]), location: 1)]),
                                                  startPoint: CGPoint(x: 0, y: 6), endPoint: CGPoint(x: 0, y: 72)))
            achievement.scene(&art, colors: colors)
            if let day {
                var pm = ctx
                pm.opacity = 0.6
                pm.stroke(Path(ellipseIn: CGRect(x: 118, y: 10, width: 20, height: 20)), with: .color(Theme.ink), lineWidth: 1)
                for dy in [15.0, 20, 25] {
                    var wave = Path()
                    wave.move(to: CGPoint(x: 98, y: dy))
                    wave.addQuadCurve(to: CGPoint(x: 106, y: dy), control: CGPoint(x: 102, y: dy - 3))
                    wave.addQuadCurve(to: CGPoint(x: 114, y: dy), control: CGPoint(x: 110, y: dy + 3))
                    pm.stroke(wave, with: .color(Theme.ink), lineWidth: 0.8)
                }
                pm.draw(Text(loc("postcard.day")).font(Theme.font(5.5, .heavy, condensed: true)).foregroundStyle(Theme.ink), at: CGPoint(x: 128, y: 17))
                pm.draw(Text(num(day)).font(Theme.font(6.5, .heavy, condensed: true)).foregroundStyle(Theme.ink), at: CGPoint(x: 128, y: 24))
            }
            ctx.draw(Text(achievement.title).font(Theme.font(10, .heavy, condensed: true)).foregroundStyle(Theme.ink),
                     at: CGPoint(x: 8, y: 82), anchor: .leading)
            ctx.draw(Text(day == nil ? loc("postcard.locked", achievement.detail) : achievement.detail).font(Theme.font(6.6)).foregroundStyle(Theme.ink2),
                     at: CGPoint(x: 8, y: 91), anchor: .leading)
        }
        .aspectRatio(150 / 96, contentMode: .fit)
        .saturation(day == nil ? 0 : 1)
        .opacity(day == nil ? 0.45 : 1)
        .accessibilityElement()
        .accessibilityLabel(day.map { loc("album.earned", achievement.title, achievement.detail, num($0)) }
                            ?? loc("album.lockedHint", achievement.title, achievement.detail))
    }
}

extension Achievement {
    /// Sky of the scene: sunrise, day, night, dusk, snow or desert.
    var sky: [String] {
        switch self {
        case .mission, .fleet5, .pax1k, .design, .upgrade3: ["#4f9ee0", "#9fd2f0", "#e6f4fb"]
        case .star45, .fest, .world: ["#0f0e2e", "#2b2350", "#5a4a8a"]
        case .hotel, .hotelOwn, .rivalDown, .boss: ["#3a2a6a", "#c8607a", "#ffb070"]
        case .winter: ["#7fa6cf", "#c7dcef", "#f2f7fc"]
        case .abq, .baronAbq: ["#3f62b4", "#f09a6a", "#ffd08a"]
        default: ["#6b7fc4", "#f0b48c", "#ffdca8"]
        }
    }
}

/// A new postcard for the album. Port of `showPostcard`.
struct PostcardView: View {
    @Environment(GameStore.self) private var store
    let achievement: Achievement

    var body: some View {
        let s = store.state
        return ModalCard {
            Text(loc("postcard.new"))
                .font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
                .frame(maxWidth: .infinity)
            PostcardArt(achievement: achievement, day: s?.achievements[achievement] ?? s?.day, colors: s?.colors ?? [])
                .frame(maxWidth: 300)
                .rotationEffect(.degrees(-2))
                .shadow(color: Theme.ink.opacity(0.25), radius: 14, y: 8)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            CardText.title(achievement.title).frame(maxWidth: .infinity)
            CardText.lead(achievement.detail + ".").frame(maxWidth: .infinity)
            Button(loc("postcard.keep")) {
                SoundEngine.shared.play(.click)
                store.closePostcard()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
            ShareCardButton(achievement: achievement)
        }
    }
}

/// The album of postcards, from the menu. Port of `showAlbum`. A tapped postcard grows into its own card, with the
/// share button right under it.
struct AlbumView: View {
    @Environment(GameStore.self) private var store
    /// The postcard opened large.
    @State private var zoom: Achievement?

    var body: some View {
        let s = store.state
        let got = s?.achievements ?? [:]
        return ZStack {
            ModalCard(onClose: { store.showAlbum = false }) {
                CardText.title(loc("album.title"))
                CardText.hint(loc("album.count", num(got.count), num(Achievement.allCases.count)))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Achievement.allCases, id: \.self) { a in
                        Button {
                            SoundEngine.shared.play(.click)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { zoom = a }
                        } label: {
                            PostcardArt(achievement: a, day: got[a], colors: s?.colors ?? [])
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    SoundEngine.shared.play(.click)
                    store.showAlbum = false
                } label: {
                    Text(loc("world.close")).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .ghost))
            }
            if let a = zoom {
                PostcardZoom(achievement: a, day: got[a], colors: s?.colors ?? []) {
                    withAnimation(.easeOut(duration: 0.2)) { zoom = nil }
                }
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .zIndex(1)
            }
        }
    }
}

/// One postcard, large: the picture, what it's for, and for an earned one the share button.
private struct PostcardZoom: View {
    let achievement: Achievement
    let day: Int?
    let colors: [String]
    let close: () -> Void

    var body: some View {
        ZStack {
            Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: close)
            VStack(spacing: 14) {
                PostcardArt(achievement: achievement, day: day, colors: colors)
                    .frame(maxWidth: 360)
                    .rotationEffect(.degrees(day == nil ? 0 : -1.5))
                    .shadow(color: .black.opacity(0.3), radius: 16, y: 10)
                    .accessibilityHidden(true)
                CardText.title(achievement.title).frame(maxWidth: .infinity)
                CardText.lead(day.map { loc("album.earned", achievement.title, achievement.detail, num($0)) }
                              ?? loc("album.lockedHint", achievement.title, achievement.detail))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                if day != nil { ShareCardButton(achievement: achievement, big: true) }
                Button {
                    SoundEngine.shared.play(.click)
                    close()
                } label: {
                    Text(loc("world.close")).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .ghost))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: 440)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(alignment: .topTrailing) { CardCloseX(action: close) }
            .compositingGroup()
            .shadow(color: .black.opacity(0.35), radius: 25, y: 20)
            .padding(16)
        }
    }
}
