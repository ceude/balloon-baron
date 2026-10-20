import SwiftUI
import BalloonBaronCore

/// Crew page: license, idle and assigned pilots, applicants and the pilot school.
struct CrewView: View {
    @Environment(GameStore.self) private var store

    private struct Assignment: Identifiable {
        let pilot: Pilot
        let balloon: Balloon
        var id: Int { pilot.id }
    }

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
                            idleSection(s)
                            dutySection(s)
                            candidatesSection(s)
                            schoolSection(s)
                                .id(PageSection.school)
                        }
                        .padding(16)
                    }
                    .onAppear { store.scrollToSection(proxy) }
                }
            }
        }
        .background(Theme.sky.ignoresSafeArea())
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

    @ViewBuilder
    private func idleSection(_ s: GameState) -> some View {
        let idle = s.idlePilots.sorted { $0.wage > $1.wage }
        if !idle.isEmpty {
            let wasted = idle.reduce(0) { $0 + $1.wage }
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle(loc("crew.idle", num(idle.count)))
                callout(loc("crew.idle.callout", eur(wasted)), loc("crew.idle.body"), color: Theme.yellow)
                ForEach(idle) { p in
                    pilotRow(p, detail: [loc("crew.wage", eur(p.wage)), loc("crew.idleTag"), xpText(p)].joined(separator: " · "),
                             button: loc("crew.fire"), light: true) {
                        store.act { $0.fire(p.id) }
                    }
                }
            }
        }
    }

    private func dutySection(_ s: GameState) -> some View {
        let idleCount = s.idlePilots.count
        let working = assigned(s)
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc(idleCount > 0 ? "crew.onDuty" : "crew.pilots"))
            if s.local.pilots.count > 1 {
                hint(loc("crew.rule"))
            }
            if s.local.pilots.isEmpty {
                hint(loc("crew.noPilots"))
            }
            ForEach(working) { pair in
                pilotRow(pair.pilot, detail: dutyDetail(pair.pilot, pair.balloon, s), button: loc("crew.fire"), light: true) {
                    store.act { $0.fire(pair.pilot.id) }
                }
            }
        }
    }

    /// Pilots with a balloon, biggest balloon first.
    private func assigned(_ s: GameState) -> [Assignment] {
        var out: [Assignment] = []
        for p in s.local.pilots {
            if let b = s.local.balloons.first(where: { $0.pilot == p.id }) { out.append(Assignment(pilot: p, balloon: b)) }
        }
        return out.sorted { $0.balloon.size.capacity > $1.balloon.size.capacity }
    }

    private func dutyDetail(_ p: Pilot, _ b: Balloon, _ s: GameState) -> String {
        var on = loc("crew.on", b.name)
        switch s.status(b) {
        case .damaged: on += " " + loc("crew.inRepair")
        case .worn: on += " " + loc("crew.worn")
        case .licenseHold: on += " " + loc("crew.waitLicense")
        default: break
        }
        return [loc("crew.wage", eur(p.wage)), on, xpText(p)].joined(separator: " · ")
    }

    private func xpText(_ p: Pilot) -> String {
        if let next = p.level.xpToNext { return loc("crew.xp", num(p.xp), num(next)) }
        return loc("crew.topLevel")
    }

    // MARK: Applicants and school

    private func candidatesSection(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc("crew.candidates"))
            ForEach(s.local.candidates) { p in
                pilotRow(p, detail: loc("crew.wage", eur(p.wage)), button: loc("crew.hire"), light: false) {
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
            if s.local.school {
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
                }
                .padding(12)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: Building blocks

    private func pilotRow(_ p: Pilot, detail: String, button: String, light: Bool, action: @escaping () -> Void) -> some View {
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
                }
                Text(detail)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            PlanSmallButton(title: button, light: light, action: action)
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
