import SwiftUI
import UIKit
import BalloonBaronCore

/// The menu behind the top-right button (`showMenu`, prototype v106): a settings screen in the game's own look.
/// Rows sit on white cards with the game's hard shadow, each group with its own icon tint; the save code hides
/// behind its own rows, one to copy your code and one to paste and load another.
struct MenuView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.openURL) private var openURL
    @AppStorage("sound") private var soundOn = true
    @AppStorage("haptics") private var hapticsOn = true
    @AppStorage(GameStore.nightSceneKey) private var nightOn = true
    @State private var reminderOn = Reminder.on
    @State private var code = ""
    @State private var pasted = ""
    @State private var message = ""
    /// Which save-code row is open.
    private enum CodeBox { case copy, load }
    @State private var open: CodeBox?
    /// New game needs a second tap to confirm.
    @State private var armed = false

    private static let privacyURL = URL(string: "https://ceude.github.io/balloon-baron/privacy-policy.html")!
    private static let supportURL = URL(string: "https://github.com/ceude/balloon-baron/issues")!

    private enum Tint {
        static let game = Theme.coral
        static let sound = Color(hex: "#14a39a")
        static let notice = Theme.yellow
        static let save = Color(hex: "#3d7fd0")
        static let shop = Color(hex: "#9b7be0")
        static let about = Theme.ink2
        static let danger = Theme.red
    }

    var body: some View {
        ZStack {
            Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { close() }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    content
                    Button(loc("menu.continue")) { close() }
                        .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
                        .padding(.top, 18)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
                .frame(maxWidth: 440, alignment: .leading)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 26))
                .compositingGroup()
                .shadow(color: .black.opacity(0.35), radius: 25, y: 20)
                .padding(16)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            store.save()
            code = store.saveCode ?? ""
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            DesignBalloon(colors: store.state?.colors ?? Rules.palettes[0])
                .frame(width: 26, height: 33)
                .frame(width: 48, height: 48)
                .background(LinearGradient(colors: [Color(hex: "#2f2560"), Color(hex: "#ff8a5a")], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 16))
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.ink.opacity(0.35)).offset(y: 3))
            VStack(alignment: .leading, spacing: 3) {
                Text(loc("settings.title")).font(Theme.font(30, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                if let s = store.state {
                    Text(loc("settings.sub", s.company, num(s.day), s.region.title))
                        .font(Theme.font(13.5, .semibold)).foregroundStyle(Theme.ink2).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button { close() } label: {
                SettingsIcon(kind: .close, width: 2.6)
                    .frame(width: 20, height: 20)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 2))
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.line).offset(y: 3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc("world.close"))
        }
        .padding(.bottom, 4)
    }

    // MARK: Groups

    @ViewBuilder
    private var content: some View {
        let s = store.state
        group(loc("settings.game"), Tint.game) {
            row(.trophy, loc("settings.album"), value: s.map { "\(num($0.achievements.count))/\(num(Achievement.allCases.count))" }) {
                store.showMenu = false
                store.showAlbum = true
            }
            divider
            row(.game, loc("menu.gameCenter")) { GameCenter.openDashboard() }
            divider
            toggleRow(.moon, loc("settings.night"), on: nightOn) { nightOn.toggle() }
        }
        group(loc("settings.soundHaptics"), Tint.sound) {
            toggleRow(.sound, loc("settings.sound"), on: soundOn) {
                soundOn.toggle()
                SoundEngine.shared.enabled = soundOn
            }
            divider
            toggleRow(.haptic, loc("settings.haptics"), on: hapticsOn) {
                hapticsOn.toggle()
                Haptics.tick()
            }
        }
        group(loc("settings.notice"), Tint.notice) {
            toggleRow(.bell, loc("settings.reminder"), on: reminderOn) { toggleReminder() }
        }
        group(loc("settings.save"), Tint.save) {
            row(.cloud, loc("settings.autosaved"), value: s.map { loc("paper.day", num($0.day)) }, info: true)
            divider
            row(.copy, loc("settings.copyCode"), open: open == .copy) { toggle(.copy) }
            divider
            row(.paste, loc("settings.loadCode"), open: open == .load) { toggle(.load) }
        }
        if let open { codeBox(open) }
        if !message.isEmpty && open == nil {
            Text(message).font(Theme.font(13)).foregroundStyle(Theme.ink2).padding(.top, 8)
        }
        group(loc("settings.purchases"), Tint.shop) {
            row(.bag, loc("settings.restore")) {
                Task { @MainActor in await Shop.shared.restore() }
                message = loc("settings.restoring")
            }
        }
        group(loc("settings.about"), Tint.about) {
            row(.shield, loc("settings.privacy")) { openURL(Self.privacyURL) }
            divider
            row(.mail, loc("settings.support")) { openURL(Self.supportURL) }
            divider
            row(.info, loc("settings.version"),
                value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0", info: true)
        }
        group(nil, Tint.danger) {
            row(.trash, loc(armed ? "settings.sure" : "menu.newGame"), danger: true) { newGame() }
        }
    }

    private func group<C: View>(_ title: String?, _ tint: Color, @ViewBuilder rows: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title ?? " ")
                .font(Theme.font(13, .heavy, condensed: true))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Theme.ink2)
                .padding(.horizontal, 6)
                .opacity(title == nil ? 0 : 1)
            VStack(spacing: 0) { rows() }
                .environment(\.settingsTint, tint)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 2))
                .background(RoundedRectangle(cornerRadius: 18).fill(Theme.line).offset(y: 4))
        }
        .padding(.top, 16)
    }

    private var divider: some View {
        Rectangle().fill(Theme.line).frame(height: 2).padding(.leading, 62)
    }

    private func row(_ icon: SettingsIcon.Kind, _ title: String, value: String? = nil, open: Bool = false, info: Bool = false,
                     danger: Bool = false, action: (() -> Void)? = nil) -> some View {
        SettingsRow(icon: icon, title: title, value: value, open: open, info: info, danger: danger, toggle: nil, action: action)
    }

    private func toggleRow(_ icon: SettingsIcon.Kind, _ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        SettingsRow(icon: icon, title: title, value: nil, open: false, info: false, danger: false, toggle: on, action: action)
    }

    // MARK: Save code

    private func codeBox(_ kind: CodeBox) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc(kind == .copy ? "settings.copyHint" : "settings.loadHint"))
                .font(Theme.font(13)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
            ZStack(alignment: .topLeading) {
                if kind == .load && pasted.isEmpty {
                    Text(loc("settings.pastePlaceholder")).font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.ink2.opacity(0.7)).padding(.horizontal, 11).padding(.vertical, 14)
                }
                TextEditor(text: kind == .copy ? .constant(code) : $pasted)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .scrollContentBackground(.hidden)
                    .padding(6)
            }
            .frame(height: 84)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1.5))
            HStack(spacing: 10) {
                if kind == .copy {
                    codeButton(loc("menu.copy"), primary: true) {
                        UIPasteboard.general.string = code
                        message = loc("menu.copied")
                    }
                } else {
                    codeButton(loc("settings.paste")) {
                        pasted = UIPasteboard.general.string ?? ""
                    }
                    codeButton(loc("menu.load"), primary: true) {
                        if !store.load(code: pasted) { message = loc("menu.badCode") }
                    }
                }
            }
            if !message.isEmpty {
                Text(message).font(Theme.font(13)).foregroundStyle(Theme.ink2)
            }
        }
        .padding(12)
        .background(Color(hex: "#f6f3fb"), in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 10)
    }

    private func codeButton(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            SoundEngine.shared.play(.click)
            action()
        } label: {
            Text(title).frame(minWidth: 70)
        }
        .buttonStyle(ChunkyButtonStyle(kind: primary ? .big : .ghost, height: 42))
        .fixedSize()
    }

    // MARK: Actions

    private func toggle(_ k: CodeBox) {
        message = ""
        withAnimation(.easeOut(duration: 0.2)) { open = open == k ? nil : k }
    }

    private func close() {
        SoundEngine.shared.play(.click)
        store.closeMenu()
    }

    private func toggleReminder() {
        if reminderOn {
            Reminder.turnOff()
            reminderOn = false
        } else {
            Reminder.turnOn { granted in
                reminderOn = granted
                message = granted ? "" : loc("menu.reminderDenied")
            }
        }
    }

    private func newGame() {
        guard armed else {
            armed = true
            return
        }
        store.startOver()
    }
}

