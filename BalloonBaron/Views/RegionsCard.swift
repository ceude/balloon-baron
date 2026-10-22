import SwiftUI
import BalloonBaronCore

/// The region you're in, tapped on the top bar: your other regions one tap away, and the world map. Port of `regionMenu`.
struct RegionsCard: View {
    @Environment(GameStore.self) private var store
    let onClose: () -> Void

    var body: some View {
        let s = store.state
        return ModalCard {
            CardText.title(loc("regions.title"))
            if let s {
                ForEach(RegionID.allCases.filter { s.owns($0) }, id: \.self) { r in
                    row(r, s)
                }
            }
            ghost(loc("regions.map")) {
                onClose()
                store.page = .map
            }
            ghost(loc("world.close")) { onClose() }
        }
    }

    private func row(_ r: RegionID, _ s: GameState) -> some View {
        let here = r == s.region, issue = s.parked[r]?.auto.issue != nil
        let pin = MapPin(rawValue: r.rawValue)
        let status = here ? loc("regions.here") : issue ? loc("regions.issue") : loc("regions.auto")
        return Button {
            SoundEngine.shared.play(.click)
            onClose()
            if !here { store.goTo(r) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.title).font(Theme.font(21, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                    Text([pin?.land, status].compactMap { $0 }.joined(separator: " · ")).font(Theme.font(13)).foregroundStyle(Theme.ink2)
                }
                Spacer()
                Text(here ? "✓" : loc("regions.go"))
                    .font(Theme.font(17, .heavy, condensed: true))
                    .foregroundStyle(here ? Theme.green : Theme.coral)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(here ? Theme.green : Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func ghost(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button {
            SoundEngine.shared.play(.click)
            action()
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(kind: .ghost))
    }
}
