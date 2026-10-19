import SwiftUI
import BalloonBaronCore

/// Stand-in for the SpriteKit flight scene: lets you pick the outcome so the day loop is playable.
struct FlightPlaceholderView: View {
    @Environment(GameStore.self) private var store
    @State private var missionDone = false

    var body: some View {
        let mission = store.state?.weather?.mission
        ZStack {
            Theme.sky.ignoresSafeArea()
            VStack(spacing: 14) {
                Spacer()
                BalloonShape(colors: store.state?.colors ?? Rules.palettes[0])
                    .frame(width: 110, height: 140)
                Text(loc("flight.title")).font(Theme.font(30, .heavy, condensed: true)).foregroundStyle(.white)
                Text(loc("flight.pax", num(store.flightPax ?? 0))).font(Theme.font(17, .semibold)).foregroundStyle(.white)
                Text(loc("flight.placeholder"))
                    .font(Theme.font(15))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                if let mission {
                    Toggle(isOn: $missionDone) {
                        Text(loc("flight.missionDone") + ": " + mission.title)
                            .font(Theme.font(16, .bold))
                            .foregroundStyle(.white)
                    }
                    .tint(Theme.sun)
                    .padding(.horizontal, 24)
                }
                Spacer()
                VStack(spacing: 8) {
                    ForEach([FlightResult.Landing.perfect, .good, .far, .hard, .crash], id: \.self) { q in
                        BigButton(title: loc("landing.\(q.rawValue)"), style: q == .perfect ? .primary : .ghost) {
                            store.endDay(FlightResult(landing: q, distance: q == .far ? 420 : 40, mission: mission,
                                                      missionDone: missionDone))
                        }
                    }
                    Button(loc("landing.cancel")) { store.endDay(FlightResult(landing: .cancel, mission: mission)) }
                        .font(Theme.font(15, .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
    }
}
