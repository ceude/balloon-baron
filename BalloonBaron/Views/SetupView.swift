import SwiftUI
import BalloonBaronCore

struct SetupView: View {
    @Environment(GameStore.self) private var store
    @State private var name = ""
    @State private var palette = 0
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            BalloonShape(colors: Rules.palettes[palette])
                .frame(width: 120, height: 150)
                .animation(.spring(duration: 0.3), value: palette)
            VStack(alignment: .leading, spacing: 14) {
                Text(loc("setup.title"))
                    .font(Theme.font(28, .heavy, condensed: true))
                    .foregroundStyle(Theme.ink)
                Text(loc("setup.subtitle"))
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.ink2)
                TextField(loc("setup.placeholder"), text: $name)
                    .font(Theme.font(20, .semibold))
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 2))
                    .focused($focused)
                    .submitLabel(.done)
                Text(loc("setup.color"))
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(Theme.ink2)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ForEach(Rules.palettes.indices, id: \.self) { i in
                        let c = Rules.palettes[i]
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: c[0]), Color(hex: c[1])], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Theme.ink, lineWidth: palette == i ? 3 : 0))
                            .onTapGesture { palette = i }
                    }
                }
                BigButton(title: loc("setup.start")) {
                    store.newGame(company: name.trimmingCharacters(in: .whitespaces), colors: Rules.palettes[palette])
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
            .padding(22)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 26))
            .padding(.horizontal, 16)
            Spacer()
        }
        .onAppear { focused = true }
    }
}

/// Simple code-drawn balloon used in menus until the SpriteKit art lands.
struct BalloonShape: View {
    let colors: [String]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Ellipse()
                    .fill(Color(hex: colors[0]))
                    .frame(width: w, height: h * 0.78)
                    .position(x: w / 2, y: h * 0.39)
                Ellipse()
                    .fill(Color(hex: colors[1]))
                    .frame(width: w * 0.32, height: h * 0.78)
                    .position(x: w / 2, y: h * 0.39)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#6b4426"))
                    .frame(width: w * 0.22, height: h * 0.13)
                    .position(x: w / 2, y: h * 0.92)
            }
        }
    }
}
