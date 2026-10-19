import SwiftUI
import BalloonBaronCore

/// Building blocks shared by the office pages (fleet, market).
enum FleetUI {
    /// Sky background, title bar with cash and close button, scrolling content.
    struct PageFrame<Content: View>: View {
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
                    ScrollView {
                        VStack(spacing: 14) { content }
                            .padding(16)
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
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 1) {
                    Text(title)
                        .font(Theme.font(15, .heavy, condensed: true))
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                    if let note {
                        Text(note).font(Theme.font(11, .semibold)).opacity(0.85)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 40)
                .foregroundStyle(ghost ? Theme.ink : Color.white)
                .background(ghost ? Color.white : Theme.coral, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ghost ? Theme.line : Color.clear, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .opacity(disabled ? 0.45 : 1)
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
                }
            }
        }
    }
}

/// Wraps a balloon id for `.sheet(item:)`.
private struct BalloonPick: Identifiable {
    let id: Int
}

struct FleetView: View {
    @Environment(GameStore.self) private var store
    @State private var adPick: BalloonPick?
    @State private var designPick: BalloonPick?
    @State private var studioOpen = false

    var body: some View {
        if let game = store.game {
            FleetUI.PageFrame(title: loc("fleetPage.title"), cash: game.state.cash, close: { store.closePage() }) {
                balloonsCard(game)
                shopCard(game.state)
                workshopCard(game)
            }
            .sheet(item: $adPick) { pick in
                AdPicker(balloonID: pick.id).environment(store)
            }
            .sheet(item: $designPick) { pick in
                DesignPicker(balloonID: pick.id).environment(store)
            }
            .sheet(isPresented: $studioOpen) {
                DesignStudioView().environment(store)
            }
        }
    }

    // MARK: Your balloons

    private func balloonsCard(_ game: Game) -> some View {
        let s = game.state
        return FleetUI.Card(loc("fleetPage.yours")) {
            ForEach(s.sortedFleet) { b in
                balloonRow(b, game)
            }
            FleetUI.Hint(loc("fleetPage.hintEnvelope", num(s.envelopeLife)))
            FleetUI.Hint(loc("fleetPage.hintPilots"))
        }
    }

    private func balloonRow(_ b: Balloon, _ game: Game) -> some View {
        let s = game.state
        return FleetUI.Item {
            HStack(alignment: .top, spacing: 12) {
                DesignBalloon(colors: s.colors, design: s.design(of: b))
                    .frame(width: 44, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        FleetUI.Title(b.name)
                        if b.id == s.flagship {
                            FleetUI.Tag(text: "★ " + loc("fleetPage.flagship"), color: Theme.green)
                        }
                    }
                    FleetUI.Detail(b.size.title + " · " + loc("fleetPage.specs", num(b.size.capacity), eur(b.size.upkeep), eur(b.size.fuel)))
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
        }
        return Text(text)
            .font(Theme.font(13, .bold))
            .foregroundStyle(color)
    }

    private func conditionBar(_ b: Balloon, _ s: GameState) -> some View {
        let cond = s.condition(b)
        let left = max(0, s.envelopeLife - b.flights)
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
                adPick = BalloonPick(id: b.id)
            } label: {
                chip(dot: b.ad.map { Color(hex: $0.colors.bg) } ?? Theme.line,
                     text: b.ad.map { loc("fleetPage.adOn", $0.title, eur($0.pay(for: b.size))) } ?? loc("fleetPage.adNone"))
            }
            .buttonStyle(.plain)
            if s.workshopDay != nil && !s.designs.isEmpty {
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
        let sale = Int((Double(b.size.cost) * Rules.sellShare).rounded())
        return FleetUI.ButtonGrid {
            if s.condition(b) < 0.6 {
                FleetUI.SmallButton(title: loc("fleetPage.renew", eur(renew)), disabled: s.cash < renew) {
                    store.act { _ = $0.renewEnvelope(b.id) }
                }
            }
            if b.id != s.flagship {
                FleetUI.SmallButton(title: loc("fleetPage.makeFlagship"), ghost: true) {
                    store.act { $0.makeFlagship(b.id) }
                }
            }
            if s.balloons.count > 1 {
                FleetUI.SmallButton(title: loc("fleetPage.sell", eur(sale)), ghost: true) {
                    store.act { _ = $0.sellBalloon(b.id) }
                }
            }
        }
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
                    HStack(spacing: 6) {
                        FleetUI.Title(s.region.xlName)
                        FleetUI.Tag(text: loc("fleetPage.signature"), color: Theme.yellow)
                    }
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

// MARK: - Pickers

/// Sponsor choice for one balloon (`openAdPicker`).
private struct AdPicker: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let balloonID: Int

    var body: some View {
        if let s = store.state, let b = s.balloon(balloonID) {
            FleetUI.Sheet(title: loc("fleetPage.adTitle", b.name), lead: loc("fleetPage.adLead"), close: { dismiss() }) {
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
                FleetUI.SmallButton(title: loc(current ? "fleetPage.selected" : "fleetPage.choose"), disabled: current) {
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
                FleetUI.SmallButton(title: loc(label), disabled: current || !ok) {
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

/// Repaint one balloon with company colours or a workshop design (`openDesignPicker`).
private struct DesignPicker: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let balloonID: Int

    var body: some View {
        if let game = store.game, let b = game.state.balloon(balloonID) {
            FleetUI.Sheet(title: loc("fleetPage.designPickTitle", b.name), lead: loc("fleetPage.designPickLead", eur(Studio.reskinCost)),
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
        let current = b.design == d.id
        return FleetUI.Item {
            HStack(spacing: 12) {
                DesignBalloon(colors: d.colors, design: d)
                    .frame(width: 44, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(d.title)
                    FleetUI.Detail(loc("fleetPage.designStats", num(d.score), percent(game.freshness(d))))
                }
                Spacer(minLength: 4)
                paintButton(current: current, cash: game.state.cash) { paint(d.id, b) }
            }
        }
    }

    private func paintButton(current: Bool, cash: Int, action: @escaping () -> Void) -> some View {
        FleetUI.SmallButton(title: loc(current ? "fleetPage.selected" : "fleetPage.paint"),
                            disabled: current || cash < Studio.reskinCost, action: action)
            .frame(width: 104)
    }

    private func paint(_ design: Int?, _ b: Balloon) {
        store.act { _ = $0.paint(b.id, design: design) }
        dismiss()
    }
}
