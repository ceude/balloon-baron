import SwiftUI
import StoreKit
import UIKit
import BalloonBaronCore

/// v123–v123.5: the family's letter (`showLetter`), once, from the morning of day 50, after Hezarfen's cards. A sealed
/// envelope: the Nevşehir stamp, the Göreme postmark with the day, and the company's name in a flowing hand. A tap turns
/// it over; on the back a round balloon sticker in the company's colours holds the flap down. It lifts off with a faint
/// burner, the flap opens, a folded letter rises out, the envelope drops away and the letter grows to full size: the
/// family's photo taped on, a few lines, and a button to the App Store's review page. Sunrise glitter and a short magic
/// chime while it opens, then a light Hicaz tune while it is read (`SoundEngine.letterMusic`).
struct LetterView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    enum Phase: Int, Comparable {
        case front, flip, lift, pull, read
        static func < (a: Phase, b: Phase) -> Bool { a.rawValue < b.rawValue }
    }

    @State private var phase = Phase.front
    @State private var appeared = false
    @State private var hintDim = false
    @State private var rated = false
    @State private var closing = false
    @State private var sparks = LetterSparkles()

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width, H = geo.size.height
            let ew = min(340, W * 0.88), eh = ew * 2 / 3
            let stage = CGRect(x: (W - ew) / 2, y: (H - eh) / 2, width: ew, height: eh)
            ZStack {
                Color(red: 20 / 255, green: 14 / 255, blue: 40 / 255).opacity(0.74)
                    .ignoresSafeArea()
                envelope(w: ew, h: eh, screenH: H)
                    .position(x: stage.midX, y: stage.midY)
                LetterSparkleLayer(model: sparks)
                    .allowsHitTesting(false)
                    .onAppear { sparks.stage = stage; sparks.screenH = H }
                    .onChange(of: geo.size) { _, s in
                        sparks.stage = CGRect(x: (s.width - ew) / 2, y: (s.height - eh) / 2, width: ew, height: eh)
                    }
                if phase == .front {
                    Text(loc("letter.hint"))
                        .font(Theme.font(16, .bold, condensed: true))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .opacity(hintDim ? 0.4 : 0.85)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 40)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
                sheet(width: min(400, W - 28), maxHeight: H - 24)
                    .scaleEffect(phase == .read ? 1 : 0.82)
                    .offset(y: phase == .read ? 0 : -H * 0.06)
                    .opacity(phase == .read ? 1 : 0)
                    .allowsHitTesting(phase == .read && !closing)
                    .animation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.8), value: phase)
            }
            .frame(width: W, height: H)
        }
        .opacity(closing ? 0 : 1)
        .animation(.easeOut(duration: 0.35), value: closing)
        .onAppear(perform: start)
    }

    // MARK: the envelope

    private func envelope(w: CGFloat, h: CGFloat, screenH: CGFloat) -> some View {
        let angle: Double = phase >= .flip ? 180 : 0
        let colors = store.state?.colors ?? ["#e5432f", "#ffc23d"]
        return ZStack {
            LetterFront(w: w, h: h, company: store.state?.company ?? "", day: store.state?.letterDay ?? store.state?.day ?? Letter.day)
                .modifier(FlipFace(angle: angle, back: false))
            LetterBack(w: w, h: h, phase: phase, colors: colors, screenH: screenH)
                .modifier(FlipFace(angle: angle, back: true))
        }
        .frame(width: w, height: h)
        .animation(.timingCurve(0.5, 0, 0.3, 1, duration: 1), value: phase >= .flip)
        .contentShape(Rectangle())
        .onTapGesture(perform: openEnvelope)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loc("letter.hint"))
        .accessibilityAddTraits(.isButton)
        // it comes in from below, tilted; and drops away once the letter is out
        .rotationEffect(.degrees(appeared ? 0 : -7))
        .offset(y: phase == .read ? screenH * 0.42 : appeared ? 0 : 70)
        .scaleEffect(phase == .read ? 0.9 : 1)
        .opacity(phase == .read ? 0 : appeared ? 1 : 0)
        .animation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.7), value: phase == .read)
    }

    // MARK: the letter

    private var lang: String { Bundle.main.preferredLocalizations.first ?? "en" }

    private func sheet(width: CGFloat, maxHeight: CGFloat) -> some View {
        let hand = LetterHand(lang: lang)
        let content = sheetContent(width: width, hand: hand)
        return ViewThatFits(in: .vertical) {
            content
            ScrollView(showsIndicators: false) { content }
        }
        .frame(width: width)
        .frame(maxHeight: maxHeight)
        .background(Parchment(corner: 3))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.45), radius: 30, y: 24)
    }

    private func sheetContent(width: CGFloat, hand: LetterHand) -> some View {
        let s = store.state
        let company = s?.company ?? ""
        let day = s?.letterDay ?? s?.day ?? Letter.day
        let ink = Color(hex: "#232a5c"), inkDark = Color(hex: "#1f2350")
        let inner = width - 44
        let sign = loc("letter.signOff") + "\n" + loc("letter.signature")
        return VStack(spacing: 0) {
            TapedPhoto(width: inner * 0.74)
                .padding(.top, 2)
                .padding(.bottom, 14)
            Text(loc("letter.greeting", company))
                .font(hand.font(25, .bold))
                .foregroundStyle(inkDark)
                .shadow(color: inkDark.opacity(0.55), radius: 0.35)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            VStack(alignment: .leading, spacing: 9) {
                Text(loc("letter.p1", num(day)))
                Text(loc("letter.p2"))
            }
            .font(hand.font(19 * hand.bodyScale, .medium))
            .lineSpacing(19 * hand.bodyScale * 0.3)
            .foregroundStyle(ink)
            .shadow(color: ink.opacity(0.55), radius: 0.4)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                InkBlot(seed: 1).fill(inkDark.opacity(0.55)).frame(width: 18, height: 18).offset(x: 16, y: -14)
            }
            .padding(.bottom, 9)
            Text(sign)
                .font(hand.font(23, .bold))
                .multilineTextAlignment(.trailing)
                .lineSpacing(1)
                .foregroundStyle(inkDark)
                .shadow(color: inkDark.opacity(0.55), radius: 0.35)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 6)
                .overlay(alignment: .topLeading) {
                    InkBlot(seed: 2).fill(inkDark.opacity(0.78)).frame(width: 34, height: 34)
                        .rotationEffect(.degrees(-20)).offset(x: 8, y: 2)
                }
                .padding(.top, 6)
                .padding(.bottom, 12)
            if rated {
                Text(loc("letter.thanks"))
                    .font(.custom("CaveatBrush-Regular", size: 22))
                    .foregroundStyle(Theme.green)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                    .transition(.opacity)
            } else {
                Button(action: rate) {
                    Text(loc("letter.rate"))
                        .font(Theme.font(19, .heavy, condensed: true))
                        .tracking(0.4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.white)
                        .padding(.vertical, 13)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(Theme.coral, in: RoundedRectangle(cornerRadius: 14))
                        .background(Color(hex: "#d9411f"), in: RoundedRectangle(cornerRadius: 14).offset(y: 4))
                }
                .buttonStyle(.plain)
            }
            Button(action: close) {
                Text(loc(rated ? "letter.close" : "letter.later"))
                    .font(Theme.font(15, .bold, condensed: true))
                    .foregroundStyle(Theme.ink2)
                    .padding(8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.top, 20)
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
        .frame(width: width)
    }

    // MARK: the sequence

    private func start() {
        withAnimation(.timingCurve(0.2, 0.9, 0.3, 1.15, duration: 0.8)) { appeared = true }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { hintDim = true }
        SoundEngine.shared.play(.click)
        #if DEBUG
        // Screenshots (`-demoScene letterRead`): the letter already open.
        if ProcessInfo.processInfo.arguments.contains("letterRead") {
            phase = .read
            sparks.reading = true
            sparks.rate = 2.5
        }
        #endif
    }

    /// The prototype's timeline after the tap (ms): turn 0, burner 1300–2700, sticker and flap 2000, letter out 2900,
    /// envelope away and the letter up 3900.
    private func openEnvelope() {
        guard phase == .front else { return }
        phase = .flip
        SoundEngine.shared.letterMusic(.magic)
        sparks.burst(35)
        sparks.rate = 14
        func at(_ s: Double, _ f: @escaping () -> Void) { DispatchQueue.main.asyncAfter(deadline: .now() + s, execute: f) }
        at(1.3) { SoundEngine.shared.burner(true, level: 0.3) }
        at(2.0) {
            withAnimation(.timingCurve(0.55, 0, 0.75, 0.4, duration: 1.5)) { phase = .lift }
            sparks.followSticker()
        }
        at(2.7) { SoundEngine.shared.burner(false) }
        at(2.9) { withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.9)) { phase = .pull } }
        at(3.5) { sparks.follow = nil }
        at(3.9) {
            phase = .read
            sparks.reading = true
            sparks.burst(45, speed: 2.2)
            sparks.rain(14)
            sparks.rate = 2.5
            SoundEngine.shared.letterMusic(.letter)
        }
    }

    /// The App Store's write-review page when the app's Apple ID is known, else Apple's own rating prompt.
    @MainActor private func rate() {
        SoundEngine.shared.play(.click)
        let day = store.state?.day ?? 0
        store.act { $0.markLetterRated() }
        Telemetry.letter("rate", day: day)
        if let url = AppStoreLink.writeReviewURL { openURL(url) } else { requestReview() }
        withAnimation(.easeOut(duration: 0.25)) { rated = true }
    }

    private func close() {
        guard !closing else { return }
        SoundEngine.shared.play(.click)
        if !rated { Telemetry.letter("later", day: store.state?.day ?? 0) }
        SoundEngine.shared.letterMusic(nil)
        SoundEngine.shared.burner(false)
        closing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { store.closeLetter() }
    }
}

