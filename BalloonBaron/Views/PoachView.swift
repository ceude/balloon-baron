import SwiftUI
import BalloonBaronCore

/// A rival wants one of your pilots (prototype `showPoach`): match the wage or let them go.
struct PoachView: View {
    @Environment(GameStore.self) private var store
    let offer: PoachOffer

    var body: some View {
        let s: GameState? = store.state
        let rival: Rival? = s.flatMap { st in st.rivals.indices.contains(offer.rivalIndex) ? st.rivals[offer.rivalIndex] : nil }
        let pilot: Pilot? = s?.pilots.first { $0.id == offer.pilotID }
        return ModalCard {
            BalloonShape(colors: rivalColors(rival))
                .frame(width: 46, height: 58)
            CardText.title(loc("poach.title", rival?.name ?? ""))
            if let pilot, let s {
                // v142b (TestFlight: "I can't see my pilot's traits, and it matters for the decision"): who it is
                pilotRow(pilot, s)
            }
            if let pilot {
                CardText.lead(loc("poach.lead", pilot.name, pilot.level.title, eur(offer.wage), eur(pilot.wage)))
            }
            Button(loc("poach.raise", eur(offer.wage))) {
                SoundEngine.shared.play(.click)
                store.answerPoach(offer, match: true)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
            Button {
                SoundEngine.shared.play(.click)
                store.answerPoach(offer, match: false)
            } label: {
                Text(loc("poach.letGo")).frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
        }
    }

    /// The pilot at a glance, as on the crew's pilot card: level, school, trait, then wage, accident risk, balloon and
    /// experience, and what the trait does.
    private func pilotRow(_ p: Pilot, _ s: GameState) -> some View {
        let b = s.local.balloons.first { $0.pilot == p.id }
        return HStack(alignment: .top, spacing: 10) {
            Text(String(p.name.prefix(1)))
                .font(Theme.font(17, .heavy, condensed: true))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(CrewView.levelColor(p.level), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(p.name)
                    .font(Theme.font(16, .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    PlanTag(text: p.level.title, color: Theme.ink2)
                    if p.fromSchool { PlanTag(text: loc("crew.school"), color: Theme.green) }
                    if let t = p.trait { PlanTag(text: t.title, color: Color(hex: t.color)) }
                }
                Text(CrewView.detail(p, b, s))
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
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func rivalColors(_ r: Rival?) -> [String] {
        let c: [String] = r?.colors ?? []
        return [c.first ?? "#9a8fb8", c.count > 1 ? c[1] : "#ffffff"]
    }
}
