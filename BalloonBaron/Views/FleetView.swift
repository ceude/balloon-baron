import SwiftUI
import BalloonBaronCore

/// Building blocks shared by the office pages (fleet, market).
enum FleetUI {
    /// Sky background, title bar with cash and close button, scrolling content.
    struct PageFrame<Content: View>: View {
        @Environment(GameStore.self) private var store
        let title: String
        let cash: Int
        let close: () -> Void
        let content: Content

        init(title: String, cash: Int, close: @escaping () -> Void, @ViewBuilder content: () -> Content) {
            self.title = title
            self.cash = cash
            self.close = close
            self.content = content()
        }

        var body: some View {
            ZStack {
                Theme.sky.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                content
                                PageDoneButton(action: close)
                            }
                            .padding(16)
                        }
                        .onAppear { store.scrollToSection(proxy) }
                    }
                }
            }
        }

        private var header: some View {
            HStack(spacing: 10) {
                Text(title)
                    .font(Theme.font(30, .heavy, condensed: true))
                    .foregroundStyle(Color.white)
                Spacer()
                Text(eur(cash))
                    .font(Theme.font(17, .bold, condensed: true))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.glass, in: Capsule())
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.glass, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(loc("fleetPage.close"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }

    /// Paper section with a heading.
    struct Card<Content: View>: View {
        let title: String
        let content: Content

        init(_ title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(Theme.font(22, .heavy, condensed: true))
                    .foregroundStyle(Theme.ink)
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    /// White row inside a card.
    struct Item<Content: View>: View {
        var highlight = false
        let content: Content

        init(highlight: Bool = false, @ViewBuilder content: () -> Content) {
            self.highlight = highlight
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(highlight ? Color(hex: "#fff3e8") : Color.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(highlight ? Theme.coral : Theme.line, lineWidth: highlight ? 2 : 1))
        }
    }

    struct SmallButton: View {
        let title: String
        var note: String? = nil
        var ghost = false
        var disabled = false
        /// The current choice: a clear green "✓ title" instead of a faded button.
        var selected = false
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 1) {
                    Text(selected ? "✓ " + title : title)
                        .font(Theme.font(15, .heavy, condensed: true))
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                    if let note, !selected {
                        Text(note).font(Theme.font(12.5, .bold)).opacity(0.9)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 40)
                .foregroundStyle(selected ? Color(hex: "#1b7d47") : ghost ? Theme.ink : disabled ? Theme.offText : Color.white)
                .background(selected ? Theme.green.opacity(0.14) : ghost ? Color.white : disabled ? Theme.offFill : Theme.coral, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Theme.green.opacity(0.5) : ghost ? Theme.line : Color.clear, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .disabled(disabled || selected)
            .opacity(disabled && !selected && ghost ? 0.55 : 1)
            .accessibilityAddTraits(selected ? .isSelected : [])
        }
    }

    struct Tag: View {
        let text: String
        var color: Color = Theme.ink2

        var body: some View {
            Text(text)
                .font(Theme.font(12, .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(color, in: Capsule())
        }
    }

    struct Hint: View {
        let text: String
        init(_ text: String) { self.text = text }

        var body: some View {
            Text(text)
                .font(Theme.font(13))
                .foregroundStyle(Theme.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    struct Title: View {
        let text: String
        init(_ text: String) { self.text = text }

        var body: some View {
            Text(text).font(Theme.font(18, .heavy, condensed: true)).foregroundStyle(Theme.ink)
        }
    }

    struct Detail: View {
        let text: String
        var color: Color = Theme.ink2
        init(_ text: String, color: Color = Theme.ink2) {
            self.text = text
            self.color = color
        }

        var body: some View {
            Text(text)
                .font(Theme.font(14))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Buttons that wrap onto the next line on narrow screens.
    struct ButtonGrid<Content: View>: View {
        let content: Content
        init(@ViewBuilder content: () -> Content) { self.content = content() }

        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], alignment: .leading, spacing: 8) { content }
        }
    }

    /// Bottom sheet frame for pickers: title, lead text, rows and a close button.
    struct Sheet<Content: View>: View {
        let title: String
        let lead: String
        let close: () -> Void
        let content: Content

        init(title: String, lead: String, close: @escaping () -> Void, @ViewBuilder content: () -> Content) {
            self.title = title
            self.lead = lead
            self.close = close
            self.content = content()
        }

        var body: some View {
            ZStack {
                Theme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(title)
                            .font(Theme.font(28, .heavy, condensed: true))
                            .foregroundStyle(Theme.ink)
                        Detail(lead)
                        content
                        BigButton(title: loc("fleetPage.close"), action: close)
                            .padding(.top, 6)
                    }
                    .padding(20)
                    .overlay(alignment: .topTrailing) { CardCloseX(action: close) }
                }
            }
        }
    }
}

/// Wraps a balloon id for `.sheet(item:)`.
private struct BalloonPick: Identifiable {
    let id: Int
}

/// The fleet page's balloon filters (`FLEET_FILTERS`). Size filters and empty ones are hidden when nothing matches.
private enum FleetFilter: String, CaseIterable {
    case all, ready, issue, worn, S, M, L, XL

    func includes(_ b: Balloon, _ s: GameState) -> Bool {
        switch self {
        case .all: return true
        case .ready: return s.status(b) == .ok
        case .issue: return s.status(b) != .ok || s.condition(b) < 0.3
        case .worn: return s.condition(b) < 0.6
        case .S: return b.size == .S
        case .M: return b.size == .M
        case .L: return b.size == .L
        case .XL: return b.size == .XL
        }
    }
}

/// The fleet page stays readable with twenty balloons: a summary, status filters with counts, then one compact line
/// per balloon (flagship first, then the ones that need you, then by size). A line opens the balloon's card with
/// everything else: sponsor, design, equipment, envelope, flagship, sell. Port of prototype v107 `tabFleet`.
struct FleetView: View {
    @Environment(GameStore.self) private var store
    @State private var filter: FleetFilter = .all
    @State private var cardPick: BalloonPick?
    @State private var studioOpen = false

    var body: some View {
        if let game = store.game {
            FleetUI.PageFrame(title: loc("fleetPage.title"), cash: game.state.cash, close: { store.closePage() }) {
                balloonsCard(game)
                shopCard(game.state)
                workshopCard(game)
                    .id(PageSection.workshop)
            }
            .sheet(item: $cardPick) { pick in
                BalloonCardSheet(balloonID: pick.id).environment(store)
            }
            .sheet(isPresented: $studioOpen) {
                DesignStudioView().environment(store)
            }
        }
    }

    // MARK: Your balloons

    private func balloonsCard(_ game: Game) -> some View {
        let s = game.state
        // A filter that no longer matches anything (the last worn envelope was renewed) falls back to all.
        let current = filter == .all || s.balloons.contains(where: { filter.includes($0, s) }) ? filter : .all
        let list = s.balloons.filter { current.includes($0, s) }.sorted { a, b in
            let ra = rank(a, s), rb = rank(b, s)
            if ra != rb { return ra < rb }
            if a.size.capacity != b.size.capacity { return a.size.capacity > b.size.capacity }
            return a.name.localizedCompare(b.name) == .orderedAscending
        }
        let worn = game.wornBalloons.count, cost = game.renewWornCost
        return FleetUI.Card(loc("fleetPage.yours")) {
            summary(s)
            chips(s, current)
            if worn > 0 {
                FleetUI.SmallButton(title: loc("fleet.renewAll", num(worn), eur(cost)), ghost: true, disabled: s.cash < cost) {
                    store.act { _ = $0.renewWornEnvelopes() }
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.element.id) { i, b in
                    if i > 0 { Rectangle().fill(Theme.line).frame(height: 1.5).padding(.leading, 52) }
                    row(b, s)
                }
                if list.isEmpty {
                    FleetUI.Hint(loc("fleet.empty")).frame(maxWidth: .infinity).padding(14)
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 2))
            FleetUI.Hint(loc("fleetPage.hintEnvelope", num(s.envelopeLife)))
            FleetUI.Hint(loc("fleetPage.hintPilots"))
        }
    }

    private func summary(_ s: GameState) -> some View {
        let seats = s.balloons.reduce(0) { $0 + $1.size.capacity }, up = s.balloons.reduce(0) { $0 + $1.size.upkeep }
        let ready = s.balloons.filter { s.status($0) == .ok }.count
        return HStack(spacing: 6) {
            tile(num(s.balloons.count), loc("fleet.sum.balloons"))
            tile(num(seats), loc("fleet.sum.seats"))
            tile(num(ready), loc("fleet.sum.ready"))
            tile(eur(up), loc("fleet.sum.upkeep"))
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(Theme.font(20, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(Theme.font(11, .semibold))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 2))
        .accessibilityElement(children: .combine)
    }

    private func chips(_ s: GameState, _ current: FleetFilter) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FleetFilter.allCases, id: \.self) { f in
                    let n = s.balloons.filter { f.includes($0, s) }.count
                    if f == .all || n > 0 {
                        let on = f == current
                        Button { filter = f } label: {
                            HStack(spacing: 4) {
                                Text(loc("fleet.f.\(f.rawValue)")).foregroundStyle(on ? Color.white : Theme.ink)
                                Text(num(n)).foregroundStyle(on ? Color(hex: "#cfc8ff") : f == .issue ? Theme.red : Theme.ink2)
                            }
                            .font(Theme.font(13, .bold))
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(on ? Theme.ink : Color.white, in: Capsule())
                            .overlay(Capsule().stroke(on ? Color.clear : Theme.line, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    /// Flagship first, then red, orange, yellow and green.
    private func rank(_ b: Balloon, _ s: GameState) -> Int { (b.id == s.flagship ? 0 : 10) + rowState(b, s).level }

    /// `fleetState(b)`: how urgent the balloon is (0 red … 3 green), its dot color and a short status.
    private func rowState(_ b: Balloon, _ s: GameState) -> (level: Int, color: Color, text: String) {
        let orange = Color(hex: "#ff8a3d")
        switch s.status(b) {
        case .damaged: return (0, Theme.red, loc("fleetPage.status.damaged", num(b.damagedUntil - s.day)))
        case .worn: return (0, Theme.red, loc("fleet.row.worn"))
        case .banned: return (0, Theme.red, loc("fleet.row.banned"))
        case .strike: return (1, orange, loc("fleetPage.status.strike"))
        case .noPilot: return (1, orange, loc("fleet.row.noPilot"))
        case .licenseHold: return (1, orange, loc("fleet.row.licenseHold"))
        case .late: return (1, orange, loc("fleetPage.status.late"))
        case .chartered: return (3, Theme.green, loc("fleetPage.status.chartered"))
        case .ok:
            if s.condition(b) < 0.3 { return (2, Theme.yellow, loc("fleet.row.readyWorn")) }
            if !b.fly { return (3, Theme.ink2, loc("fleetPage.status.resting")) }
            if s.isSelf(b) { return (3, Theme.green, loc("fleet.row.readyYou")) }
            let first = s.pilot(of: b).map { String($0.name.split(separator: " ").first ?? Substring($0.name)) } ?? ""
            return (3, Theme.green, loc("fleet.row.ready", first))
        }
    }

    private func row(_ b: Balloon, _ s: GameState) -> some View {
        let st = rowState(b, s), cond = s.condition(b)
        let ring: Color = cond < 0.3 ? Theme.red : cond < 0.6 ? Theme.yellow : Theme.green
        return Button { cardPick = BalloonPick(id: b.id) } label: {
            HStack(spacing: 10) {
                DesignBalloon(colors: s.colors, design: s.design(of: b))
                    .frame(width: 30, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(b.title)
                            .font(Theme.font(17, .heavy, condensed: true))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        if b.id == s.flagship {
                            Text("★").font(Theme.font(14, .bold)).foregroundStyle(Theme.sun)
                        }
                        if s.isSelf(b) {
                            Text(loc("fleet.row.youFly"))
                                .font(Theme.font(10.5, .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(Theme.coral, in: RoundedRectangle(cornerRadius: 8))
                                .fixedSize()
                        }
                        Text(b.size.rawValue + " · " + num(b.size.capacity))
                            .font(Theme.font(11, .bold))
                            .foregroundStyle(Theme.ink2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Theme.line.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                            .fixedSize()
                        if let ad = b.ad {
                            Circle().fill(Color(hex: ad.colors.bg)).frame(width: 9, height: 9)
                        }
                        if b.burners > 1 {
                            Text("×" + num(b.burners)).font(Theme.font(11, .heavy)).foregroundStyle(Color(hex: "#d9641f")).fixedSize()
                        }
                    }
                    HStack(spacing: 5) {
                        Circle().fill(st.color).frame(width: 8, height: 8)
                        Text(st.text)
                            .font(Theme.font(12.5, .semibold))
                            .foregroundStyle(st.level < 2 ? Theme.ink : Theme.ink2)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                Spacer(minLength: 4)
                ZStack {
                    Circle().stroke(Theme.line, lineWidth: 4)
                    Circle().trim(from: 0, to: CGFloat(cond))
                        .stroke(ring, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(num(Int((cond * 100).rounded())))
                        .font(Theme.font(10.5, .heavy))
                        .foregroundStyle(Theme.ink)
                }
                .frame(width: 32, height: 32)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.ink2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loc("fleet.row.a11y", b.title, st.text, percent(cond)))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Shop

    private func shopCard(_ s: GameState) -> some View {
        FleetUI.Card(loc("fleetPage.shop")) {
            ForEach(BalloonSize.shop, id: \.self) { z in
                shopRow(z, s)
            }
            if !s.balloons.contains(where: { $0.size == .XL }) {
                xlRow(s)
            }
        }
    }

    private func specs(_ z: BalloonSize) -> String {
        loc("fleetPage.shopSpecs", num(z.capacity), z.risk.formatted(.number.precision(.fractionLength(0...2))), eur(z.upkeep), eur(z.fuel))
    }

    private func shopRow(_ z: BalloonSize, _ s: GameState) -> some View {
        FleetUI.Item {
            HStack(alignment: .center, spacing: 12) {
                DesignBalloon(colors: ["#cfc8dd", "#ffffff"])
                    .frame(width: 38, height: 48)
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(z.title)
                    FleetUI.Detail(specs(z))
                }
                Spacer(minLength: 4)
                FleetUI.SmallButton(title: eur(z.cost), disabled: s.cash < z.cost) {
                    store.act { _ = $0.buyBalloon(z) }
                }
                .frame(width: 110)
            }
        }
    }

    private func xlRow(_ s: GameState) -> some View {
        let z = BalloonSize.XL
        return FleetUI.Item {
            HStack(alignment: .top, spacing: 12) {
                DesignBalloon(colors: [s.colors.first ?? "#ff5e3a", "#ffd27a"])
                    .frame(width: 38, height: 48)
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(s.region.xlName)
                    FleetUI.Detail(z.title + " · " + specs(z))
                    FleetUI.Detail(loc("fleetPage.xlDesc"))
                }
            }
            FleetUI.SmallButton(title: eur(z.cost), disabled: s.cash < z.cost) {
                store.act { _ = $0.buyBalloon(z) }
            }
        }
    }

    // MARK: Workshop

    private func workshopCard(_ game: Game) -> some View {
        let s = game.state
        return FleetUI.Card(loc("fleetPage.workshop")) {
            if s.workshopDay == nil {
                FleetUI.Item {
                    FleetUI.Title(loc("fleetPage.workshopBuild"))
                    FleetUI.Detail(loc("fleetPage.workshopDesc"))
                    FleetUI.SmallButton(title: eur(Studio.workshopCost), disabled: s.cash < Studio.workshopCost) {
                        store.act { _ = $0.buildWorkshop() }
                    }
                }
            } else {
                if s.designs.isEmpty {
                    FleetUI.Hint(loc("fleetPage.noDesigns"))
                }
                ForEach(s.designs) { d in
                    designRow(d, game)
                }
                BigButton(title: loc("fleetPage.newDesign")) { studioOpen = true }
            }
        }
    }

    private func designRow(_ d: Design, _ game: Game) -> some View {
        let s = game.state
        let fresh = game.freshness(d)
        let faded = Int((fresh * 100).rounded()) <= 20
        let count = s.balloons.filter { $0.design == d.id }.count
        return FleetUI.Item {
            HStack(spacing: 12) {
                DesignBalloon(colors: d.colors, design: d)
                    .frame(width: 44, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(d.title)
                    FleetUI.Detail(loc(faded ? "fleetPage.designLineFaded" : "fleetPage.designLine", num(d.score), percent(fresh), num(count)))
                }
            }
        }
    }
}

/// A balloon's card (`balloonCard`): what the old fleet row showed, with its buttons and pickers.
private struct BalloonCardSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let balloonID: Int
    @State private var adPick: BalloonPick?
    @State private var designPick: BalloonPick?
    @State private var equipPick: BalloonPick?
    @State private var renamePick: BalloonPick?

    var body: some View {
        if let game = store.game, let b = game.state.balloon(balloonID) {
            FleetUI.Sheet(title: b.title, lead: b.size.title + " · " + loc("fleetPage.specs", num(b.size.capacity), eur(b.size.upkeep), eur(b.size.fuel)),
                          close: { dismiss() }) {
                balloonRow(b, game)
            }
            .sheet(item: $adPick) { pick in
                AdPicker(balloonID: pick.id).environment(store)
            }
            .sheet(item: $designPick) { pick in
                DesignPicker(balloonID: pick.id).environment(store)
            }
            .sheet(item: $equipPick) { pick in
                EquipmentPicker(balloonID: pick.id).environment(store)
            }
            .sheet(item: $renamePick) { pick in
                RenameSheet(balloonID: pick.id).environment(store)
            }
        }
    }

    private func balloonRow(_ b: Balloon, _ game: Game) -> some View {
        let s = game.state
        return FleetUI.Item {
            HStack(alignment: .top, spacing: 12) {
                DesignBalloon(colors: s.colors, design: s.design(of: b))
                    .frame(width: 44, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    if s.isSelf(b) {
                        FleetUI.Tag(text: loc("fleet.row.youFly"), color: Theme.coral)
                    } else if b.id == s.flagship {
                        FleetUI.Tag(text: "★ " + loc("fleetPage.flagship"), color: Theme.green)
                    }
                    if b.used == true {
                        FleetUI.Tag(text: loc("fleetPage.used"), color: Theme.yellow)
                    }
                    if let p = pilotText(b, s) {
                        FleetUI.Detail(p, color: Theme.ink)
                    }
                    statusLine(b, s)
                    conditionBar(b, s)
                }
            }
            extrasRow(b, s)
            actionsRow(b, game)
        }
    }

    private func pilotText(_ b: Balloon, _ s: GameState) -> String? {
        if s.isSelf(b) { return loc("fleetPage.pilotYou") }
        if let p = s.pilot(of: b) { return loc("fleetPage.pilot", p.name, p.level.title) }
        return nil
    }

    private func statusLine(_ b: Balloon, _ s: GameState) -> some View {
        let text: String
        let color: Color
        switch s.status(b) {
        case .ok:
            text = loc(b.fly ? "fleetPage.status.ok" : "fleetPage.status.resting")
            color = b.fly ? Theme.green : Theme.ink2
        case .banned:
            text = loc("fleetPage.status.banned")
            color = Theme.red
        case .damaged:
            text = loc("fleetPage.status.damaged", num(b.damagedUntil - s.day))
            color = Theme.red
        case .worn:
            text = loc("fleetPage.status.worn")
            color = Theme.red
        case .noPilot:
            text = loc("fleetPage.status.noPilot")
            color = Theme.yellow
        case .licenseHold:
            text = loc("fleetPage.status.licenseHold")
            color = Theme.yellow
        case .chartered:
            text = loc("fleetPage.status.chartered")
            color = Theme.green
        case .late:
            text = loc("fleetPage.status.late")
            color = Theme.yellow
        case .strike:
            text = loc("fleetPage.status.strike")
            color = Theme.red
        }
        return Text(text)
            .font(Theme.font(13, .bold))
            .foregroundStyle(color)
    }

    private func conditionBar(_ b: Balloon, _ s: GameState) -> some View {
        let cond = s.condition(b)
        let left = max(0, s.envelopeLife - Int(b.flights.rounded(.up)))
        let color: Color = cond < 0.3 ? Theme.red : cond < 0.6 ? Theme.yellow : Theme.green
        let label = loc(cond < 0.3 ? "fleetPage.envelopeWorn" : "fleetPage.envelope", percent(cond), num(left))
        return VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Theme.font(12, .semibold))
                .foregroundStyle(Theme.ink2)
            Capsule()
                .fill(Theme.line)
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { g in
                        Capsule().fill(color).frame(width: g.size.width * CGFloat(cond))
                    }
                }
        }
    }

    /// Sponsor and design buttons.
    private func extrasRow(_ b: Balloon, _ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                renamePick = BalloonPick(id: b.id)
            } label: {
                chip(dot: Color(hex: "#9b7be0"), text: loc("fleetPage.nameBtn", b.title))
            }
            .buttonStyle(.plain)
            Button {
                adPick = BalloonPick(id: b.id)
            } label: {
                chip(dot: b.ad.map { Color(hex: $0.colors.bg) } ?? Theme.line,
                     text: b.ad.map { loc("fleetPage.adOn", $0.title, eur($0.pay(for: b.size))) } ?? loc("fleetPage.adNone"))
            }
            .buttonStyle(.plain)
            Button {
                equipPick = BalloonPick(id: b.id)
            } label: {
                chip(dot: Color(hex: "#ff8a3d"),
                     text: loc("equip.burners.\(b.burners)") + (b.hasTurningVent ? " · " + loc("equip.ventShort") : ""))
            }
            .buttonStyle(.plain)
            if !s.designs.isEmpty { // bazaar designs work without the workshop
                let d = s.design(of: b)
                Button {
                    designPick = BalloonPick(id: b.id)
                } label: {
                    chip(dot: Color(hex: d?.colors.first ?? s.colors.first ?? "#ff5e3a"),
                         text: loc("fleetPage.designBtn", d?.title ?? loc("fleetPage.companyColors")))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func chip(dot: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(dot).frame(width: 12, height: 12)
            Text(text)
                .font(Theme.font(13, .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.ink2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.line.opacity(0.45), in: Capsule())
    }

    private func actionsRow(_ b: Balloon, _ game: Game) -> some View {
        let s = game.state
        let renew = game.renewCost(b)
        let sale = game.sellValue(b)
        return FleetUI.ButtonGrid {
            if s.condition(b) < 0.6 {
                FleetUI.SmallButton(title: loc("fleetPage.renew", eur(renew)), disabled: s.cash < renew) {
                    store.act { _ = $0.renewEnvelope(b.id) }
                }
            }
            // v111: pick the balloon you fly yourself right here; it becomes the flagship.
            if !s.isSelf(b) {
                let down = s.status(b) == .damaged || s.status(b) == .worn
                FleetUI.SmallButton(title: loc("fleetPage.flyMyself"), disabled: down) {
                    store.act { _ = $0.flyMyself(b.id) }
                }
            }
            if b.id != s.flagship && !s.flyingSelf {
                FleetUI.SmallButton(title: loc("fleetPage.makeFlagship"), ghost: true) {
                    store.act { $0.makeFlagship(b.id) }
                }
            }
            if s.balloons.count > 1 {
                FleetUI.SmallButton(title: loc("fleetPage.sell", eur(sale)), ghost: true) {
                    store.act { _ = $0.sellBalloon(b.id) }
                    dismiss()
                }
            }
        }
    }

}

// MARK: - Pickers

/// Your own name for a balloon (`renameCard`).
private struct RenameSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let balloonID: Int
    @State private var text = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        FleetUI.Sheet(title: loc("rename.title"), lead: loc("rename.lead", num(Rules.balloonNameMax)), close: { dismiss() }) {
            TextField(loc("rename.placeholder"), text: $text)
                .font(Theme.font(18, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 2))
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(save)
                .onChange(of: text) { _, v in if v.count > Rules.balloonNameMax { text = String(v.prefix(Rules.balloonNameMax)) } }
            if let error {
                Text(error).font(Theme.font(13, .bold)).foregroundStyle(Theme.red)
            }
            Button(loc("rename.save"), action: save)
                .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
        }
        .onAppear {
            text = store.state?.balloon(balloonID)?.title ?? ""
            focused = true
        }
    }

    private func save() {
        if text.trimmingCharacters(in: .whitespaces) == store.state?.balloon(balloonID)?.title { dismiss(); return }
        var r = Game.RenameResult.empty
        store.act { r = $0.renameBalloon(balloonID, text) }
        switch r {
        case .ok: SoundEngine.shared.play(.coin); dismiss()
        case .empty: error = loc("rename.empty")
        case .taken: error = loc("rename.taken")
        }
    }
}

/// Sponsor choice for one balloon (`openAdPicker`).
private struct AdPicker: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let balloonID: Int

    var body: some View {
        if let s = store.state, let b = s.balloon(balloonID) {
            FleetUI.Sheet(title: loc("fleetPage.adTitle", b.title), lead: loc("fleetPage.adLead"), close: { dismiss() }) {
                noneRow(b)
                ForEach(Sponsor.allCases, id: \.self) { sp in
                    sponsorRow(sp, b)
                }
            }
        }
    }

    private func noneRow(_ b: Balloon) -> some View {
        let current = b.ad == nil
        return FleetUI.Item {
            HStack(spacing: 12) {
                badge(bg: Theme.line, fg: Theme.ink2, text: "–")
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(loc("fleetPage.adNoneTitle"))
                    FleetUI.Detail(loc("fleetPage.adNoneDesc"))
                }
                Spacer(minLength: 4)
                FleetUI.SmallButton(title: loc(current ? "fleetPage.selected" : "fleetPage.choose"), selected: current) {
                    choose(nil, b)
                }
                .frame(width: 104)
            }
        }
    }

    private func sponsorRow(_ sp: Sponsor, _ b: Balloon) -> some View {
        let current = b.ad == sp
        let ok = sp.allowed(on: b.size)
        let hit = Sponsor.allCases.firstIndex(of: sp) ?? 0
        let detail = ok
            ? loc("fleetPage.adPay", eur(sp.pay(for: b.size)), loc("fleetPage.hit.\(hit)"))
            : loc(sp.minSize == .L ? "fleetPage.adMinL" : "fleetPage.adMinM")
        let label = current ? "fleetPage.selected" : ok ? "fleetPage.choose" : "fleetPage.locked"
        return FleetUI.Item {
            HStack(spacing: 12) {
                badge(bg: Color(hex: sp.colors.bg), fg: Color(hex: sp.colors.fg), text: String(sp.title.prefix(1)))
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(sp.title)
                    FleetUI.Detail(detail)
                }
                Spacer(minLength: 4)
                FleetUI.SmallButton(title: loc(label), disabled: !ok, selected: current) {
                    choose(sp, b)
                }
                .frame(width: 104)
            }
        }
        .opacity(ok ? 1 : 0.55)
    }

    private func badge(bg: Color, fg: Color, text: String) -> some View {
        Text(text)
            .font(Theme.font(18, .heavy, condensed: true))
            .foregroundStyle(fg)
            .frame(width: 40, height: 40)
            .background(bg, in: RoundedRectangle(cornerRadius: 10))
    }

    private func choose(_ sp: Sponsor?, _ b: Balloon) {
        store.act { _ = $0.setAd(b.id, sp) }
        dismiss()
    }
}

/// A balloon's equipment: one, two or three burners, and the turning vent. Sold on safety (`equipCard`).
private struct EquipmentPicker: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let balloonID: Int

    var body: some View {
        if let game = store.game, let b = game.state.balloon(balloonID) {
            FleetUI.Sheet(title: loc("equip.title"), lead: b.title, close: { dismiss() }) {
                ForEach(1...3, id: \.self) { n in
                    burnerRow(n, b, game)
                }
                ventRow(b, game)
            }
        }
    }

    private func percentOff(_ k: Double) -> String { num(Int(((1 - k) * 100).rounded())) }
    private func percentUp(_ k: Double) -> String { num(Int(((k - 1) * 100).rounded())) }

    private func burnerRow(_ n: Int, _ b: Balloon, _ game: Game) -> some View {
        let have = b.burners >= n, next = b.burners + 1 == n
        let detail = n == 1 ? loc("equip.single.d")
            : loc(n == 2 ? "equip.double.d" : "equip.triple.d", percentOff(Burners.risk[n - 1]), percentUp(Burners.heat[n - 1]))
        return FleetUI.Item(highlight: next) {
            FleetUI.Title((have ? "✓ " : "") + loc("equip.burners.\(n)"))
            FleetUI.Detail(detail)
            if next, let cost = game.burnerCost(b) {
                FleetUI.SmallButton(title: loc("equip.fit", eur(cost)), disabled: game.state.cash < cost) {
                    store.act { _ = $0.addBurner(b.id) }
                }
            }
        }
        .opacity(have || next ? 1 : 0.55)
    }

    private func ventRow(_ b: Balloon, _ game: Game) -> some View {
        let cost = game.turningVentCost(b)
        return FleetUI.Item(highlight: !b.hasTurningVent) {
            FleetUI.Title((b.hasTurningVent ? "✓ " : "") + loc("equip.vent"))
            FleetUI.Detail(loc("equip.vent.d", percentOff(Burners.turningVentRisk)))
            if !b.hasTurningVent {
                FleetUI.SmallButton(title: loc("equip.fit", eur(cost)), disabled: game.state.cash < cost) {
                    store.act { _ = $0.fitTurningVent(b.id) }
                }
            }
        }
    }
}

/// Repaint one balloon with company colours or a workshop design (`openDesignPicker`).
private struct DesignPicker: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let balloonID: Int

    var body: some View {
        if let game = store.game, let b = game.state.balloon(balloonID) {
            FleetUI.Sheet(title: loc("fleetPage.designPickTitle", b.name), lead: loc("fleetPage.designPickLead", eur(Studio.reskinCost)) + " " + loc("fleetPage.designPickFree"),
                          close: { dismiss() }) {
                companyRow(b, game.state)
                ForEach(game.state.designs) { d in
                    designRow(d, b, game)
                }
            }
        }
    }

    private func companyRow(_ b: Balloon, _ s: GameState) -> some View {
        let current = b.design == nil
        return FleetUI.Item {
            HStack(spacing: 12) {
                DesignBalloon(colors: s.colors)
                    .frame(width: 44, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(loc("fleetPage.companyColors"))
                    FleetUI.Detail(loc("fleetPage.companyColorsDesc"))
                }
                Spacer(minLength: 4)
                paintButton(current: current, cash: s.cash) { paint(nil, b) }
            }
        }
    }

    private func designRow(_ d: Design, _ b: Balloon, _ game: Game) -> some View {
        let current = b.design == d.id, cost = game.paintCost(d.id)
        return FleetUI.Item {
            HStack(spacing: 12) {
                DesignBalloon(colors: d.colors, design: d)
                    .frame(width: 44, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(d.title)
                    FleetUI.Detail(loc("fleetPage.designStats", num(d.score), percent(game.freshness(d))))
                }
                Spacer(minLength: 4)
                paintButton(current: current, cash: game.state.cash, cost: cost) { paint(d.id, b) }
            }
        }
    }

    private func paintButton(current: Bool, cash: Int, cost: Int = Studio.reskinCost, action: @escaping () -> Void) -> some View {
        // "Paint" and its price underneath, also when it costs nothing.
        FleetUI.SmallButton(title: loc(current ? "fleetPage.selected" : "fleetPage.paint"), note: current ? nil : eur(cost),
                            disabled: cash < cost, selected: current, action: action)
            .frame(width: 104)
    }

    private func paint(_ design: Int?, _ b: Balloon) {
        store.act { _ = $0.paint(b.id, design: design) }
        dismiss()
    }
}