/// The letter's handwriting: Dancing Script for Latin scripts, Yomogi for Japanese, Gaegu for Korean (all bundled, OFL).
struct LetterHand {
    let lang: String
    var ja: Bool { lang.hasPrefix("ja") }
    var ko: Bool { lang.hasPrefix("ko") }
    /// Kana, kanji and hangul take more room per line than Latin letters.
    var bodyScale: CGFloat { ja || ko ? 0.86 : 1 }

    enum Weight { case medium, semibold, bold }

    func name(_ w: Weight) -> String {
        if ja { return "Yomogi-Regular" }
        if ko { return w == .medium ? "Gaegu-Regular" : "Gaegu-Bold" }
        switch w {
        case .medium: return "DancingScript-Medium"
        case .semibold: return "DancingScript-SemiBold"
        case .bold: return "DancingScript-Bold"
        }
    }

    /// Fixed sizes: the envelope and the letter are laid out to fit one screen.
    func font(_ size: CGFloat, _ w: Weight) -> Font { .custom(name(w), fixedSize: size) }

    /// The company's name on the envelope: Great Vibes when it is written in Latin letters.
    func scriptName(for text: String) -> String {
        let latin = text.unicodeScalars.allSatisfy { $0.value < 0x0250 || (0x1E00...0x1EFF).contains($0.value) || $0.properties.isWhitespace }
        if latin { return "GreatVibes-Regular" }
        return ja ? "Yomogi-Regular" : ko ? "Gaegu-Bold" : "GreatVibes-Regular"
    }
}

