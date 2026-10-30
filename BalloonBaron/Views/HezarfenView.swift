import SwiftUI
import BalloonBaronCore

/// Master Hezarfen's speech bubble with a typewriter effect. Tap the bubble to finish typing.
/// A rival boss and the aviation inspector speak through the same bubble with their own faces, and outside
/// Cappadocia the region's own guide does the talking (Hezarfen still says goodbye when you enter a region).
struct HezarfenView: View {
    let message: HezMessage
    var day = 1
    let onClose: () -> Void
    @State private var shown = 0
    /// v122: "More" was tapped: the whole lesson, at once.
    @State private var long = false

    /// v122 (`HEZ_SHORT`): the lessons of the first days say one sentence; the old text is behind "More".
    static let shortTips: Set<Tip> = [.welcome, .insurance, .fleet, .bank, .crew, .market, .guide, .agency, .bazaar, .workshop, .school,
                                      .goals, .price, .priceRep, .priceRiv, .price3, .yellow, .red, .mission, .accident, .pr, .rivals, .aging]

    private var shortKey: String? {
        if case .tip(let t) = message, Self.shortTips.contains(t) { return "tip.\(t.rawValue).short" }
        return nil
    }

    private var boss: (RegionID, BossLine)? {
        if case let .boss(r, l) = message { return (r, l) }
        return nil
    }

    /// v125: a contract company's owner speaks, with their own face and a name tag in their color.
    private var owner: ContractOwner? {
        if case let .contract(w, _, _, _) = message { return w }
        return nil
    }

    private var inspector: Bool {
        if case .inspector = message { return true }
        return false
    }

    /// Whose face and name: Hezarfen when you enter a region, the new guide when they introduce themselves, else the region's guide.
    private var guide: RegionID {
        switch message {
        case .enteredRegion: .cap
        case .guideHello(let r): r
        default: currentRegion
        }
    }

    private var button: String {
        if let (_, l) = boss { return loc(["boss.ok.0", "boss.ok.1", "boss.ok.2"][(day + l.rawValue.count) % 3]) }
        if case .praise = message { return loc("hez.thanks") }
        if case .deed = message { return loc("hez.thanks") }
        if case .milestone = message { return loc("hez.thanks") }
        if message == .tip(.show) { return loc("hez.toShow") }
        if message == .tip(.price) || message == .tip(.price3) { return loc("hez.toPrice") }
        return loc(message == .tip(.bazaar) ? "hez.toBazaar" : "hez.ok")
    }

    var body: some View {
        let short = long ? nil : shortKey
        let text = short.map { loc($0) } ?? message.text
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
            HStack(alignment: .bottom, spacing: 10) {
                VStack(spacing: 4) {
                    if let w = owner {
                        ContractAvatar(owner: w, size: 64)
                        Text(w.short)
                            .font(Theme.font(13, .heavy, condensed: true))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9).padding(.vertical, 3)
                            .background(Color(hex: w.color), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                            .fixedSize()
                            .offset(y: -8)
                    } else if let (r, _) = boss {
                        BossAvatar(region: r, size: 64)
                        Text(loc("boss.\(r.rawValue).name"))
                            .font(Theme.font(12, .bold, condensed: true))
                            .foregroundStyle(Color(hex: "#bfe0ff"))
                            .fixedSize()
                    } else if inspector {
                        InspectorAvatar(size: 64)
                        Text(loc("insp.name.\(currentRegion.rawValue)"))
                            .font(Theme.font(12, .bold, condensed: true))
                            .foregroundStyle(Color(hex: "#bfe0ff"))
                            .fixedSize()
                    } else {
                        GuideAvatar(region: guide, size: 64)
                        Text(guideName(guide))
                            .font(Theme.font(12, .bold, condensed: true))
                            .foregroundStyle(.white)
                            .fixedSize()
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    if let w = owner {
                        Text(w.role).font(Theme.font(11.5, .bold)).foregroundStyle(Theme.ink2)
                    } else if let (r, _) = boss {
                        Text(loc("boss.\(r.rawValue).title"))
                            .font(Theme.font(11.5, .bold)).foregroundStyle(Theme.ink2)
                    } else if inspector {
                        Text(loc("insp.title.\(currentRegion.rawValue)"))
                            .font(Theme.font(11.5, .bold)).foregroundStyle(Theme.ink2)
                    }
                    // The full text reserves the bubble's height so it doesn't grow while typing.
                    ZStack(alignment: .topLeading) {
                        Text(text).opacity(0)
                        Text(String(text.prefix(shown)))
                    }
                    .font(Theme.font(17, .medium))
                    .foregroundStyle(Theme.ink)
                    if short != nil {
                        HStack(spacing: 10) {
                            Button {
                                SoundEngine.shared.play(.click)
                                long = true
                            } label: {
                                Text(loc("tut.more")).font(Theme.font(13.5, .bold)).underline().foregroundStyle(Theme.ink2)
                                    .lineLimit(1).fixedSize()
                            }
                            .buttonStyle(.plain)
                            BigButton(title: button) {
                                if shown < text.count { shown = text.count } else { onClose() }
                            }
                        }
                    } else {
                        BigButton(title: button) {
                            if shown < text.count { shown = text.count } else { onClose() }
                        }
                    }
                }
                .padding(16)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 22))
                .onTapGesture { shown = text.count }
            }
            .padding(16)
        }
        .onChange(of: message) { _, _ in long = false }
        .task(id: text) {
            // The long lesson behind "More" comes at once.
            if long { shown = text.count; return }
            shown = 0
            while shown < text.count {
                try? await Task.sleep(for: .milliseconds(22))
                shown = min(text.count, shown + 2)
            }
        }
    }
}