/// One settings row: a tinted icon tile, the title, and a value, a chevron or a switch.
private struct SettingsRow: View {
    @Environment(\.settingsTint) private var tint
    let icon: SettingsIcon.Kind
    let title: String
    let value: String?
    let open: Bool
    let info: Bool
    let danger: Bool
    /// The switch's state, for a toggle row.
    let toggle: Bool?
    let action: (() -> Void)?

    var body: some View {
        if let action {
            Button {
                SoundEngine.shared.play(.click)
                action()
            } label: { label }
            .buttonStyle(SettingsPressStyle())
            .accessibilityAddTraits(toggle != nil ? .isButton : [])
            .accessibilityValue(toggle.map { loc($0 ? "a11y.on" : "a11y.off") } ?? value ?? "")
        } else {
            label.accessibilityElement(children: .combine)
        }
    }

    private var label: some View {
        HStack(spacing: 12) {
            SettingsIcon(kind: icon, color: tint)
                .frame(width: 21, height: 21)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .background(RoundedRectangle(cornerRadius: 12).fill(tint.opacity(0.28)).offset(y: 2))
            Text(title)
                .font(Theme.font(18, info ? .semibold : .bold, condensed: true))
                .foregroundStyle(danger ? Theme.red : info ? Theme.ink2 : Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let value {
                Text(value).font(Theme.font(14, .bold)).foregroundStyle(Theme.ink2)
            }
            if let toggle {
                SettingsSwitch(on: toggle)
            } else if action != nil && !danger {
                SettingsIcon(kind: open ? .down : .chevron, color: open ? tint : Color(hex: "#b9b1cc"), width: 2.6)
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

/// The game's switch: a green pill with a white knob that has a hard little shadow.
private struct SettingsSwitch: View {
    let on: Bool

    var body: some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule().fill(on ? Theme.green : Color(hex: "#e6e0f0"))
                .overlay(Capsule().stroke(Theme.ink.opacity(on ? 0 : 0.08), lineWidth: 1))
            Circle().fill(Color.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.ink.opacity(0.25)).offset(y: 2))
                .padding(3)
        }
        .frame(width: 52, height: 32)
        .animation(.easeOut(duration: 0.18), value: on)
        .accessibilityHidden(true)
    }
}

private struct SettingsPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(configuration.isPressed ? Color(hex: "#f6f3fb") : Color.clear)
    }
}

private struct SettingsTintKey: EnvironmentKey { static let defaultValue: Color = Theme.ink }
extension EnvironmentValues {
    var settingsTint: Color {
        get { self[SettingsTintKey.self] }
        set { self[SettingsTintKey.self] = newValue }
    }
}
