import SwiftUI
import BalloonBaronCore

/// `updateChirp()`: a passenger review that slides in under the HUD for 8 s every 30 s,
/// cycling through the latest 6 reviews. Renders nothing until there are reviews.
struct ReviewChirpView: View {
    @Environment(GameStore.self) private var store
    @State private var shown: Review?
    @State private var visible = false
    @State private var index = 0

    var body: some View {
        let reviews = store.state?.reviews ?? []
        let company = store.state?.company ?? ""
        let designs = store.state?.designs ?? []
        let active = !reviews.isEmpty && store.hezarfen == nil && store.page == nil
        ZStack {
            if active, visible, let r = shown {
                ReviewCard(review: r, company: company, designs: designs, compact: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: 440, alignment: .leading)
                    .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(red: 20 / 255, green: 10 / 255, blue: 40 / 255).opacity(0.25), radius: 7, y: 4)
                    .transition(.opacity.combined(with: .offset(y: -8)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: visible)
        .task { await cycle() }
    }

    /// First chirp after 2 s, then one every 30 s, each shown for 8 s.
    @MainActor
    private func cycle() async {
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            while !Task.isCancelled {
                let latest = Array((store.state?.reviews ?? []).prefix(6))
                if !latest.isEmpty {
                    shown = latest[index % latest.count]
                    index += 1
                    visible = true
                }
                try await Task.sleep(nanoseconds: 8_000_000_000)
                visible = false
                try await Task.sleep(nanoseconds: 22_000_000_000)
            }
        } catch {
            return
        }
    }
}

/// `revHTML()`: avatar initial, name, home and day, stars, text.
struct ReviewCard: View {
    let review: Review
    let company: String
    var designs: [Design] = []
    /// The chirp clamps the text to two lines.
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(String(review.name.prefix(1)))
                .font(Theme.font(15, .heavy, condensed: true))
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background(Self.avatarColor(review.name), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                (Text(review.name).font(Theme.font(14, .bold)).foregroundColor(Theme.ink)
                    + Text("  " + review.place + ", " + loc("review.day", num(review.day))).font(Theme.font(12.5)).foregroundColor(Theme.ink2))
                    .lineLimit(1)
                Text(Self.starString(review.stars))
                    .font(.system(size: 13))
                    .kerning(1)
                    .foregroundStyle(Color(hex: "#f0a000"))
                Text(review.text(company: company, designs: designs))
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(compact ? 2 : nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, compact ? 0 : 2)
            }
            Spacer(minLength: 0)
        }
    }

    static func starString(_ n: Int) -> String {
        let k = max(0, min(5, n))
        return String(repeating: "★", count: k) + String(repeating: "☆", count: 5 - k)
    }

    /// `avatarCol()`: hue hashed from the name, hsl(h, 55%, 52%).
    static func avatarColor(_ name: String) -> Color {
        var h = 0
        for u in name.utf16 { h = (h * 31 + Int(u)) % 360 }
        return hsl(Double(h), 0.55, 0.52)
    }

    private static func hsl(_ h: Double, _ s: Double, _ l: Double) -> Color {
        let c = (1 - abs(2 * l - 1)) * s
        let hp = h / 60
        let x = c * (1 - abs(hp.truncatingRemainder(dividingBy: 2) - 1))
        let rgb: (Double, Double, Double)
        switch hp {
        case ..<1: rgb = (c, x, 0)
        case ..<2: rgb = (x, c, 0)
        case ..<3: rgb = (0, c, x)
        case ..<4: rgb = (0, x, c)
        case ..<5: rgb = (x, 0, c)
        default: rgb = (c, 0, x)
        }
        let m = l - c / 2
        return Color(red: rgb.0 + m, green: rgb.1 + m, blue: rgb.2 + m)
    }
}
