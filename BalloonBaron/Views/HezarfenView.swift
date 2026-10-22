import SwiftUI
import BalloonBaronCore

/// Master Hezarfen's speech bubble with a typewriter effect. Tap the bubble to finish typing.
/// A rival boss speaks through the same bubble, with his own face and a curt button.
struct HezarfenView: View {
    let message: HezMessage
    var day = 1
    let onClose: () -> Void
    @State private var shown = 0

    private var boss: (RegionID, BossLine)? {
        if case let .boss(r, l) = message { return (r, l) }
        return nil
    }

    private var button: String {
        if let (_, l) = boss { return loc(["boss.ok.0", "boss.ok.1", "boss.ok.2"][(day + l.rawValue.count) % 3]) }
        return loc(message == .tip(.bazaar) ? "hez.toBazaar" : "hez.ok")
    }

    var body: some View {
        let text = message.text
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
            HStack(alignment: .bottom, spacing: 10) {
                VStack(spacing: 4) {
                    if let (r, _) = boss {
                        BossAvatar(region: r, size: 64)
                        Text(loc("boss.\(r.rawValue).name"))
                            .font(Theme.font(12, .bold, condensed: true))
                            .foregroundStyle(Color(hex: "#bfe0ff"))
                            .fixedSize()
                    } else {
                        HezarfenAvatar(size: 64)
                        Text(loc("hez.name"))
                            .font(Theme.font(12, .bold, condensed: true))
                            .foregroundStyle(.white)
                            .fixedSize()
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    if let (r, _) = boss {
                        Text(loc("boss.\(r.rawValue).title"))
                            .font(Theme.font(11.5, .bold)).foregroundStyle(Theme.ink2)
                    }
                    // The full text reserves the bubble's height so it doesn't grow while typing.
                    ZStack(alignment: .topLeading) {
                        Text(text).opacity(0)
                        Text(String(text.prefix(shown)))
                    }
                    .font(Theme.font(17, .medium))
                    .foregroundStyle(Theme.ink)
                    BigButton(title: button) {
                        if shown < text.count { shown = text.count } else { onClose() }
                    }
                }
                .padding(16)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 22))
                .onTapGesture { shown = text.count }
            }
            .padding(16)
        }
        .task(id: text) {
            shown = 0
            while shown < text.count {
                try? await Task.sleep(for: .milliseconds(22))
                shown = min(text.count, shown + 2)
            }
        }
    }
}
