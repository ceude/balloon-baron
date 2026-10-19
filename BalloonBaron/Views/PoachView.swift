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

    private func rivalColors(_ r: Rival?) -> [String] {
        let c: [String] = r?.colors ?? []
        return [c.first ?? "#9a8fb8", c.count > 1 ? c[1] : "#ffffff"]
    }
}
