import SwiftUI
import BalloonBaronCore

/// Breaking news: two rivals joined forces against you.
struct MergeView: View {
    @Environment(GameStore.self) private var store
    let news: MergeNews

    var body: some View {
        WorldPopup(topBar: Theme.red) {
            icons
            Text(loc("merge.tag"))
                .font(Theme.font(13, .heavy, condensed: true))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Theme.red, in: RoundedRectangle(cornerRadius: 8))
            Text(loc("merge.title"))
                .font(Theme.font(28, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            Text(loc("merge.body", news.a, news.b, percent(Double(news.sharePercent) / 100), news.name))
                .font(Theme.font(16, .medium))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                stat(num(news.balloons), loc("merge.balloons"))
                stat(eur(news.cash), loc("merge.cash"))
                stat(starsValue(Rules.stars(news.rep)), loc("merge.popularity"))
            }
            Text(loc("merge.hint"))
                .font(Theme.font(14))
                .foregroundStyle(Theme.ink2)
            BigButton(title: loc("merge.ready")) { store.dismissPopup() }
        }
    }

    private var icons: some View {
        HStack(spacing: 6) {
            BalloonShape(colors: [color(0, "#9a8fb8"), color(1, "#ffffff")])
                .frame(width: 46, height: 58)
            Text("+")
                .font(Theme.font(28, .heavy, condensed: true))
                .foregroundStyle(Theme.ink2)
            BalloonShape(colors: [color(2, "#9a8fb8"), "#ffffff"])
                .frame(width: 46, height: 58)
        }
    }

    private func color(_ i: Int, _ fallback: String) -> String {
        news.colors.indices.contains(i) ? news.colors[i] : fallback
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.font(20, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(Theme.font(12, .semibold))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 12))
    }
}