/// Shows the front only while it faces the viewer, and the back (turned half a turn) after.
private struct FlipFace: ViewModifier, Animatable {
    var angle: Double
    let back: Bool
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        let shown = back ? angle > 90 : angle <= 90
        content
            .opacity(shown ? 1 : 0)
            .rotation3DEffect(.degrees(back ? angle - 180 : angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

// MARK: - The envelope's front

private struct LetterFront: View {
    let w: CGFloat, h: CGFloat
    let company: String
    let day: Int

    private var hand: LetterHand { LetterHand(lang: Bundle.main.preferredLocalizations.first ?? "en") }

    var body: some View {
        let addr = addressLines()
        let font = hand.scriptName(for: company)
        let aw = w * 0.81
        let fit = Self.fitName(company, font: font, width: aw)
        let nameH = (fit.two ? 2 : 1) * fit.size * 1.05 + 6
        let top = h * max(0.30, 0.50 - max(0, nameH - 50) / h)
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 7).fill(Color(hex: "#f3e6cc"))
            Canvas { c, size in
                // the paper's faint dotted grain
                var y: CGFloat = 0
                while y < size.height {
                    var x: CGFloat = 0
                    while x < size.width {
                        c.fill(Path(ellipseIn: CGRect(x: x + 2.5, y: y + 2.5, width: 2, height: 2)), with: .color(Color(red: 140 / 255, green: 100 / 255, blue: 50 / 255).opacity(0.07)))
                        x += 7
                    }
                    y += 7
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
            Postmark(day: day)
                .frame(width: 70, height: 70)
                .opacity(0.5)
                .rotationEffect(.degrees(-14))
                .offset(x: w - 70 - 70, y: 40)
            Stamp()
                .frame(width: 82, height: 104)
                .rotationEffect(.degrees(3))
                .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
                .offset(x: w - 14 - 82, y: 12)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(addr.indices, id: \.self) { i in
                    let line = addr[i]
                    if line.big {
                        Text(line.text)
                            .font(.custom(font, fixedSize: fit.size))
                            .lineLimit(fit.two ? 2 : 1)
                            .minimumScaleFactor(0.85)
                            .lineSpacing(0)
                            .frame(width: fit.two ? aw * 0.78 : aw, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                    } else {
                        Text(line.text)
                            .font(hand.font(24, .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.leading, 26)
                            .padding(.top, 2)
                    }
                }
                Text(loc("letter.addrPlace"))
                    .font(hand.font(18, .medium))
                    .foregroundStyle(Color(hex: "#6a5a86"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.leading, 26)
                    .padding(.top, 8)
            }
            .foregroundStyle(Color(hex: "#2c2350"))
            .frame(width: aw, alignment: .leading)
            .offset(x: w * 0.11, y: top)
        }
        .frame(width: w, height: h)
        .compositingGroup()
        .shadow(color: .black.opacity(0.38), radius: 22, y: 20)
    }

    /// `letter.addrTo` holds two lines; the one with the company name is drawn big. The order differs by language.
    private func addressLines() -> [(text: String, big: Bool)] {
        loc("letter.addrTo").components(separatedBy: "\n").map { l in
            l.contains("%@") ? (l.replacingOccurrences(of: "%@", with: company), true) : (l, false)
        }
    }

    /// v123.5: the name shrinks from 42 to 28 pt to fit one line; past that it takes two lines, from 32 pt down to 20.
    static func fitName(_ s: String, font: String, width: CGFloat) -> (size: CGFloat, two: Bool) {
        func ui(_ p: CGFloat) -> UIFont { UIFont(name: font, size: p) ?? .systemFont(ofSize: p) }
        func wid(_ p: CGFloat) -> CGFloat { (s as NSString).size(withAttributes: [.font: ui(p)]).width }
        var fs: CGFloat = 42
        while wid(fs) > width && fs > 28 { fs -= 1 }
        if wid(fs) <= width { return (fs, false) }
        fs = 32
        func lines(_ p: CGFloat) -> CGFloat {
            let r = (s as NSString).boundingRect(with: CGSize(width: width * 0.78, height: .greatestFiniteMagnitude),
                                                 options: [.usesLineFragmentOrigin], attributes: [.font: ui(p)], context: nil)
            return r.height / max(1, ui(p).lineHeight)
        }
        while lines(fs) > 2.05 && fs > 20 { fs -= 1 }
        return (fs, true)
    }
}

/// The Nevşehir balloon stamp (`STAMP_SVG`) on its perforated white paper.
private struct Stamp: View {
    var body: some View {
        Canvas { c, size in
            // the paper with its perforated edge: round bites every 8 pt
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "#fffaf0")))
            var bites = Path()
            var x: CGFloat = 0
            while x <= size.width + 4 {
                bites.addEllipse(in: CGRect(x: x - 2.9, y: -2.9, width: 5.8, height: 5.8))
                bites.addEllipse(in: CGRect(x: x - 2.9, y: size.height - 2.9, width: 5.8, height: 5.8))
                x += 8
            }
            var y: CGFloat = 0
            while y <= size.height + 4 {
                bites.addEllipse(in: CGRect(x: -2.9, y: y - 2.9, width: 5.8, height: 5.8))
                bites.addEllipse(in: CGRect(x: size.width - 2.9, y: y - 2.9, width: 5.8, height: 5.8))
                y += 8
            }
            c.blendMode = .destinationOut
            c.fill(bites, with: .color(.black))
            c.blendMode = .normal
            // the picture, 54 × 70 units inside a 6 pt margin
            let r = CGRect(x: 6, y: 6, width: size.width - 12, height: size.height - 12)
            let k = r.width / 54
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * k, y: r.minY + y * r.height / 70) }
            c.fill(Path(r), with: .linearGradient(Gradient(stops: [.init(color: Color(hex: "#ffb36b"), location: 0), .init(color: Color(hex: "#ffd9a0"), location: 0.7)]),
                                                  startPoint: CGPoint(x: r.midX, y: r.minY), endPoint: CGPoint(x: r.midX, y: r.maxY)))
            c.fill(Path(ellipseIn: CGRect(x: p(33, 33).x, y: p(33, 33).y, width: 14 * k, height: 14 * k)), with: .color(Color(hex: "#fff3c4")))
            func poly(_ pts: [(CGFloat, CGFloat)], _ col: String) {
                var path = Path()
                path.move(to: p(pts[0].0, pts[0].1))
                for q in pts.dropFirst() { path.addLine(to: p(q.0, q.1)) }
                path.closeSubpath()
                c.fill(path, with: .color(Color(hex: col)))
            }
            poly([(0, 52), (6, 38), (9, 46), (13, 33), (17, 47), (22, 40), (27, 52), (33, 36), (37, 47), (42, 42), (47, 34), (50, 46), (54, 40), (54, 70), (0, 70)], "#c98a5a")
            poly([(0, 60), (10, 52), (22, 58), (34, 50), (46, 57), (54, 52), (54, 70), (0, 70)], "#a8693f")
            /// A balloon envelope: top at (cx, top), widest at `half`, mouth `mouth` wide at `bottom`.
            func balloon(_ pts: [(CGFloat, CGFloat)], _ col: String) {
                // M p0 C p1 p2 p3 C p4 p5 p6 L p7 C p8 p9 p10 C p11 p12 p13 Z
                var path = Path()
                path.move(to: p(pts[0].0, pts[0].1))
                path.addCurve(to: p(pts[3].0, pts[3].1), control1: p(pts[1].0, pts[1].1), control2: p(pts[2].0, pts[2].1))
                path.addCurve(to: p(pts[6].0, pts[6].1), control1: p(pts[4].0, pts[4].1), control2: p(pts[5].0, pts[5].1))
                path.addLine(to: p(pts[7].0, pts[7].1))
                path.addCurve(to: p(pts[10].0, pts[10].1), control1: p(pts[8].0, pts[8].1), control2: p(pts[9].0, pts[9].1))
                path.addCurve(to: p(pts[13].0, pts[13].1), control1: p(pts[11].0, pts[11].1), control2: p(pts[12].0, pts[12].1))
                path.closeSubpath()
                c.fill(path, with: .color(Color(hex: col)))
            }
            balloon([(22, 8), (28, 8), (31, 12), (31, 17), (31, 21), (28, 24), (26.5, 26), (21.5, 26), (20, 24), (17, 21), (17, 17), (17, 12), (20, 8), (22, 8)], "#e5432f")
            balloon([(22, 8), (24, 8), (25.5, 12), (25.5, 17), (25.5, 21), (24.5, 24), (24, 26), (20, 26), (19.5, 24), (18.5, 21), (18.5, 17), (18.5, 12), (20, 8), (22, 8)], "#ffc23d")
            c.fill(Path(roundedRect: CGRect(x: p(21, 27.5).x, y: p(21, 27.5).y, width: 4 * k, height: 3 * k), cornerRadius: 0.6 * k), with: .color(Color(hex: "#6b4a26")))
            balloon([(38, 18), (40.5, 18), (42, 20), (42, 22), (42, 24), (40.5, 25), (40, 26), (37.5, 26), (37, 25), (35.5, 24), (35.5, 22), (35.5, 20), (37, 18), (38, 18)], "#2b7fd6")
            // stamps and postmarks say NEVŞEHİR and GÖREME in every language, like real ones
            c.draw(Text("NEVŞEHİR").font(.custom("BarlowCondensed-ExtraBold", fixedSize: 7.5 * k)).tracking(0.6 * k).foregroundColor(Color(hex: "#fffaf0")),
                   at: p(27, 66), anchor: UnitPoint(x: 0.5, y: 0.78))
            c.draw(Text("₺5").font(.custom("BarlowCondensed-ExtraBold", fixedSize: 7 * k)).foregroundColor(Color(hex: "#7a3a1c")),
                   at: p(4, 8), anchor: UnitPoint(x: 0, y: 0.78))
        }
    }
}

