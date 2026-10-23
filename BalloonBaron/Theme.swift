import SwiftUI
import CoreText
import BalloonBaronCore

/// Design tokens from the HTML prototype.
enum Theme {
    static let ink = Color(hex: "#2b2350")
    static let ink2 = Color(hex: "#6c6488")
    static let coral = Color(hex: "#ff5e3a")
    static let sun = Color(hex: "#ffc23d")
    static let paper = Color(hex: "#fffaf3")
    static let glass = Color(red: 30 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.84)
    static let green = Color(hex: "#22a45d")
    static let yellow = Color(hex: "#e0a400")
    static let red = Color(hex: "#e5432f")
    static let line = Color(hex: "#e2dcef")
    /// A button you can't press yet: grey with readable grey text, never a faded coral that hides its price.
    static let offFill = Color(hex: "#e6e1ef")
    static let offText = Color(hex: "#857d9f")

    static let sky = LinearGradient(colors: [Color(hex: "#2f2560"), Color(hex: "#b9506a"), Color(hex: "#ffae6a")],
                                    startPoint: .top, endPoint: .bottom)

    /// Barlow for Latin scripts; iOS falls back to the system font for Japanese and Korean glyphs.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular, condensed: Bool = false) -> Font {
        let name: String
        if condensed {
            name = weight == .heavy || weight == .black ? "BarlowCondensed-ExtraBold" : weight == .bold ? "BarlowCondensed-Bold" : "BarlowCondensed-SemiBold"
        } else {
            switch weight {
            case .heavy, .black: name = "Barlow-ExtraBold"
            case .bold: name = "Barlow-Bold"
            case .semibold: name = "Barlow-SemiBold"
            case .medium: name = "Barlow-Medium"
            default: name = "Barlow-Regular"
            }
        }
        return .custom(name, size: size, relativeTo: .body)
    }

    /// Fonts ship in the bundle; registering at launch avoids Info.plist entries.
    static func registerFonts() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
    }

    static func flagColor(_ f: Flag) -> Color {
        switch f {
        case .green: green
        case .yellow: yellow
        case .red: red
        }
    }
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xff) / 255, green: Double((v >> 8) & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }
}

/// Big tappable button used across the office screens.
struct BigButton: View {
    let title: String
    var style: Style = .primary
    let action: () -> Void

    enum Style { case primary, ghost }

    var body: some View {
        Button {
            SoundEngine.shared.play(.click)
            action()
        } label: {
            Text(title)
                .font(Theme.font(19, .heavy, condensed: true))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(style == .primary ? .white : Theme.ink)
                .background(style == .primary ? Theme.coral : Color.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(style == .ghost ? Theme.line : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

/// The prototype's `.pdone`: a small centered "Done" at the end of every office page.
struct PageDoneButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            SoundEngine.shared.play(.click)
            action()
        } label: {
            Text(loc("home.done"))
                .font(Theme.font(18, .heavy, condensed: true))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .padding(.horizontal, 26)
                .frame(minWidth: 140, minHeight: 44)
                .background(Theme.coral, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }
}

/// The band of a chunky button's depth that shows below it, like the prototype's `box-shadow: 0 Npx 0`: only the part
/// outside the button, so it never darkens the face (which matters for the see-through glass buttons).
struct DepthBand: Shape {
    var radius: CGFloat
    var drop: CGFloat

    var animatableData: CGFloat {
        get { drop }
        set { drop = newValue }
    }

    func path(in r: CGRect) -> Path {
        Path(roundedRect: r.offsetBy(dx: 0, dy: drop), cornerRadius: radius)
            .subtracting(Path(roundedRect: r, cornerRadius: radius))
    }
}
