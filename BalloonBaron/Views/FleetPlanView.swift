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
        for b in local.balloons {
            let st = status(b)
            if st == .ok {
                if !b.fly { grounded += 1 }
            } else {
                why[st, default: 0] += 1
            }
        }
        let order: [(FlyStatus, String)] = [(.damaged, "home.fleet.damaged"), (.noPilot, "home.fleet.noPilot"), (.worn, "home.fleet.worn"),
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
                    BigButton(title: loc("home.done")) { dismiss() }
                        .padding(.top, 6)
                }
                .padding(18)
                .overlay(alignment: .topTrailing) { CardCloseX { dismiss() } }
            }
            .background(Theme.paper.ignoresSafeArea())
            .sensoryFeedback(.selection, trigger: tick)
        }
    }

    private func groups(_ s: GameState) -> [SizeGroup] {
        let fleet = s.sortedFleet
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
                    Text(loc("fplan.who", fb.title))
                        .font(Theme.font(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(loc("fplan.whoNote"))
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.ink2)
                    if let m = s.weather?.mission {
                        Text(loc("fplan.missionNote", m.title, eur(m.reward(for: fb.size))))
                            .font(Theme.font(14, .semibold))
                            .foregroundStyle(Theme.coral)
                    }
                    HStack(spacing: 10) {
                        PlanFlyButton(title: loc("fplan.you"), on: s.selfFly, wide: true) { setSelf(true) }
                        PlanFlyButton(title: loc("fplan.pilot"), on: !s.selfFly, wide: true) { setSelf(false) }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
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
                    if b.id == s.flagship {
                        PlanTag(text: loc("fplan.flagship"), color: Theme.green)
                    }
                }
                Text(subtitle(b, s))
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(st == .ok ? Theme.ink2 : Theme.red)
                Text(detail(b, g))
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.ink2)
            }
            Spacer(minLength: 6)
            trailing(b, st)
        }
        .padding(12)
        .background(Color.white.opacity(st == .ok ? 1 : 0.6), in: RoundedRectangle(cornerRadius: 14))
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

/// Small action button for list rows.
struct PlanSmallButton: View {
    let title: String
    var light = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(15, .heavy, condensed: true))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .frame(minHeight: 34)
                .foregroundStyle(light ? Theme.ink : disabled ? Theme.offText : Color.white)
                .background(light ? Theme.line : disabled ? Theme.offFill : Theme.coral, in: RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled && light ? 0.55 : 1)
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