/// The Göreme postmark (`postmarkSvg`): two rings, wavy cancel lines, the place and the day.
private struct Postmark: View {
    let day: Int

    var body: some View {
        Canvas { c, size in
            let k = size.width / 66
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            let ink = Color(hex: "#3b2c5a")
            var rings = Path()
            rings.addEllipse(in: CGRect(x: 13 * k, y: 13 * k, width: 40 * k, height: 40 * k))
            rings.addEllipse(in: CGRect(x: 18 * k, y: 18 * k, width: 30 * k, height: 30 * k))
            var waves = Path()
            for y in [18.0, 26, 40, 48] as [CGFloat] {
                var x: CGFloat = -36
                waves.move(to: p(x, y))
                for i in 0..<4 {
                    waves.addQuadCurve(to: p(x + 16, y), control: p(x + 8, y + (i % 2 == 0 ? -4 : 4)))
                    x += 16
                }
            }
            c.clip(to: Path(CGRect(origin: .zero, size: size)))
            c.stroke(rings, with: .color(ink), lineWidth: 1.3 * k)
            c.stroke(waves, with: .color(ink), lineWidth: 1.3 * k)
            c.draw(Text("GÖREME").font(.custom("BarlowCondensed-Bold", fixedSize: 6.5 * k)).foregroundColor(ink), at: p(33, 31), anchor: UnitPoint(x: 0.5, y: 0.78))
            c.draw(Text(loc("letter.postmarkDay", num(day))).font(.custom("BarlowCondensed-Bold", fixedSize: 6 * k)).foregroundColor(ink),
                   at: p(33, 39), anchor: UnitPoint(x: 0.5, y: 0.78))
        }
    }
}

