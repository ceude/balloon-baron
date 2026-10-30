import SwiftUI
import UIKit
import UniformTypeIdentifiers
import BalloonBaronCore

/// The menu behind the top-right button (`showMenu`, prototype v106): a settings screen in the game's own look.
/// Rows sit on white cards with the game's hard shadow, each group with its own icon tint; the save code hides
/// behind its own rows, one to copy your code and one to paste and load another.
struct MenuView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("sound") private var soundOn = true
    @AppStorage("haptics") private var hapticsOn = true
    @AppStorage(GameStore.nightSceneKey) private var nightOn = true
    @AppStorage(GameStore.collectSceneKey) private var collectOn = true
    @State private var reminderOn = Reminder.on
    @State private var code = ""
    @State private var pasted = ""
    @State private var message = ""
    /// v124.3: the code written to a small text file to share (AirDrop, Messages, Files), and the file picker to load one.
    @State private var codeFile: URL?
    @State private var importing = false
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
        static let film = Theme.coral
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
        .overlay(alignment: .top) { ToastView(text: store.toast) }
        .onAppear {
            store.save()
            code = store.saveCode ?? ""
            codeFile = Self.writeCodeFile(code, company: store.game?.state.company ?? "")
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText, .text, .data]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { message = loc("menu.badCode"); return }
            pasted = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !store.load(code: pasted) { message = loc("menu.badCode") }
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
            divider
            toggleRow(.people, loc("settings.collect"), on: collectOn) { collectOn.toggle() }
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
        // v121.10: the opening film again, over the running game (it is Cappadocia's, so only there)
        if s?.region == .cap && !reduceMotion && OpeningLoader.supported {
            group(loc("settings.film"), Tint.film) {
                row(.film, loc("settings.replayOpening")) { store.replayOpening() }
            }
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
            if kind == .copy {
                HStack(spacing: 10) {
                    codeButton(loc("menu.copy"), primary: true) {
                        UIPasteboard.general.string = code
                        // v125.6: the green-check toast, like the rest of the game
                        message = ""
                        store.showToast(loc("menu.copied").trimmingCharacters(in: CharacterSet(charactersIn: ".。")))
                    }
                    if let codeFile {
                        ShareLink(item: codeFile) {
                            Text(loc("settings.shareCode")).frame(minWidth: 70)
                        }
                        .buttonStyle(ChunkyButtonStyle(kind: .ghost, height: 42))
                        .fixedSize()
                        .simultaneousGesture(TapGesture().onEnded { SoundEngine.shared.play(.click) })
                    }
                }
            }
            if kind == .load {
                // v125.6: Paste / From file / Load wrap to two lines on a small phone (German, Spanish)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { loadButtons }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) { pasteButton; fileButton }
                        loadButton
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

    @ViewBuilder private var loadButtons: some View {
        pasteButton
        fileButton
        loadButton
    }

    private var pasteButton: some View {
        codeButton(loc("settings.paste")) { pasted = UIPasteboard.general.string ?? "" }
    }

    private var fileButton: some View {
        codeButton(loc("settings.fromFile")) {
            message = ""
            importing = true
        }
    }

    private var loadButton: some View {
        codeButton(loc("menu.load"), primary: true) {
            if !store.load(code: pasted) { message = loc("menu.badCode") }
        }
    }

    /// "BalloonBaron-<company>.txt" in the temporary folder, holding the save code.
    private static func writeCodeFile(_ code: String, company: String) -> URL? {
        guard !code.isEmpty else { return nil }
        let parts = company.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let name = "BalloonBaron" + (parts.isEmpty ? "" : "-" + parts.joined(separator: "-")) + ".txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do { try code.write(to: url, atomically: true, encoding: .utf8) } catch { return nil }
        return url
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
/// The game's own switch (v110), in the chunky buttons' style: a pill with a hard drop shadow, coral when on, with a
/// white knob that carries a small coral dot when on.
private struct SettingsSwitch: View {
    let on: Bool

    var body: some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule().fill(on ? Theme.coral : Color(hex: "#ebe6f4"))
                .background(Capsule().fill(on ? Color(hex: "#d9411f") : Theme.line).offset(y: 3))
                .overlay(Capsule().stroke(Theme.ink.opacity(on ? 0 : 0.06), lineWidth: 1))
            Circle().fill(Color.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Theme.ink.opacity(0.22)).offset(y: 2))
                .overlay(Circle().fill(Theme.coral).frame(width: 8, height: 8).opacity(on ? 1 : 0))
                .padding(4)
        }
        .frame(width: 54, height: 32)
        .padding(.bottom, 3)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: on)
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
