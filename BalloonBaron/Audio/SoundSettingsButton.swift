import SwiftUI

/// Speaker toggle for the sound setting (the prototype's "Ses: açık / kapalı").
struct SoundSettingsButton: View {
    @AppStorage("sound") private var on = true
    var size: CGFloat = 20
    var color: Color = Theme.ink

    var body: some View {
        Button {
            let new = !on
            SoundEngine.shared.enabled = new
            on = new
            if new { SoundEngine.shared.play(.click) }
        } label: {
            Image(systemName: on ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Wraps any button style so pressing the button plays the click sound on touch-down,
/// like the prototype's global pointerdown handler.
struct ClickSoundButtonStyle<Base: ButtonStyle>: ButtonStyle {
    var base: Base

    func makeBody(configuration: Configuration) -> some View {
        base.makeBody(configuration: configuration)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    SoundEngine.shared.start()
                    SoundEngine.shared.play(.click)
                }
            }
    }
}