// MARK: - The envelope's back

private struct LetterBack: View {
    let w: CGFloat, h: CGFloat
    let phase: LetterView.Phase
    let colors: [String]
    let screenH: CGFloat

    var body: some View {
        let lifted = phase >= .lift
        let paperH = h * (1 - 0.06 - 0.08)
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 7).fill(Color(hex: "#e7d2ab"))
                .zIndex(0)
            // the folded letter inside: it shows once the flap is open and rises out
            FoldedPaper()
                .frame(width: w * 0.86, height: paperH)
                .offset(x: w * 0.07, y: h * 0.06 + (phase >= .pull ? -paperH * 0.64 : 0))
                .opacity(lifted ? 1 : 0)
                .animation(.easeOut(duration: 0.2).delay(0.3), value: lifted)
                .zIndex(1)
            Pocket()
                .frame(width: w, height: h)
                .zIndex(2)
            Flap()
                .fill(Color(hex: "#e0c592"))
                .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
                .frame(width: w, height: h * 0.6)
                .rotation3DEffect(.degrees(lifted ? 180 : 0), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.5)
                .animation(.easeInOut(duration: 0.6).delay(0.25), value: lifted)
                .zIndex(lifted ? 0.5 : 3)
            Sticker(colors: colors)
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(lifted ? 8 : 0))
                .scaleEffect(lifted ? 1.25 : 1)
                .offset(x: w / 2 - 40 + (lifted ? 18 : 0), y: h * 0.6 - 48 - (lifted ? screenH * 0.62 : 0))
                .opacity(lifted ? 0 : 1)
                .zIndex(4)
        }
        .frame(width: w, height: h)
        .compositingGroup()
        .shadow(color: .black.opacity(0.38), radius: 22, y: 20)
    }
}

