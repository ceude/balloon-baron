import SwiftUI
import BalloonBaronCore

/// Today's fleet at a glance, for the home summary bar and the flight plan.
struct PlanCounts {
    var flying: Int
    var total: Int
    var seats: Int
    /// "Grounded: 2", "In repair: 1" …
    var parts: [String]
    /// Something the player should fix: no pilot, worn envelope, license hold.
    var alarm: Bool
}

extension GameState {
    var planCounts: PlanCounts {
        let fl = flyingToday
        var why: [FlyStatus: Int] = [:]
        var grounded = 0
        let sts = statusByID // v127: once for the whole fleet
        for b in local.balloons {
            let st = sts[b.id] ?? status(b)
            if st == .ok {
                if !b.fly { grounded += 1 }
            } else {
                why[st, default: 0] += 1
            }
        }
        let order: [(FlyStatus, String)] = [(.outside, "home.fleet.outside"), (.damaged, "home.fleet.damaged"), (.noPilot, "home.fleet.noPilot"), (.worn, "home.fleet.worn"),
                                           (.licenseHold, "home.fleet.license"), (.banned, "home.fleet.banned"), (.late, "home.fleet.late"),
                                           (.strike, "home.fleet.strike"), (.chartered, "home.fleet.chartered")]
        var parts: [String] = []
        if grounded > 0 { parts.append(loc("home.fleet.grounded", num(grounded))) }
        for (st, key) in order {
            if let n = why[st], n > 0 { parts.append(loc(key, num(n))) }
        }
        let alarm = why[.noPilot] != nil || why[.worn] != nil || why[.licenseHold] != nil
        let seats = fl.reduce(0) { $0 + sellSeats($1) }
        return PlanCounts(flying: fl.count, total: local.balloons.count, seats: seats, parts: parts, alarm: alarm)
    }

    /// Company colors for balloon icons, with a fallback for odd saves.
    var planIconColors: [String] { colors.count >= 2 ? colors : ["#ff5e3a", "#ffc23d"] }
}

