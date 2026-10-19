import SwiftUI
import BalloonBaronCore

/// Master Hezarfen's speech bubble with a typewriter effect. Tap the bubble to finish typing.
struct HezarfenView: View {
    let message: HezMessage
    let onClose: () -> Void
    @State private var shown = 0

    var body: some View {
        let text = message.text
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
            HStack(alignment: .bottom, spacing: 10) {
                VStack(spacing: 4) {
                    HezarfenAvatar(size: 64)
                    Text(loc("hez.name"))
                        .font(Theme.font(12, .bold, condensed: true))
                        .foregroundStyle(.white)
                        .fixedSize()
                }
                VStack(alignment: .leading, spacing: 12) {
                    // The full text reserves the bubble's height so it doesn't grow while typing.
                    ZStack(alignment: .topLeading) {
                        Text(text).opacity(0)
                        Text(String(text.prefix(shown)))
                    }
                    .font(Theme.font(17, .medium))
                    .foregroundStyle(Theme.ink)
                    BigButton(title: loc("hez.ok")) {
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