/// The pocket: the two side folds and the bottom fold, each a shade of kraft.
private struct Pocket: View {
    var body: some View {
        Canvas { c, size in
            let w = size.width, h = size.height
            var left = Path()
            left.move(to: CGPoint(x: 0, y: 0)); left.addLine(to: CGPoint(x: w / 2, y: h)); left.addLine(to: CGPoint(x: 0, y: h)); left.closeSubpath()
            var right = Path()
            right.move(to: CGPoint(x: w, y: 0)); right.addLine(to: CGPoint(x: w, y: h)); right.addLine(to: CGPoint(x: w / 2, y: h)); right.closeSubpath()
            var bottom = Path()
            bottom.move(to: CGPoint(x: 0, y: h)); bottom.addLine(to: CGPoint(x: w / 2, y: h * 0.45)); bottom.addLine(to: CGPoint(x: w, y: h)); bottom.closeSubpath()
            c.clip(to: Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 7))
            c.fill(left, with: .color(Color(hex: "#f2e2c2")))
            c.fill(right, with: .color(Color(hex: "#eddcb9")))
            c.fill(bottom, with: .color(Color(hex: "#f0dfbd")))
        }
    }
}

private struct Flap: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// The round sticker that seals the flap: a balloon in the company's colours, no flame (`stickerSvg`).
private struct Sticker: View {
    let colors: [String]

    var body: some View {
        Canvas { c, size in
            let k = 66 / 64 * size.width / 80, o = (size.width - 66 * size.width / 80) / 2
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o + x * k, y: o + y * k) }
            func env(_ l: CGFloat, _ r: CGFloat, _ ml: CGFloat, _ mr: CGFloat, _ col: Color) {
                var path = Path()
                path.move(to: p(32, 6))
                path.addCurve(to: p(r, 22), control1: p(32 + (r - 32) * 0.625, 6), control2: p(r, 13))
                path.addCurve(to: p(mr, 39), control1: p(r, 30), control2: p(mr + (r - mr) * 0.4, 35))
                path.addLine(to: p(ml, 39))
                path.addCurve(to: p(l, 22), control1: p(ml - (ml - l) * 0.4, 35), control2: p(l, 30))
                path.addCurve(to: p(32, 6), control1: p(l, 13), control2: p(32 - (32 - l) * 0.625, 6))
                path.closeSubpath()
                c.fill(path, with: .color(col))
            }
            env(16, 48, 26, 38, Color(hex: colors.first ?? "#e5432f"))
            env(25, 39, 29, 35, Color(hex: colors.count > 1 ? colors[1] : "#ffc23d"))
            var ropes = Path()
            ropes.move(to: p(27, 39)); ropes.addLine(to: p(28.5, 47))
            ropes.move(to: p(37, 39)); ropes.addLine(to: p(35.5, 47))
            c.stroke(ropes, with: .color(Color(hex: "#6b4a26")), lineWidth: k)
            c.fill(Path(roundedRect: CGRect(x: p(27.5, 47).x, y: p(27.5, 47).y, width: 9 * k, height: 7 * k), cornerRadius: 1.2 * k), with: .color(Color(hex: "#8a5a2e")))
        }
        .background(Circle().fill(Color(hex: "#fffaf0")).shadow(color: .black.opacity(0.25), radius: 2, y: 2))
    }
}

