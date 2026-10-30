import SwiftUI
import BalloonBaronCore

/// Crew page: license, idle and assigned pilots, applicants and the pilot school.
struct CrewView: View {
    @Environment(GameStore.self) private var store
    @State private var filter: CrewFilter = .all
    @State private var card: PilotPick?

    private static let levelColors: [PilotLevel: Color] = [
        .rookie: Color(hex: "#9a8fb8"), .experienced: Color(hex: "#14a39a"), .senior: Color(hex: "#ff5e3a")
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            if let s = store.state {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            licenseSection(s)
                            needPilots(s)
                            crewSummary(s)
                            idleSection(s)
                            dutySection(s)
                            candidatesSection(s)
                            schoolSection(s)
                                .id(PageSection.school)
                            PageDoneButton { store.closePage() }
                        }
                        .padding(16)
                    }
                    .onAppear { store.scrollToSection(proxy) }
                    .tutScrolling(proxy, store)
                }
            }
        }
        .background(Theme.sky.ignoresSafeArea())
        .sheet(item: $card) { pick in
            PilotCardSheet(pilotID: pick.id).environment(store)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text(loc("crew.title"))
                .font(Theme.font(30, .heavy, condensed: true))
                .foregroundStyle(.white)
            Spacer()
            Button { store.closePage() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.glass, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc("home.close"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: License

    @ViewBuilder
    private func licenseSection(_ s: GameState) -> some View {
        if s.licenseValid {
            callout(loc("crew.licenseOk"),
                    loc("crew.licenseOk.body", num(Rules.licenseDays), num(s.licenseDaysLeft)),
                    color: Theme.green)
        } else {
            callout(loc("home.alert.expired"), loc("crew.licenseLapsed.body", eur(Rules.recertCost)), color: Theme.red) {
                PlanSmallButton(title: loc("crew.renew", eur(Rules.recertCost)), disabled: s.cash < Rules.recertCost) {
                    store.act { $0.renewLicense() }
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func needPilots(_ s: GameState) -> some View {
        let need = s.local.balloons.filter { s.status($0) == .noPilot }.count
        if need > 0 {
            callout(loc("crew.needPilots", num(need)), loc("crew.needPilots.body"), color: Theme.yellow)
        }
    }

    // MARK: Pilots

    /// Readable with thirty pilots (prototype v109 `tabCrew`): a summary, an idle callout with one-tap firing,
    /// filters with counts and one line per pilot. A line opens the pilot's card with the details and Fire.
    @ViewBuilder
    private func crewSummary(_ s: GameState) -> some View {
        let pilots = s.local.pilots
        if !pilots.isEmpty {
            HStack(spacing: 6) {
                tile(num(pilots.count), loc("crew.sum.pilots"))
                tile(eur(pilots.reduce(0) { $0 + $1.wage }), loc("crew.sum.wages"))
                tile(num(s.idlePilots.count), loc("crew.sum.idle"))
                tile(num(pilots.filter { $0.level == .senior }.count), loc("crew.sum.senior"))
            }
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
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func idleSection(_ s: GameState) -> some View {
        let idle = s.idlePilots
        if !idle.isEmpty {
            callout(loc("crew.idle", num(idle.count)) + " " + loc("crew.idle.callout", eur(idle.reduce(0) { $0 + $1.wage })),
                    loc("crew.idle.body"), color: Theme.yellow) {
                PlanSmallButton(title: loc("crew.fireIdle", num(idle.count)), light: true) {
                    store.act { $0.fireIdlePilots() }
                }
                .padding(.top, 4)
            }
        }
    }

    private func dutySection(_ s: GameState) -> some View {
        let pilots = s.local.pilots
        let current = filter == .all || pilots.contains(where: { filter.includes($0, s) }) ? filter : .all
        func cap(_ p: Pilot) -> Int { s.local.balloons.first { $0.pilot == p.id }?.size.capacity ?? -1 }
        // Idle first (they need you), then by the size of their balloon, then the most senior, then by name.
        let list = pilots.filter { current.includes($0, s) }.sorted { a, b in
            let ia = cap(a) < 0 ? 0 : 1, ib = cap(b) < 0 ? 0 : 1
            if ia != ib { return ia < ib }
            if cap(a) != cap(b) { return cap(a) > cap(b) }
            if a.level != b.level { return a.level > b.level }
            return a.name.localizedCompare(b.name) == .orderedAscending
        }
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc("crew.pilots"))
            if pilots.isEmpty {
                hint(loc("crew.noPilots"))
            } else {
                chips(s, current)
                VStack(spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { i, p in
                        if i > 0 { Rectangle().fill(Theme.line).frame(height: 1.5).padding(.leading, 56) }
                        row(p, s)
                    }
                    if list.isEmpty {
                        Text(loc("crew.empty")).font(Theme.font(13)).foregroundStyle(Theme.ink2).padding(14)
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                if pilots.count > 1 { hint(loc("crew.rule") + " " + loc("crew.ringHint")) }
            }
        }
    }

    private func chips(_ s: GameState, _ current: CrewFilter) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(CrewFilter.allCases, id: \.self) { f in
                    let n = s.local.pilots.filter { f.includes($0, s) }.count
                    if f == .all || n > 0 {
                        let on = f == current
                        Button { filter = f } label: {
                            HStack(spacing: 4) {
                                Text(f.title).foregroundStyle(on ? Color.white : Theme.ink)
                                Text(num(n)).foregroundStyle(on ? Color(hex: "#cfc8ff") : f == .idle ? Theme.red : Theme.ink2)
                            }
                            .font(Theme.font(13, .bold))
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(on ? Theme.ink : Color.white, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func row(_ p: Pilot, _ s: GameState) -> some View {
        let b = s.local.balloons.first { $0.pilot == p.id }
        let st: (Color, String)
        if let b {
            switch s.status(b) {
            case .damaged: st = (Theme.red, loc("crew.row.repair", b.title))
            case .worn: st = (Theme.red, loc("crew.row.worn", b.title))
            default: st = (Theme.green, b.title)
            }
        } else {
            st = (Color(hex: "#ff8a3d"), loc("crew.idleTag"))
        }
        let next = p.level.xpToNext
        let k = next.map { min(max(p.xp / Double($0), 0), 1) } ?? 1
        let line = st.1 + " · " + loc("crew.wage", eur(p.wage))
        return Button { card = PilotPick(id: p.id) } label: {
            HStack(spacing: 10) {
                Text(String(p.name.prefix(1)))
                    .font(Theme.font(17, .heavy, condensed: true))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Self.levelColors[p.level] ?? Theme.ink2, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(p.name)
                            .font(Theme.font(17, .heavy, condensed: true))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Text(p.level.title)
                            .font(Theme.font(11, .bold))
                            .foregroundStyle(Theme.ink2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Theme.line.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                            .fixedSize()
                        if let t = p.trait {
                            Text(t.title).font(Theme.font(11, .bold)).foregroundStyle(Color(hex: t.color)).lineLimit(1)
                        }
                    }
                    HStack(spacing: 5) {
                        Circle().fill(st.0).frame(width: 8, height: 8)
                        Text(line)
                            .font(Theme.font(12.5, .semibold))
                            .foregroundStyle(Theme.ink2)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                ZStack {
                    Circle().stroke(Theme.line, lineWidth: 4)
                    Circle().trim(from: 0, to: CGFloat(k))
                        .stroke(next == nil ? Theme.green : Theme.sun, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(next == nil ? "★" : num(Int(p.xp)))
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
        .accessibilityLabel(loc("crew.row.a11y", p.name, p.level.title, line))
        .accessibilityAddTraits(.isButton)
    }

    /// The pilot card's line: wage, accident risk, balloon (or idle) and experience.
    static func detail(_ p: Pilot, _ b: Balloon?, _ s: GameState) -> String {
        var on = loc("crew.idleTag")
        if let b {
            on = loc("crew.on", b.title)
            switch s.status(b) {
            case .damaged: on += " " + loc("crew.inRepair")
            case .worn: on += " " + loc("crew.worn")
            case .licenseHold: on += " " + loc("crew.waitLicense")
            default: break
            }
        }
        return [loc("crew.wage", eur(p.wage)), riskText(p), on, xpText(p)].joined(separator: " · ")
    }

    static func levelColor(_ l: PilotLevel) -> Color { levelColors[l] ?? Theme.ink2 }

    /// `pilotRiskText`: the accident multiplier of level and trait together, with the parts when a trait changes it.
    static func riskText(_ p: Pilot) -> String {
        func f(_ x: Double) -> String { x.formatted(.number.precision(.fractionLength(0...2))) }
        let total = Game.pilotRisk(p)
        guard let t = p.trait, t.accidentFactor != 1 else { return loc("crew.risk", f(total)) }
        return loc("crew.riskTrait", f(total), p.level.title, f(p.level.risk), t.title, f(t.accidentFactor))
    }

    static func xpText(_ p: Pilot) -> String {
        if let next = p.level.xpToNext { return loc("crew.xp", num(Int(p.xp)), num(next)) }
        return loc("crew.topLevel")
    }

    // MARK: Applicants and school

    private func candidatesSection(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc("crew.candidates"))
            ForEach(s.local.candidates) { p in
                pilotRow(p, detail: [loc("crew.wage", eur(p.wage)), Self.riskText(p)].joined(separator: " · "), button: loc("crew.hire"), light: false,
                         spot: p.id == s.local.candidates.first?.id ? "ga.hire" : nil, sound: .coin) {
                    store.act { $0.hire(p.id) }
                }
            }
            hint(loc("crew.candidates.hint"))
        }
    }

    @ViewBuilder
    private func schoolSection(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc("crew.schoolTitle"))
            if !s.local.school && !s.unlocked.contains(.school) {
                // v121.9: the school's plot opens on its own day
                Text(loc("crew.schoolSoon", num(Rules.unlockDay[.school] ?? 11)))
                    .font(Theme.font(13)).foregroundStyle(Theme.ink2)
            } else if s.local.school {
                callout(loc("crew.schoolOpen"), loc("crew.schoolOpen.body"), color: Theme.green)
            } else {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(loc("crew.schoolBuild"))
                            .font(Theme.font(16, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(loc("crew.schoolBuild.body"))
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 6)
                    PlanSmallButton(title: eur(Rules.schoolCost), disabled: s.cash < Rules.schoolCost) {
                        store.act { $0.buildSchool() }
                    }
                    .tutTarget("ga.school", disabled: s.cash < Rules.schoolCost) // v122
                }
                .padding(12)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: Building blocks

    private func pilotRow(_ p: Pilot, detail: String, button: String, light: Bool, spot: String? = nil, sound: Sfx = .click, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            avatar(p)
            VStack(alignment: .leading, spacing: 3) {
                Text(p.name)
                    .font(Theme.font(16, .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    PlanTag(text: p.level.title, color: Theme.ink2)
                    if p.fromSchool { PlanTag(text: loc("crew.school"), color: Theme.green) }
                    if let t = p.trait { PlanTag(text: t.title, color: Color(hex: t.color)) }
                }
                Text(detail)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                if let t = p.trait {
                    Text(t.title + ": " + t.detail)
                        .font(Theme.font(12.5).italic())
                        .foregroundStyle(Theme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 6)
            PlanSmallButton(title: button, light: light, sound: sound, action: action)
                .tutTargetIf(spot != nil, spot ?? "", disabled: false) // v122
        }
        .padding(12)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
    }

    private func avatar(_ p: Pilot) -> some View {
        Text(String(p.name.prefix(1)))
            .font(Theme.font(18, .heavy, condensed: true))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(Self.levelColors[p.level] ?? Theme.ink2, in: Circle())
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(Theme.font(20, .heavy, condensed: true))
            .foregroundStyle(.white)
    }

    private func hint(_ t: String) -> some View {
        Text(t)
            .font(Theme.font(13))
            .foregroundStyle(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func callout(_ title: String, _ text: String, color: Color) -> some View {
        callout(title, text, color: color) { EmptyView() }
    }

    private func callout<Extra: View>(_ title: String, _ text: String, color: Color, @ViewBuilder extra: () -> Extra) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.font(15, .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(text)
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                extra()
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Wraps a pilot id for `.sheet(item:)`.
private struct PilotPick: Identifiable { let id: Int }

/// The crew page's pilot filters (`CREW_FILTERS`); empty ones are hidden.
private enum CrewFilter: CaseIterable {
    case all, idle, senior, experienced, rookie, school

    var title: String {
        switch self {
        case .all: loc("crew.f.all")
        case .idle: loc("crew.f.idle")
        case .senior: PilotLevel.senior.title
        case .experienced: PilotLevel.experienced.title
        case .rookie: PilotLevel.rookie.title
        case .school: loc("crew.f.school")
        }
    }

    func includes(_ p: Pilot, _ s: GameState) -> Bool {
        switch self {
        case .all: true
        case .idle: !s.local.balloons.contains { $0.pilot == p.id }
        case .senior: p.level == .senior
        case .experienced: p.level == .experienced
        case .rookie: p.level == .rookie
        case .school: p.fromSchool
        }
    }
}

/// A pilot's card (`pilotCard`): what the old crew row showed, and Fire.
private struct PilotCardSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let pilotID: Int
    @State private var picking = false

    var body: some View {
        if let s = store.state, let p = s.local.pilots.first(where: { $0.id == pilotID }) {
            let b = s.local.balloons.first { $0.pilot == p.id }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text(String(p.name.prefix(1)))
                            .font(Theme.font(22, .heavy, condensed: true))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(CrewView.levelColor(p.level), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.name).font(Theme.font(26, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                            HStack(spacing: 5) {
                                PlanTag(text: p.level.title, color: Theme.ink2)
                                if p.fromSchool { PlanTag(text: loc("crew.school"), color: Theme.green) }
                                if let t = p.trait { PlanTag(text: t.title, color: Color(hex: t.color)) }
                            }
                        }
                    }
                    Text(CrewView.detail(p, b, s))
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let t = p.trait {
                        Text(t.title + ": " + t.detail)
                            .font(Theme.font(14).italic())
                            .foregroundStyle(Theme.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // v124.4: send the pilot to another balloon
                    if s.local.balloons.contains(where: { !s.isSelf($0) }) {
                        Button { picking = true } label: {
                            HStack(spacing: 6) {
                                Circle().fill(Color(hex: "#3d7fd0")).frame(width: 12, height: 12)
                                Text(loc("pick.balloonBtn", b?.title ?? loc("pick.none")))
                                    .font(Theme.font(13, .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.ink2)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: 10) {
                        PlanSmallButton(title: loc("crew.fire"), light: true) {
                            store.act { $0.fire(p.id) }
                            dismiss()
                        }
                        Spacer()
                    }
                    BigButton(title: loc("fleetPage.close"), style: .ghost) { dismiss() }
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .sheet(isPresented: $picking) {
                BalloonPicker(pilotID: pilotID).environment(store)
            }
        }
    }
}

/// v124.4: pick the balloon a pilot flies; that balloon's pilot swaps over (`balloonPicker`).
private struct BalloonPicker: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let pilotID: Int

    var body: some View {
        if let s = store.state, let p = s.local.pilots.first(where: { $0.id == pilotID }) {
            FleetUI.Sheet(title: loc("pick.balloonTitle", p.name), lead: loc("pick.balloonLead"), close: { dismiss() }) {
                ForEach(s.local.balloons.filter { !s.isSelf($0) }.sorted { ($0.size.capacity, $1.title) > ($1.size.capacity, $0.title) }) { b in
                    row(b, p, s)
                }
            }
        }
    }

    private func row(_ b: Balloon, _ p: Pilot, _ s: GameState) -> some View {
        let mine = b.pilot == p.id || b.pinnedPilot == p.id
        var line = mine ? loc("pick.thisPilot") : s.pilot(of: b)?.name ?? loc("fleetPage.status.noPilot")
        switch s.status(b) {
        case .damaged: line += " · " + loc("crew.inRepair")
        case .worn: line += " · " + loc("crew.worn")
        default: break
        }
        return FleetUI.Item(highlight: mine) {
            HStack(spacing: 12) {
                DesignBalloon(colors: s.colors, design: s.design(of: b))
                    .frame(width: 30, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(b.title)
                    FleetUI.Detail(b.size.title + " · " + line)
                }
                Spacer(minLength: 4)
                FleetUI.SmallButton(title: loc(mine ? "fleetPage.selected" : "fleetPage.choose"), selected: mine) {
                    store.act { $0.pinPilot(balloon: b.id, pilot: p.id) }
                    dismiss()
                }
                .frame(width: 104)
            }
        }
    }
}