/// Today's flight plan: who flies the flagship and which balloons go up.
struct FleetPlanView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// Called with an office page to open once the sheet has closed.
    var openPage: (Page) -> Void = { _ in }
    @State private var tick = 0
    @State private var noPilot = false

    private struct SizeGroup: Identifiable {
        let size: BalloonSize
        let list: [Balloon]
        var id: String { size.rawValue }
    }

    var body: some View {
        if let g = store.game {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header(g.state)
                    whoFlies(g.state)
                    topButtons(g.state)
                    ForEach(groups(g.state)) { grp in
                        groupView(grp, g)
                    }
                    // v127: the balloons outside the hangar aren't listed; one line says how many, and leads to the upgrade
                    if g.state.outsideCount > 0 {
                        HangarWarningRow(outside: g.state.outsideCount, capacity: g.state.hangarCapacity) {
                            dismiss()
                            store.buildingCard = .hangar
                        }
                        .padding(.top, 4)
                    }
                    BigButton(title: loc("home.done")) { dismiss() }
                        .padding(.top, 6)
                }
                .padding(18)
                .overlay(alignment: .topTrailing) { CardCloseX { dismiss() } }
            }
            .background(Theme.paper.ignoresSafeArea())
            .sensoryFeedback(.selection, trigger: tick)
            .modifier(NoPilotAlert(shown: $noPilot, crewOpen: g.state.unlocked.contains(.crew)) { go(.crew) })
        }
    }

    private func groups(_ s: GameState) -> [SizeGroup] {
        let out = s.outsideIDs
        let fleet = s.sortedFleet.filter { !out.contains($0.id) } // v121.7: your balloon stays in its place in its group, tagged; v127: not the ones outside
        return [BalloonSize.XL, .L, .M, .S].compactMap { z -> SizeGroup? in
            let list = fleet.filter { $0.size == z }
            return list.isEmpty ? nil : SizeGroup(size: z, list: list)
        }
    }

    // MARK: Header

    private func header(_ s: GameState) -> some View {
        let c = s.planCounts
        let line = ([loc("home.fleet.count", num(c.flying), num(c.total)), loc("home.fleet.seats", num(c.seats))] + c.parts)
            .joined(separator: " · ")
        return VStack(alignment: .leading, spacing: 4) {
            Text(loc("fplan.title"))
                .font(Theme.font(28, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            Text(line)
                .font(Theme.font(14, .semibold))
                .foregroundStyle(Theme.ink2)
        }
    }

    @ViewBuilder
    private func whoFlies(_ s: GameState) -> some View {
        if let fb = s.balloon(s.flagship) {
            VStack(alignment: .leading, spacing: 6) {
                if !s.licenseValid {
                    Text(loc("fplan.mustSelf"))
                        .font(Theme.font(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(loc("fplan.mustSelf.body", eur(Rules.recertCost)))
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.ink2)
                } else {
                    // v121.2 (TestFlight): no "who flies?" question; you pick your balloon in the list, like in the fleet
                    let premium = Rules.founderPremium.formatted(.percent.precision(.fractionLength(0)))
                    Text(s.selfFly ? loc("fplan.selfTitle", fb.title) : loc("fplan.pilotsTitle"))
                        .font(Theme.font(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(loc(s.selfFly ? "fplan.selfNote" : "fplan.pilotsNote", premium))
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.ink2)
                    if let m = s.weather?.mission {
                        Text(loc(s.selfFly ? "fplan.missionYours" : "fplan.missionNote", m.title, eur(m.reward(for: fb.size))))
                            .font(Theme.font(14, .semibold))
                            .foregroundStyle(s.selfFly ? Theme.ink2 : Theme.coral)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#fff3e8"), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func topButtons(_ s: GameState) -> some View {
        HStack(spacing: 10) {
            BigButton(title: loc("fplan.allFly"), style: .ghost) { setFlying(s.local.balloons, true) }
            BigButton(title: loc("fplan.allGround"), style: .ghost) { setFlying(s.local.balloons, false) }
        }
    }

    // MARK: Groups

    private func groupView(_ grp: SizeGroup, _ g: Game) -> some View {
        let s = g.state
        let okList = grp.list.filter { s.status($0) == .ok }
        let on = okList.filter(\.fly).count
        let title = loc("fplan.group", grp.size.title, num(grp.size.capacity), num(on), num(grp.list.count))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(Theme.ink2)
                Spacer(minLength: 4)
                if okList.count > 1 {
                    PlanSmallButton(title: loc("fplan.all"), light: true) { setFlying(grp.list, true) }
                    PlanSmallButton(title: loc("fplan.none"), light: true) { setFlying(grp.list, false) }
                }
            }
            .padding(.top, 6)
            ForEach(grp.list) { b in
                row(b, g)
            }
        }
    }

    private func row(_ b: Balloon, _ g: Game) -> some View {
        let s = g.state
        let st = s.status(b)
        let active = st == .ok && b.fly
        let you = s.isSelf(b)
        return HStack(spacing: 10) {
            BalloonShape(colors: s.planIconColors)
                .frame(width: 28, height: 36)
                .opacity(active ? 1 : 0.45)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(b.title)
                        .font(Theme.font(16, .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    if you {
                        PlanTag(text: loc("fleet.row.youFly"), color: Color(hex: "#c2401f"))
                    } else if b.id == s.flagship {
                        PlanTag(text: loc("fplan.flagship"), color: Theme.green)
                    }
                }
                Text(subtitle(b, s))
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(st == .ok ? Theme.ink2 : Theme.red)
                Text(detail(b, g))
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.ink2)
                // "Give to a pilot": with no pilot free it asks to hire one instead of grounding the flagship (v121.10)
                if s.licenseValid && (you || ([.ok, .noPilot, .late, .strike] as [GameState.FlyStatus]).contains(st)) {
                    PlanChipButton(title: loc(you ? "fplan.toPilot" : "fleetPage.flyMyself")) {
                        if !you { flyMyself(b.id) } else if g.pilotFreeForFlagship { setSelf(false) } else { noPilot = true }
                    }
                        .padding(.top, 3)
                }
            }
            Spacer(minLength: 6)
            trailing(b, st)
        }
        .padding(12)
        .background(you ? Color(hex: "#fff3e8") : Color.white.opacity(st == .ok ? 1 : 0.6), in: RoundedRectangle(cornerRadius: 14))
        .overlay { if you { RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#ffcbb5"), lineWidth: 2) } }
    }

    @ViewBuilder
    private func trailing(_ b: Balloon, _ st: GameState.FlyStatus) -> some View {
        if st == .ok {
            PlanFlyButton(title: loc(b.fly ? "fplan.flying" : "fplan.grounded"), on: b.fly) {
                store.act { $0.setFlying(b.id, !b.fly) }
                tick += 1
            }
        } else if let p = shortcut(st) {
            PlanSmallButton(title: loc(p == .crew ? "home.nav.crew" : "home.nav.fleet"), light: true) { go(p) }
        }
    }

    /// Why a balloon can't fly, or who flies it.
    private func subtitle(_ b: Balloon, _ s: GameState) -> String {
        switch s.status(b) {
        case .licenseHold: return loc("fplan.why.license")
        case .worn: return loc("fplan.why.worn")
        case .damaged: return loc("fplan.why.damaged", num(max(0, b.damagedUntil - s.day)))
        case .banned: return loc("fplan.why.banned")
        case .noPilot: return loc("fplan.why.noPilot")
        case .chartered: return loc("fplan.why.chartered")
        case .late: return loc("fplan.why.late")
        case .strike: return loc("fplan.why.strike")
        case .outside: return loc("fleet.row.outside")
        case .ok:
            if s.isSelf(b) { return loc("fplan.pilotYou") }
            guard let p = s.pilot(of: b) else { return loc("fplan.why.noPilot") }
            let first = p.name.split(separator: " ").first.map(String.init) ?? p.name
            return loc("fplan.pilotName", first, p.level.title)
        }
    }

    /// Envelope condition and, when it can fly, today's accident risk.
    private func detail(_ b: Balloon, _ g: Game) -> String {
        let s = g.state
        var parts = [loc("fplan.envelope", percent(s.condition(b)))]
        if s.status(b) == .ok && s.weather?.flag != .red {
            let risk = g.accidentChance(b).formatted(.percent.precision(.fractionLength(1)))
            parts.append(loc("fplan.risk", risk))
        }
        return parts.joined(separator: " · ")
    }

    private func shortcut(_ st: GameState.FlyStatus) -> Page? {
        switch st {
        case .noPilot, .licenseHold: return .crew
        case .worn: return .fleet
        default: return nil
        }
    }

    // MARK: Actions

    /// "I'll fly this one": it becomes the flagship, flying today.
    private func flyMyself(_ id: Int) {
        store.act { g in
            if g.flyMyself(id), let b = g.state.balloon(id), g.state.status(b) == .ok { g.setFlying(id, true) }
        }
        tick += 1
    }

    private func setSelf(_ on: Bool) {
        store.act { $0.setSelfFly(on) }
        tick += 1
    }

    /// Only balloons that can fly are switched.
    private func setFlying(_ list: [Balloon], _ on: Bool) {
        let ids = list.map(\.id)
        store.act { g in
            for id in ids {
                if let b = g.state.balloon(id), g.state.status(b) == .ok { g.setFlying(id, on) }
            }
        }
        tick += 1
    }

    private func go(_ p: Page) {
        openPage(p)
        dismiss()
    }
}

extension Game {
    /// Whether a pilot could take the flagship if you stepped out of its basket.
    var pilotFreeForFlagship: Bool {
        var t = self
        t.setSelfFly(false)
        return t.state.balloon(t.state.flagship).map { t.state.status($0) == .ok } ?? false
    }
}

/// v121.10: "Give to a pilot" with no pilot free: offer the crew page (or say it isn't open yet).
struct NoPilotAlert: ViewModifier {
    @Binding var shown: Bool
    let crewOpen: Bool
    let goCrew: () -> Void

    func body(content: Content) -> some View {
        // v122.5: the game's own card, not the system alert
        content.modifier(GameAlert(shown: $shown, title: loc("noPilot.title"), message: loc(crewOpen ? "noPilot.body" : "noPilot.locked"),
                                   primary: loc(crewOpen ? "noPilot.goCrew" : "noPilot.ok"),
                                   secondary: crewOpen ? loc("common.cancel") : nil,
                                   onPrimary: { if crewOpen { goCrew() } }))
    }
}

// MARK: Shared game-style controls

/// Chunky on/off button: coral when on, grey when off.
struct PlanFlyButton: View {
    let title: String
    let on: Bool
    var wide = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(15, .heavy, condensed: true))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .frame(minWidth: 84, maxWidth: wide ? CGFloat.infinity : nil, minHeight: 36)
                .foregroundStyle(on ? Color.white : Theme.ink2)
                .background(RoundedRectangle(cornerRadius: 12).fill(on ? Theme.coral : Color(hex: "#e4deef")))
                .background(RoundedRectangle(cornerRadius: 12).fill(on ? Color(hex: "#c7381a") : Color(hex: "#c9c1db")).offset(y: 3))
                .padding(.bottom, 3)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// v121.2: a small outlined chip under a balloon's name ("I'll fly this one", "Give to a pilot").
struct PlanChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(13, .heavy, condensed: true))
                .lineLimit(1)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// Small action button for list rows. Looks like `FleetUI.SmallButton` (one small-button style across the app);
/// taps click and give a light haptic (`sound: nil` when the action plays its own sound).
struct PlanSmallButton: View {
    let title: String
    var light = false
    var disabled = false
    var sound: Sfx? = .click
    let action: () -> Void

    var body: some View {
        Button {
            if let sound { SoundEngine.shared.play(sound) }
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .smallButtonLook(kind: light ? .ghost : disabled ? .off : .main)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled && light ? 0.55 : 1)
    }
}

/// The one look of the small buttons (`PlanSmallButton`, `FleetUI.SmallButton`): condensed capitals, 12 pt corners,
/// at least 44 pt tall so it's easy to hit.
struct SmallButtonLook: ViewModifier {
    enum Kind { case main, ghost, off, selected }
    let kind: Kind
    var wide = false

    func body(content: Content) -> some View {
        content
            .font(Theme.font(15, .heavy, condensed: true))
            .textCase(.uppercase)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: wide ? .infinity : nil, minHeight: 44)
            .foregroundStyle(fg)
            .background(bg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(stroke, lineWidth: 2))
            .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var fg: Color {
        switch kind {
        case .main: Color.white
        case .ghost: Theme.ink
        case .off: Theme.offText
        case .selected: Color(hex: "#1b7d47")
        }
    }

    private var bg: Color {
        switch kind {
        case .main: Theme.coral
        case .ghost: Color.white
        case .off: Theme.offFill
        case .selected: Theme.green.opacity(0.14)
        }
    }

    private var stroke: Color {
        switch kind {
        case .ghost: Theme.line
        case .selected: Theme.green.opacity(0.5)
        case .main, .off: Color.clear
        }
    }
}

extension View {
    func smallButtonLook(kind: SmallButtonLook.Kind, wide: Bool = false) -> some View {
        modifier(SmallButtonLook(kind: kind, wide: wide))
    }
}

/// Little colored label ("Flagship", "Senior").
struct PlanTag: View {
    let text: String
    var color: Color = Theme.ink2

    var body: some View {
        Text(text)
            .font(Theme.font(11, .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.14), in: Capsule())
    }
}