/// The folded letter inside the envelope: parchment with two folds and a few lines of writing near the top.
private struct FoldedPaper: View {
    var body: some View {
        ZStack {
            Parchment(corner: 3)
            Canvas { c, size in
                let brown = Color(red: 120 / 255, green: 80 / 255, blue: 30 / 255)
                for f in [0.333, 0.666] as [CGFloat] {
                    c.fill(Path(CGRect(x: 0, y: size.height * f - 1, width: size.width, height: 1)), with: .color(brown.opacity(0.16)))
                    c.fill(Path(CGRect(x: 0, y: size.height * f, width: size.width, height: 1.2)), with: .color(.white.opacity(0.35)))
                }
                let x0 = size.width * 0.12, x1 = size.width * 0.84
                var y = size.height * 0.09
                while y < size.height * 0.29 {
                    c.fill(Path(CGRect(x: x0, y: y, width: (x1 - x0) * 0.7, height: 1.2)), with: .color(Color(red: 35 / 255, green: 42 / 255, blue: 92 / 255).opacity(0.28)))
                    c.fill(Path(CGRect(x: x0 + (x1 - x0) * 0.7, y: y, width: (x1 - x0) * 0.3, height: 1.2)),
                           with: .linearGradient(Gradient(colors: [Color(red: 35 / 255, green: 42 / 255, blue: 92 / 255).opacity(0.28), .clear]),
                                                 startPoint: CGPoint(x: x0 + (x1 - x0) * 0.7, y: y), endPoint: CGPoint(x: x1, y: y)))
                    y += 7
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Paper, photo, ink

/// Parchment: a warm ground, a lighter middle, a fine grain and darkened edges.
struct Parchment: View {
    var corner: CGFloat = 3
    /// A 220 pt tile of brown grain, made once.
    private static let grain: UIImage = {
        let size = CGSize(width: 220, height: 220)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            var rng = SystemRandomNumberGenerator()
            for _ in 0..<5200 {
                let x = CGFloat.random(in: 0..<220, using: &rng), y = CGFloat.random(in: 0..<220, using: &rng)
                let a = CGFloat.random(in: 0.04..<0.16, using: &rng)
                ctx.cgContext.setFillColor(UIColor(red: 0.45, green: 0.3, blue: 0.12, alpha: a).cgColor)
                ctx.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
    }()

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner)
        GeometryReader { geo in
            ZStack {
                Color(hex: "#f3e2bd")
                RadialGradient(colors: [Color(red: 1, green: 250 / 255, blue: 232 / 255).opacity(0.85), Color(red: 1, green: 250 / 255, blue: 232 / 255).opacity(0)],
                               center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: max(geo.size.width, geo.size.height) * 0.7)
                Image(uiImage: Self.grain).resizable(resizingMode: .tile)
                // darkened edges (the prototype's inset shadows)
                shape.stroke(Color(red: 140 / 255, green: 90 / 255, blue: 30 / 255).opacity(0.38), lineWidth: 34).blur(radius: 22)
                shape.stroke(Color(red: 120 / 255, green: 70 / 255, blue: 20 / 255).opacity(0.3), lineWidth: 8).blur(radius: 6)
            }
            .clipShape(shape)
        }
    }
}

/// The family's photo on a white border, taped at the four corners.
private struct TapedPhoto: View {
    let width: CGFloat

    var body: some View {
        Image("LetterPhoto")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 1))
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(Color.white)
            .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
            .overlay(alignment: .topLeading) { tape(-42).offset(x: -22, y: 2) }
            .overlay(alignment: .topTrailing) { tape(42).offset(x: 22, y: 2) }
            .overlay(alignment: .bottomLeading) { tape(42).offset(x: -22, y: -4) }
            .overlay(alignment: .bottomTrailing) { tape(-42).offset(x: 22, y: -4) }
            .frame(width: width)
            .rotationEffect(.degrees(-2.2))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(loc("letter.photoAlt"))
            .accessibilityAddTraits(.isImage)
    }

    private func tape(_ deg: Double) -> some View {
        Rectangle()
            .fill(Color(red: 247 / 255, green: 232 / 255, blue: 190 / 255).opacity(0.82))
            .overlay(alignment: .leading) { dotted }
            .overlay(alignment: .trailing) { dotted }
            .frame(width: 70, height: 22)
            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
            .rotationEffect(.degrees(deg))
    }

    private var dotted: some View {
        Rectangle()
            .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [2, 2]))
            .frame(width: 2)
    }
}

/// A small ink blot with a stray drop, the same shape every time.
private struct InkBlot: Shape {
    let seed: Int

    func path(in r: CGRect) -> Path {
        let radii: [CGFloat] = seed == 1 ? [1, 0.78, 0.95, 0.72, 0.98, 0.84, 0.9, 0.7] : [0.95, 0.85, 1, 0.74, 0.9, 0.8, 0.98, 0.76]
        let c = CGPoint(x: r.midX, y: r.midY), R = min(r.width, r.height) * 0.38
        let pts = radii.indices.map { i -> CGPoint in
            let a = Double(i) / Double(radii.count) * 2 * .pi
            return CGPoint(x: c.x + cos(a) * R * radii[i], y: c.y + sin(a) * R * radii[i])
        }
        var p = Path()
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
        p.move(to: mid(pts[pts.count - 1], pts[0]))
        for i in pts.indices { p.addQuadCurve(to: mid(pts[i], pts[(i + 1) % pts.count]), control: pts[i]) }
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: r.maxX - r.width * 0.16, y: r.minY + r.height * 0.06, width: r.width * 0.1, height: r.width * 0.1))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.08, y: r.maxY - r.height * 0.2, width: r.width * 0.07, height: r.width * 0.07))
        return p
    }
}

// MARK: - Sunrise glitter

/// v123.3 (`letterSparkles`): gold, peach, pink and white specks and four-point stars that float up and twinkle. A burst
/// when the envelope turns, a thin trail behind the rising sticker, a shower when the letter opens, then a few drifting
/// up while it is read. Not observed: the layer redraws every frame and steps it.
final class LetterSparkles {
    struct Speck {
        var x, y, vx, vy, life, max, size, phase: Double
        var color: Int
        var star: Bool
    }

    static let colors = ["#ffd27a", "#ffb36b", "#ff9ec4", "#fff6dc", "#ffe08a", "#ffc2a8"].map { Color(hex: $0) }
    var specks: [Speck] = []
    /// Specks a second: around the envelope, or rising from the bottom once the letter is open.
    var rate = 0.0
    var reading = false
    var stage = CGRect.zero
    var screenH: CGFloat = 800
    /// The rising sticker's path: when it started.
    var follow: Date?
    private var acc = 0.0
    private var last: Date?
    private var size = CGSize.zero

