import SwiftUI
import BalloonBaronCore

/// One line in the home alert stack. Lower level = more urgent.
struct HomeAlert: Identifiable {
    enum Level: Int { case red, mission, yellow, green, winter }

    let id: String
    let level: Level
    let title: String
    var text = ""
    var tap: (() -> Void)?
    /// Shows a "Renew €15,000" button for the license.
    var renew = false
}

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var confirmRed = false
    /// Day on which the player expanded the alerts; they collapse again the next morning.
    @State private var alertsOpenDay: Int?
    @State private var showPlan = false
    @State private var showPrice = false
    /// Page picked inside the flight plan, opened once the sheet is gone.
    @State private var pendingPage: Page?
    /// Top of the dock and bottom of the HUD on screen; the scene puts its ground and sky scale there.
    @State private var dockTop: CGFloat = 0
    @State private var hudBottom: CGFloat = 56

    var body: some View {
        if let game = store.game {
            content(game)
                .alert(loc("home.redConfirm"), isPresented: $confirmRed) {
                    Button(loc("home.redFly"), role: .destructive) { store.fly() }
                    Button(loc("common.cancel"), role: .cancel) {}
                } message: {
                    Text(loc("home.redConfirmBody", eur(Rules.redFine)))
                }
                .sheet(isPresented: $showPlan, onDismiss: openPendingPage) {
                    FleetPlanView(openPage: { pendingPage = $0 })
                        .environment(store)
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showPrice) {
                    PriceSheetView()
                        .environment(store)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
        }
    }

    private func content(_ game: Game) -> some View {
        let s = game.state
        return ZStack(alignment: .top) {
            OfficeSceneView(groundY: dockTop, topY: hudBottom + 40)
            VStack(spacing: 10) {
                hud(s)
                    .background {
                        GeometryReader { g in
                            Color.clear.preference(key: HudBottomKey.self, value: g.frame(in: .global).maxY)
                        }
                    }
                HStack(alignment: .top, spacing: 10) {
                    if let w = s.weather { weatherWidget(w, winter: s.winter != nil) }
                    Spacer(minLength: 0)
                    navColumn(s)
                }
                Spacer(minLength: 0)
                if !store.collecting {
                    dockPanel(game)
                        .layoutPriority(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .onPreferenceChange(DockTopKey.self) { v in
            if v >= 0 && abs(v - dockTop) > 0.5 { dockTop = v }
        }
        .onPreferenceChange(HudBottomKey.self) { v in
            if v >= 0 && abs(v - hudBottom) > 0.5 { hudBottom = v }
        }
    }

    /// The prototype's glass dock over the ground. Scrolls only when it doesn't fit.
    private func dockPanel(_ game: Game) -> some View {
        ViewThatFits(in: .vertical) {
            dockGlass(game)
            ScrollView(showsIndicators: false) { dockGlass(game) }
        }
        .frame(maxWidth: 560)
        .background {
            GeometryReader { g in
                Color.clear.preference(key: DockTopKey.self, value: g.frame(in: .global).minY)
            }
        }
    }

    private func dockGlass(_ game: Game) -> some View {
        VStack(spacing: 10) {
            dock(game)
            #if DEBUG
            Button(loc("debug.reset")) { store.resetForTesting() }
                .font(Theme.font(13))
                .foregroundStyle(.white.opacity(0.7))
            #endif
        }
        .padding(12)
        .background(Theme.glass, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(red: 10 / 255, green: 5 / 255, blue: 30 / 255).opacity(0.4), radius: 15, y: 10)
    }

    private func openPendingPage() {
        guard let p = pendingPage else { return }
        pendingPage = nil
        store.page = p
    }

    // MARK: HUD

    private func hud(_ s: GameState) -> some View {
        let multi = !s.parked.isEmpty || s.anyBaron || s.region != .cap
        return HStack(spacing: 8) {
            chip(loc("hud.day", num(s.day)))
            if multi { chip(s.region.title) }
            Spacer(minLength: 4)
            chip(eur(s.cash), color: s.cash < 0 ? Theme.red : .white)
            chip(starsText(s.rep), color: Theme.sun)
        }
    }

    private func chip(_ text: String, color: Color = .white) -> some View {
        Text(text)
            .font(Theme.font(17, .bold, condensed: true))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.glass, in: Capsule())
    }

    // MARK: Cards

    /// Compact glass weather widget (the prototype's `.wxw`): flag, surface wind and the four wind bands.
    private func weatherWidget(_ w: Weather, winter: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.flagColor(w.flag))
                    .frame(width: 14, height: 22)
                    .background(Rectangle().fill(Color.white).frame(width: 3).offset(x: -8))
                    .padding(.leading, 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(w.flag.title)
                        .font(Theme.font(19, .heavy, condensed: true))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(loc("home.wind", num(w.surfaceWind)))
                        .font(Theme.font(12))
                        .opacity(0.75)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if winter {
                        Text(loc("home.winter"))
                            .font(Theme.font(12, .semibold))
                            .foregroundStyle(Color(hex: "#bfe0ff"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
            .padding(.bottom, 2)
            ForEach([3, 2, 1, 0], id: \.self) { i in
                windRow(i, w)
            }
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(width: 204, alignment: .leading)
        .background(Theme.glass, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private func windRow(_ i: Int, _ w: Weather) -> some View {
        let band = FlightWorld.bands[i]
        let v = i < w.layers.count ? w.layers[i] : 0
        return HStack(spacing: 6) {
            Text("\(num(Int(band.lowerBound)))–\(num(Int(band.upperBound))) m")
                .font(Theme.font(11))
                .opacity(0.7)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 60, alignment: .leading)
            WindBar(speed: v)
                .frame(height: 8)
            Text(num(Int((abs(v) * 3.6).rounded())))
                .font(Theme.font(14, .bold, condensed: true))
                .monospacedDigit()
                .frame(width: 22, alignment: .trailing)
        }
    }

    // MARK: Side buttons

    private func navColumn(_ s: GameState) -> some View {
        let badge = goalsBadge(s)
        let issue = s.parked.values.contains { $0.auto.issue != nil }
        let crewDot = !s.licenseValid || s.local.balloons.contains { s.status($0) == .noPilot }
        let marketDot = s.local.rivals.contains { r in
            (r.alive && r.offer != nil && !r.offerDeclined) || (r.forSale != nil && !r.saleDeclined)
        }
        return VStack(spacing: 10) {
            if s.anyBaron {
                navButton("building.columns.fill", loc("home.nav.holding"), .holding, badge: badge, dot: issue)
            } else {
                navButton("flag.fill", loc("home.nav.goals"), .goals, badge: badge)
            }
            if s.unlocked.contains(.fleet) {
                navButton("balloon.fill", loc("home.nav.fleet"), .fleet)
            }
            if s.unlocked.contains(.crew) {
                navButton("person.2.fill", loc("home.nav.crew"), .crew, dot: crewDot)
            }
            if s.unlocked.contains(.market) {
                navButton("chart.bar.fill", loc("home.nav.market"), .market, dot: marketDot)
            }
        }
    }

    /// "2/4" goals of the chapter in progress; nil once the region's baron.
    private func goalsBadge(_ s: GameState) -> String? {
        guard let c = s.currentChapter else { return nil }
        let done = c.goals.filter { s.done($0) }.count
        return "\(num(done))/\(num(c.goals.count))"
    }

    private func navButton(_ icon: String, _ title: String, _ page: Page, badge: String? = nil, dot: Bool = false) -> some View {
        Button { store.page = page } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Theme.glass, in: RoundedRectangle(cornerRadius: 14))
                Text(title)
                    .font(Theme.font(12, .bold, condensed: true))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 64)
            .overlay(alignment: .topTrailing) {
                navMark(badge: badge, dot: dot)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func navMark(badge: String?, dot: Bool) -> some View {
        if let badge {
            Text(badge)
                .font(Theme.font(11, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Theme.sun, in: Capsule())
                .overlay(alignment: .topTrailing) {
                    if dot { Circle().fill(Theme.red).frame(width: 9, height: 9).offset(x: 3, y: -3) }
                }
        } else if dot {
            Circle()
                .fill(Theme.red)
                .frame(width: 11, height: 11)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: -4, y: -2)
        }
    }

    // MARK: Dock

    private func dock(_ g: Game) -> some View {
        let s = g.state
        return VStack(spacing: 10) {
            alertsView(alerts(s), day: s.day, cash: s.cash)
            fleetBar(s)
            if s.unlocked.contains(.insurance) { insuranceChips(g) }
            ticketCard(g)
            actionButtons(s)
        }
    }

    // MARK: Alerts

    /// Everything worth telling the player this morning, most urgent first.
    private func alerts(_ s: GameState) -> [HomeAlert] {
        var out: [HomeAlert] = []
        let takeFlight: () -> Void = { store.act { $0.setSelfFly(true) } }
        let renewCost = eur(Rules.recertCost)

        if let w = s.winter {
            out.append(HomeAlert(id: "winter", level: .winter,
                                 title: loc("home.alert.winter", num(s.day - w.start + 1), num(w.end - w.start + 1)),
                                 text: loc("home.alert.winter.body")))
        }
        if let ls = s.lastShare, s.day > 20 {
            let total = ls.me + ls.rivals.reduce(0, +)
            if total > 0 && Double(ls.me) / Double(total) > 0.6 && s.local.rivals.contains(where: { $0.alive }) {
                out.append(HomeAlert(id: "dominance", level: .yellow,
                                     title: loc("home.alert.dominance", percent(Double(ls.me) / Double(total))),
                                     text: loc("home.alert.dominance.body")))
            }
        }
        let fb = s.balloon(s.flagship)
        let fst: GameState.FlyStatus? = fb.map { s.status($0) }
        if let m = s.weather?.mission, let fb, fst != .damaged && fst != .worn {
            let reward = eur(m.reward(for: fb.size))
            if s.isSelf(fb) {
                out.append(HomeAlert(id: "mission", level: .mission, title: loc("home.alert.mission", m.title, reward), text: m.detail))
            } else {
                out.append(HomeAlert(id: "mission", level: .mission, title: loc("home.alert.missionSelf", m.title, reward),
                                     text: m.detail + " " + loc("home.alert.tapSelf"), tap: takeFlight))
            }
        }
        if s.banUntil >= s.day {
            out.append(HomeAlert(id: "ban", level: .red, title: loc("home.alert.ban"),
                                 text: loc("home.alert.ban.body", num(s.banUntil - s.day + 1))))
        }
        if s.weather?.flag == .red && !s.flyingToday.isEmpty {
            out.append(HomeAlert(id: "redflag", level: .red, title: loc("home.alert.red"),
                                 text: loc("home.alert.red.body", eur(Rules.redFine))))
        }
        if s.rep < Rules.crisisRep {
            out.append(HomeAlert(id: "crisis", level: .red, title: loc("home.alert.crisis", starsText(s.rep)),
                                 text: loc("home.alert.crisis.body")))
        }
        out += licenseAlerts(s, fst: fst, renewCost: renewCost, takeFlight: takeFlight)
        let away = s.daysSinceSelfFly
        if !s.flyingSelf && away >= Rules.absentGraceDays - 1 {
            let more = away > Rules.absentGraceDays ? loc("home.alert.absent.now") : loc("home.alert.absent.soon", num(Rules.absentGraceDays))
            out.append(HomeAlert(id: "absent", level: .yellow, title: loc("home.alert.absent", num(away)),
                                 text: more + " " + loc("home.alert.tapSelf"), tap: takeFlight))
        }
        if let fb, s.isSelf(fb), fst == .ok, fb.fly {
            out.append(HomeAlert(id: "founder", level: .green, title: loc("home.founderBonus")))
        }
        if let f = s.fiesta {
            out.append(HomeAlert(id: "fiesta", level: .mission,
                                 title: loc("home.alert.fiesta", num(s.day - f.start + 1), num(f.end - f.start + 1)),
                                 text: loc("home.alert.fiesta.body")))
        } else if s.region.hasFiesta, let next = s.fiestaNext, next - s.day >= 1, next - s.day <= 3 {
            out.append(HomeAlert(id: "fiestaSoon", level: .green, title: loc("home.alert.fiestaSoon", num(next - s.day)),
                                 text: loc("home.alert.fiestaSoon.body")))
        }
        for r in RegionID.allCases {
            guard let issue = s.parked[r]?.auto.issue else { continue }
            out.append(HomeAlert(id: "issue.\(r.rawValue)", level: .red, title: loc("home.alert.issue", r.title, issue.kind.title),
                                 text: loc("home.alert.issue.body"), tap: { store.issueRegion = r }))
        }
        // Stable sort by urgency.
        return out.enumerated()
            .sorted { ($0.element.level.rawValue, $0.offset) < ($1.element.level.rawValue, $1.offset) }
            .map(\.element)
    }

    /// Expired with the flagship stuck (the trap), expired, or about to expire.
    private func licenseAlerts(_ s: GameState, fst: GameState.FlyStatus?, renewCost: String, takeFlight: @escaping () -> Void) -> [HomeAlert] {
        if !s.licenseValid && fst != .ok {
            let title = fst == .worn ? "home.alert.trap.worn" : fst == .damaged ? "home.alert.trap.damaged" : "home.alert.trap"
            let body = fst == .worn ? "home.alert.trap.bodyWorn" : "home.alert.trap.body"
            return [HomeAlert(id: "license", level: .red, title: loc(title), text: loc(body, renewCost),
                              tap: { store.page = .fleet }, renew: true)]
        }
        if !s.licenseValid {
            return [HomeAlert(id: "license", level: .red, title: loc("home.alert.expired"), text: loc("home.alert.expired.body", renewCost),
                              tap: { store.page = .crew }, renew: true)]
        }
        let left = s.licenseDaysLeft
        guard left <= 4 else { return [] }
        var text = left == 0 ? loc("home.alert.expiring.today", renewCost) : loc("home.alert.expiring.days", num(left), renewCost)
        if !s.selfFly { text += " " + loc("home.alert.tapSelf") }
        return [HomeAlert(id: "license", level: .yellow, title: loc("home.alert.expiring"), text: text,
                          tap: s.selfFly ? nil : takeFlight, renew: true)]
    }

    private func alertsView(_ list: [HomeAlert], day: Int, cash: Int) -> some View {
        let open = alertsOpenDay == day
        let shown: [HomeAlert] = open ? list : Array(list.prefix(1))
        return VStack(spacing: 8) {
            ForEach(shown) { a in
                alertRow(a, cash: cash)
            }
            if !open && list.count > 1 {
                Button { alertsOpenDay = day } label: {
                    Text(loc("home.moreAlerts", num(list.count - 1)))
                        .font(Theme.font(14, .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(Theme.glass, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private static func color(_ l: HomeAlert.Level) -> Color {
        switch l {
        case .red: Theme.red
        case .mission: Theme.coral
        case .yellow: Theme.yellow
        case .green: Theme.green
        case .winter: Color(hex: "#5aa9e6")
        }
    }

    private func alertRow(_ a: HomeAlert, cash: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Self.color(a.level))
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(a.title)
                    .font(Theme.font(15, .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !a.text.isEmpty {
                    Text(a.text)
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if a.renew {
                    PlanSmallButton(title: loc("home.renewFor", eur(Rules.recertCost)), disabled: cash < Rules.recertCost) {
                        store.act { $0.renewLicense() }
                    }
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
            if a.tap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink2)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { a.tap?() }
        .accessibilityAddTraits(a.tap != nil ? .isButton : [])
    }

    // MARK: Fleet bar

    private func fleetBar(_ s: GameState) -> some View {
        let c = s.planCounts
        let selfFlies = s.balloon(s.flagship).map { s.isSelf($0) } ?? false
        let line = ([loc("home.fleet.seats", num(c.seats))] + c.parts).joined(separator: " · ")
        return Button { showPlan = true } label: {
            HStack(spacing: 10) {
                BalloonShape(colors: s.planIconColors)
                    .frame(width: 28, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("home.fleet.count", num(c.flying), num(c.total)))
                        .font(Theme.font(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(line)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(loc(selfFlies ? "home.fleet.you" : "home.fleet.pilot"))
                        .font(Theme.font(13, .semibold))
                        .foregroundStyle(selfFlies ? Theme.green : Theme.ink2)
                }
                Spacer(minLength: 4)
                Text(loc("home.fleet.plan"))
                    .font(Theme.font(16, .heavy, condensed: true))
                    .foregroundStyle(Theme.coral)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .background(RoundedRectangle(cornerRadius: 16).fill(c.alarm ? Theme.sun : Theme.coral).offset(y: 4))
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Insurance

    private func insuranceChips(_ g: Game) -> some View {
        let s = g.state
        let p = g.premiums()
        let red = s.weather?.flag == .red
        let hull = red ? loc("home.ins.void") : eur(p.hull)
        let pax = red ? loc("home.ins.void") : eur(p.pax)
        return HStack(spacing: 8) {
            insuranceChip(on: s.insureHull, label: loc("home.ins.hull", hull)) {
                store.act { $0.setInsurance(hull: !s.insureHull) }
            }
            insuranceChip(on: s.insurePax, label: loc("home.ins.pax", pax)) {
                store.act { $0.setInsurance(pax: !s.insurePax) }
            }
        }
    }

    private func insuranceChip(on: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(on ? Color.white : Color.clear)
                    .frame(width: 24, height: 24)
                    .background(on ? Theme.green : Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(on ? Theme.ink : Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(.leading, 6)
            .padding(.trailing, 10)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(on ? Color.white : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .background(RoundedRectangle(cornerRadius: 12).fill(on ? Theme.green : Color.black.opacity(0.28)).offset(y: 3))
            .padding(.bottom, 3)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Ticket

    private func ticketCard(_ g: Game) -> some View {
        let s = g.state
        let est = g.estimatedIncome()
        return Button { showPrice = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(loc("home.ticket"))
                        .font(Theme.font(12, .semibold))
                        .foregroundStyle(Theme.ink2)
                    Text(eur(s.price))
                        .font(Theme.font(26, .heavy, condensed: true))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                ticketForecast(est)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(loc("home.adjust"))
                    .font(Theme.font(16, .heavy, condensed: true))
                    .foregroundStyle(Theme.coral)
            }
            .padding(14)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func ticketForecast(_ est: (pax: Int, seats: Int, income: Int)) -> some View {
        if est.seats > 0 {
            VStack(alignment: .leading, spacing: 6) {
                Text(loc("home.ticketEst", "\(num(est.pax))/\(num(est.seats))", eur(est.income)))
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                TicketFillBar(fraction: Double(est.pax) / Double(max(1, est.seats)), height: 6)
            }
        } else {
            Text(loc("home.noneFlying"))
                .font(Theme.font(13, .semibold))
                .foregroundStyle(Theme.ink2)
        }
    }

    // MARK: Day buttons

    private func actionButtons(_ s: GameState) -> some View {
        let none = s.flyingToday.isEmpty
        return HStack(spacing: 10) {
            BigButton(title: loc("home.skip"), style: .ghost) { store.fly(skip: true) }
                .frame(width: 140)
            BigButton(title: loc(none ? "home.noneFlying" : "home.collect")) {
                if s.weather?.flag == .red { confirmRed = true } else { store.fly() }
            }
            .disabled(none)
            .opacity(none ? 0.5 : 1)
        }
    }
}

/// One wind band in the weather widget: an arrow from the center, right for east, left for west.
struct WindBar: View {
    let speed: Double

    var body: some View {
        Canvas { ctx, size in
            let mid = size.width / 2
            ctx.fill(Path(CGRect(x: mid - 0.5, y: 0, width: 1, height: size.height)), with: .color(.white.opacity(0.3)))
            let len = min(0.44, abs(speed) / 10 * 0.44) * Double(size.width)
            guard len > 0.5 else { return }
            let w = CGFloat(len), right = speed >= 0
            let x0 = right ? mid : mid - w
            ctx.fill(Path(roundedRect: CGRect(x: x0, y: 2, width: w, height: 4), cornerRadius: 2), with: .color(Theme.sun))
            var head = Path()
            let tip = right ? mid + w + 8 : mid - w - 8, base = right ? mid + w : mid - w
            head.move(to: CGPoint(x: base, y: -2))
            head.addLine(to: CGPoint(x: tip, y: 4))
            head.addLine(to: CGPoint(x: base, y: 10))
            head.closeSubpath()
            ctx.fill(head, with: .color(Theme.sun))
        }
        .accessibilityHidden(true)
    }
}

private struct DockTopKey: PreferenceKey {
    static var defaultValue: CGFloat = -1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct HudBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = -1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
