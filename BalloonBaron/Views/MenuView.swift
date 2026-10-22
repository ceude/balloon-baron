import SwiftUI
import UIKit
import BalloonBaronCore

/// The prototype's `showMenu`: save note, save code (copy / load), sound, new game, continue.
struct MenuView: View {
    @Environment(GameStore.self) private var store
    @AppStorage("sound") private var soundOn = true
    @State private var code = ""
    @State private var message = ""
    /// New game needs a second tap to confirm.
    @State private var armed = false

    var body: some View {
        let s: GameState? = store.state
        return ModalCard {
            CardText.title(loc("menu.title"))
            if let s {
                Button {
                    SoundEngine.shared.play(.click)
                    store.showMenu = false
                    store.showAlbum = true
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(loc("menu.album")).font(Theme.font(15.5, .bold)).foregroundStyle(Theme.ink)
                        Text(loc("album.count", num(s.achievements.count), num(Achievement.allCases.count)))
                            .font(Theme.font(13)).foregroundStyle(Theme.ink2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 2))
                }
                .buttonStyle(.plain)
                CardText.hint(loc("menu.saved", num(s.day), eur(s.cash)))
            }
            Text(loc("menu.code"))
                .font(Theme.font(22, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            CardText.hint(loc("menu.codeHint"))
            codeBox
            codeButtons
            if !message.isEmpty {
                CardText.hint(message)
            }
            settingButton(loc(soundOn ? "menu.soundOn" : "menu.soundOff")) { toggleSound() }
            settingButton(loc(armed ? "menu.sure" : "menu.newGame")) { newGame() }
            Button(loc("menu.continue")) {
                SoundEngine.shared.play(.click)
                store.closeMenu()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
        .onAppear {
            store.save()
            code = store.saveCode ?? ""
        }
    }

    private var codeBox: some View {
        TextEditor(text: $code)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(Theme.ink)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .scrollContentBackground(.hidden)
            .padding(6)
            .frame(height: 84)
            .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }

    private var codeButtons: some View {
        HStack(spacing: 10) {
            settingButton(loc("menu.copy")) {
                UIPasteboard.general.string = code
                message = loc("menu.copied")
            }
            settingButton(loc("menu.load")) {
                if !store.load(code: code) {
                    message = loc("menu.badCode")
                }
            }
        }
    }

    private func settingButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundEngine.shared.play(.click)
            action()
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(kind: .ghost, height: 46))
    }

    private func toggleSound() {
        let new: Bool = !soundOn
        SoundEngine.shared.enabled = new
        soundOn = new
    }

    private func newGame() {
        guard armed else {
            armed = true
            return
        }
        store.startOver()
    }
}