    private func add(_ x: Double, _ y: Double, _ speed: Double = 1) {
        let a = Double.random(in: 0..<(2 * .pi)), v = (20 + Double.random(in: 0..<90)) * speed
        specks.append(Speck(x: x, y: y, vx: cos(a) * v, vy: sin(a) * v - 25, life: 0, max: 1.4 + Double.random(in: 0..<1.6),
                            size: 1.4 + Double.random(in: 0..<2.4), phase: Double.random(in: 0..<6),
                            color: Int.random(in: 0..<Self.colors.count), star: Double.random(in: 0..<1) < 0.35))
    }

    func burst(_ n: Int, speed: Double = 1.4) {
        let cx = Double(stage.midX), cy = Double(stage.midY), w = Double(stage.width), h = Double(stage.height)
        for _ in 0..<n { add(cx + (Double.random(in: 0..<1) - 0.5) * w, cy + (Double.random(in: 0..<1) - 0.5) * h, speed) }
    }

    func rain(_ n: Int) {
        for _ in 0..<n {
            add(Double.random(in: 0..<max(1, Double(size.width))), -10 - Double.random(in: 0..<60), 0.3)
            specks[specks.count - 1].vy = 30 + Double.random(in: 0..<40)
        }
    }

    func followSticker() { follow = Date() }

    /// Where the sticker is now: from the flap's tip it rises 62% of the screen in 1.5 s, slowly at first.
    private func stickerPoint(_ now: Date) -> CGPoint? {
        guard let f = follow else { return nil }
        let t = min(1, now.timeIntervalSince(f) / 1.5), e = pow(t, 2.2)
        let x: Double = Double(stage.midX) + 18 * e
        let y: Double = Double(stage.minY) + Double(stage.height) * 0.6 - 8 - Double(screenH) * 0.62 * e
        return CGPoint(x: x, y: y)
    }

    func step(_ now: Date, _ size: CGSize) {
        self.size = size
        let dt = min(0.05, last.map { now.timeIntervalSince($0) } ?? 0)
        last = now
        acc += rate * dt
        while acc >= 1 {
            acc -= 1
            if reading {
                add(Double.random(in: 0..<max(1, Double(size.width))), Double(size.height) + 5, 0.4)
                specks[specks.count - 1].vy = -30 - Double.random(in: 0..<30)
            } else {
                burst(1, speed: 0.8)
            }
        }
        if let p = stickerPoint(now), Double.random(in: 0..<1) < 0.45 {
            add(Double(p.x) + (Double.random(in: 0..<1) - 0.5) * 40, Double(p.y) + 16, 0.5)
        }
        var i = specks.count - 1
        while i >= 0 {
            var p = specks[i]
            p.life += dt
            if p.life > p.max { specks.remove(at: i); i -= 1; continue }
            p.vx *= 1 - dt * 1.2
            p.vy = p.vy * (1 - dt * 1.2) - 18 * dt
            p.x += p.vx * dt
            p.y += p.vy * dt
            specks[i] = p
            i -= 1
        }
    }
}

private struct LetterSparkleLayer: View {
    let model: LetterSparkles

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { c, size in
                model.step(tl.date, size)
                c.blendMode = .plusLighter
                for p in model.specks {
                    let k = p.life / p.max, tw = 0.55 + 0.45 * sin(p.life * 9 + p.phase)
                    let al = min(1, p.life * 4) * (1 - k) * tw
                    let col = LetterSparkles.colors[p.color]
                    if p.star {
                        let s = p.size * 2.6
                        c.fill(Path(ellipseIn: CGRect(x: p.x - s * 1.1, y: p.y - s * 1.1, width: s * 2.2, height: s * 2.2)), with: .color(col.opacity(al * 0.3)))
                        var star = Path()
                        star.move(to: CGPoint(x: p.x, y: p.y - s))
                        star.addQuadCurve(to: CGPoint(x: p.x + s, y: p.y), control: CGPoint(x: p.x, y: p.y))
                        star.addQuadCurve(to: CGPoint(x: p.x, y: p.y + s), control: CGPoint(x: p.x, y: p.y))
                        star.addQuadCurve(to: CGPoint(x: p.x - s, y: p.y), control: CGPoint(x: p.x, y: p.y))
                        star.addQuadCurve(to: CGPoint(x: p.x, y: p.y - s), control: CGPoint(x: p.x, y: p.y))
                        c.fill(star, with: .color(col.opacity(al)))
                    } else {
                        let r = p.size * 0.7, g = p.size * 2.4
                        c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(col.opacity(al)))
                        c.fill(Path(ellipseIn: CGRect(x: p.x - g, y: p.y - g, width: g * 2, height: g * 2)), with: .color(col.opacity(al * 0.3)))
                    }
                }
            }
        }
    }
}
