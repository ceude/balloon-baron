import SwiftUI
import BalloonBaronCore

/// The current region's chapter goals. Barons get a crown and the way to the world map instead.
struct GoalsView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            WorldPageHeader(title: loc("goals.title")) { store.closePage() }
            ScrollView {
                if let s = store.state {
                    content(s)
                        .padding(16)
                }
            }
        }
        .background(Theme.paper.ignoresSafeArea())
    }

    @ViewBuilder
    private func content(_ s: GameState) -> some View {
        if s.isBaron() {
            baron(s)
        } else if let c = s.currentChapter {
            chapter(c, s)
        }
    }

    private func baron(_ s: GameState) -> some View {
        VStack(spacing: 14) {
            CrownIcon()
                .frame(width: 96, height: 72)
            Text(s.region.chapters.last?.title ?? "")
                .font(Theme.font(30, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(loc("goals.baronLead", s.region.title))
                .font(Theme.font(16))
                .foregroundStyle(Theme.ink2)
                .multilineTextAlignment(.center)
            BigButton(title: loc("goals.mapLink")) { store.page = .map }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private func chapter(_ c: Chapter, _ s: GameState) -> some View {
        let total = s.region.chapters.count
        let isLast = s.chapter == total - 1
        return VStack(alignment: .leading, spacing: 10) {
            if s.anyBaron {
                WorldPillButton(title: loc("goals.mapLink"), style: .light) { store.page = .map }
            }
            ChapterHeading(region: s.region, number: s.chapter + 1, total: total, title: c.title)
            ForEach(c.goals.indices, id: \.self) { i in
                ChapterGoalRow(goal: c.goals[i], state: s)
            }
            Text(isLast || c.reward == 0 ? loc("goals.baronHint", s.region.title) : loc("goals.reward", eur(c.reward)))
                .font(Theme.font(14))
                .foregroundStyle(Theme.ink2)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared by the world pages (goals, ceremony, merger, holding, map, problems)

/// Title row with a close button at the top of an office page.
struct WorldPageHeader: View {
    let title: String
    var dark = false
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(Theme.font(28, .heavy, condensed: true))
                .foregroundStyle(dark ? Theme.sun : Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(dark ? Color.white : Theme.ink)
                    .frame(width: 40, height: 40)
                    .background(dark ? Color.white.opacity(0.12) : Theme.line.opacity(0.6), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc("world.close"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

/// One chapter goal: tick, label, progress text and bar.
struct ChapterGoalRow: View {
    let goal: Goal
    let state: GameState
    /// In the ceremony every goal of the finished chapter shows done, whatever the numbers did since.
    var finished = false

    var body: some View {
        let done = finished || state.done(goal)
        let text = finished && !state.done(goal) ? loc("goals.finished") : state.progressText(goal)
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9)
                .fill(done ? Theme.green : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(done ? Theme.green : Color(hex: "#cfc6e0"), lineWidth: 2))
                .overlay {
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(goal.label(region: state.region))
                        .font(Theme.font(14, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 4)
                    Text(text)
                        .font(Theme.font(14, .bold, condensed: true))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                        .fixedSize()
                }
                WorldProgressBar(value: finished ? 1 : state.progress(goal), color: done ? Theme.green : Theme.coral)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
        // One element: the goal, then its progress ("3/5") and whether it's done.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(goal.label(region: state.region))
        .accessibilityValue(done && text != loc("goals.finished") ? text + ", " + loc("goals.finished") : text)
    }
}

struct WorldProgressBar: View {
    let value: Double
    var color: Color = Theme.coral

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule()
                    .fill(color)
                    .frame(width: g.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: 7)
    }
}

/// Small status label: "You're here", "Problem", "Baron"…
struct WorldTag: View {
    enum Kind { case green, yellow, red, neutral }
    let text: String
    let kind: Kind

    var body: some View {
        Text(text)
            .font(Theme.font(12, .bold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var foreground: Color {
        switch kind {
        case .green: Color(hex: "#145c34")
        case .yellow: Color(hex: "#6b4c00")
        case .red: Color(hex: "#8c2414")
        case .neutral: Theme.ink2
        }
    }

    private var background: Color {
        switch kind {
        case .green: Color(hex: "#dcf3e5")
        case .yellow: Color(hex: "#fff3cf")
        case .red: Color(hex: "#fde6e2")
        case .neutral: Color(hex: "#f1edf8")
        }
    }
}

/// Small action button on the light pages ("Go to region", "Decide").
struct WorldPillButton: View {
    enum Style { case ink, light, coral }
    let title: String
    var style: Style = .ink
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(16, .bold, condensed: true))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 14)
                .frame(minHeight: 38)
                .foregroundStyle(style == .light ? Theme.ink : Color.white)
                .background(background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(style == .light ? Theme.line : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }

    private var background: Color {
        switch style {
        case .ink: Theme.ink
        case .light: Color.white
        case .coral: Theme.coral
        }
    }
}

/// Dimmed backdrop with a centered paper card, used by the ceremony, merger and problem popups.
/// Like `ModalCard`, `onClose` puts a ✕ in the top right corner.
struct WorldPopup<Content: View>: View {
    let topBar: Color?
    let onClose: (() -> Void)?
    /// Sits low with a light veil, so what happens in the town stays in view above it.
    let bottom: Bool
    let content: Content

    init(topBar: Color? = nil, onClose: (() -> Void)? = nil, bottom: Bool = false, @ViewBuilder content: () -> Content) {
        self.topBar = topBar
        self.onClose = onClose
        self.bottom = bottom
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(bottom ? 0.12 : 0.45).ignoresSafeArea()
            GeometryReader { geo in
                ScrollView {
                    card
                        .frame(maxWidth: 420)
                        .padding(.horizontal, 16)
                        .padding(.vertical, bottom ? 8 : 16)
                        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: bottom ? .bottom : .center)
                }
                .defaultScrollAnchor(bottom ? .bottom : .top)
            }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.paper)
        .overlay(alignment: .top) {
            if let topBar {
                topBar.frame(height: 6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(alignment: .topTrailing) {
            if let onClose { CardCloseX(action: onClose) }
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.35), radius: 20, y: 10)
    }
}

/// The baron's crown from the prototype (64×48 artboard).
struct CrownIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 64, sy = size.height / 48
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
            func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (x - r) * sx, y: (y - r) * sy, width: 2 * r * sx, height: 2 * r * sy))
            }
            var crown = Path()
            crown.move(to: p(6, 40))
            for (x, y) in [(2, 12), (18, 24), (32, 4), (46, 24), (62, 12), (58, 40)] as [(CGFloat, CGFloat)] {
                crown.addLine(to: p(x, y))
            }
            crown.closeSubpath()
            ctx.fill(crown, with: .color(Color(hex: "#ffc23d")))
            ctx.stroke(crown, with: .color(Color(hex: "#c98a00")), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            let band = CGRect(x: 6 * sx, y: 38 * sy, width: 52 * sx, height: 7 * sy)
            ctx.fill(Path(roundedRect: band, cornerRadius: 2), with: .color(Color(hex: "#e0a400")))
            ctx.fill(dot(32, 22, 4), with: .color(Theme.coral))
            ctx.fill(dot(16, 28, 3), with: .color(Color(hex: "#3ad0c0")))
            ctx.fill(dot(48, 28, 3), with: .color(Color(hex: "#3ad0c0")))
        }
        .accessibilityHidden(true)
    }
}

/// A chapter's heading, readable at a glance: the region, a big "Chapter 2/4", then the chapter's name.
struct ChapterHeading: View {
    let region: RegionID
    let number: Int
    let total: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(region.title)
                .font(Theme.font(14, .heavy, condensed: true))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Theme.ink2)
            Text(loc("goals.chapterBig", num(number), num(total)))
                .font(Theme.font(44, .heavy, condensed: true))
                .foregroundStyle(Theme.coral)
            Text(title)
                .font(Theme.font(28, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
