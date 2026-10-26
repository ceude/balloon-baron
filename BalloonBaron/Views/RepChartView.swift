import SwiftUI
import BalloonBaronCore

/// `showRepChart()`: popularity over the last 60 days, ways to raise it, and passenger reviews.
/// Opened from the HUD stars chip.
struct RepChartView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ModalCard(onClose: close) {
            if let s = store.state {
                content(s)
            }
            Button(loc("home.close")) {
                SoundEngine.shared.play(.click)
                close()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }

    @ViewBuilder
    private func content(_ s: GameState) -> some View {
        let hist = Array(s.repHistory.suffix(60))
        CardText.title(loc("repChart.title", starsText(s.rep)))
        if hist.count < 2 {
            CardText.lead(loc("repChart.empty"))
        } else {
            RepChart(points: hist)
                .frame(height: 170)
                .accessibilityLabel(loc("repChart.chartLabel"))
            CardText.lead(delta(hist))
        }
        if s.rep < Rules.crisisRep {
            ProtoCallout(tone: .red, title: loc("repChart.crisisTitle", starsValue(Rules.stars(Rules.crisisRep))),
                         text: loc("repChart.crisisBody"))
        }
        CardText.hint(loc("repChart.hint", num(bonus), starsValue(4.5)))
        heading(loc("repChart.recover"))
        actions(s)
        heading(loc("repChart.reviews"))
        reviews(s)
    }

    private var bonus: Int { store.game?.popularityBonus() ?? 0 }

    /// Change over the last week of points (up to 8).
    private func delta(_ hist: [RepPoint]) -> String {
        let wk = Array(hist.suffix(8))
        guard let first = wk.first, let last = wk.last else { return "" }
        let d = Rules.stars(last.rep) - Rules.stars(first.rep)
        let v = abs(d).formatted(.number.precision(.fractionLength(0...2)))
        return loc("repChart.delta", num(first.day), (d >= 0 ? "+" : "−") + v + "★")
    }

    private func heading(_ t: String) -> some View {
        Text(t).font(Theme.font(22, .heavy, condensed: true)).foregroundStyle(Theme.ink)
    }

    // MARK: Actions

    @ViewBuilder
    private func actions(_ s: GameState) -> some View {
        let ads = s.balloons.filter { $0.ad != nil }.count
        let icd = s.influencerCooldown - s.day
        let gcd = s.guideCooldown - s.day
        let hotels = s.activeHotels.count
        if ads > 0 {
            row(loc("marketPage.removeAds"), loc("marketPage.removeAdsBody", num(ads)), button: loc("marketPage.remove"), disabled: false) {
                store.act { $0.removeAllAds() }
                close()
            }
        }
        row(loc("repChart.hotels"),
            loc("repChart.hotelsBody") + " " + (hotels > 0 ? loc("repChart.hotelsCount", num(hotels)) : loc("repChart.hotelsNone")),
            button: loc("repChart.hotelsButton"), disabled: false) {
            store.showRepChart = false
            store.page = .market
        }
        row(loc("marketPage.influencer"),
            icd > 0 ? loc("marketPage.wait", num(icd)) : s.day <= s.influencerUntil ? loc("marketPage.running") : loc("marketPage.influencerBody"),
            button: eur(s.influencerCost), disabled: icd > 0 || s.cash < s.influencerCost) {
            store.act { _ = $0.runInfluencer() }
            close()
        }
        row(loc("marketPage.guide"), gcd > 0 ? loc("marketPage.wait", num(gcd)) : loc("marketPage.guideBody"),
            button: eur(Rules.guideCost), disabled: gcd > 0 || s.cash < Rules.guideCost) {
            store.act { _ = $0.runGuideFlight() }
            close()
        }
        if let g = store.game, ShowCardView.offered(g) {
            let st = g.showState
            row(loc("show.openTitle"), st == .ok ? loc("show.rowBody", num(g.showFleet.count)) : ShowCardView.why(st, g),
                button: eur(g.showCost), disabled: st != .ok) {
                close()
                store.showShowCard = true
            }
        }
    }

    private func row(_ title: String, _ detail: String, button: String, disabled: Bool,
                     action: @escaping () -> Void) -> some View {
        FleetUI.Item {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(title)
                    FleetUI.Detail(detail)
                }
                Spacer(minLength: 4)
                FleetUI.SmallButton(title: button, disabled: disabled) {
                    SoundEngine.shared.play(.click)
                    action()
                }
                .frame(width: 110)
            }
        }
    }

    // MARK: Reviews

    @ViewBuilder
    private func reviews(_ s: GameState) -> some View {
        let share = Rules.popularitySeatShare * min(1, max(0, (s.rep - 0.7) / 0.7))
        ProtoCallout(tone: .green, title: loc("repChart.bonusTitle", starsText(s.rep)),
                     text: loc("repChart.bonusBody", percent(share), num(bonus), starsValue(2.8), starsValue(5),
                               percent(Rules.popularitySeatShare)))
        if s.reviews.isEmpty {
            CardText.hint(loc("repChart.noReviews"))
        } else {
            let sv = Rules.stars(s.rep)
            HStack(spacing: 12) {
                Text(sv.formatted(.number.precision(.fractionLength(1))))
                    .font(Theme.font(44, .heavy, condensed: true))
                    .foregroundStyle(Theme.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ReviewCard.starString(Int(sv.rounded())))
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#f0a000"))
                    CardText.hint(loc("repChart.rating"))
                }
            }
            let list = Array(s.reviews.prefix(8))
            ForEach(list.indices, id: \.self) { i in
                FleetUI.Item {
                    ReviewCard(review: list[i], company: s.company, designs: s.designs)
                }
            }
        }
    }

    private func close() {
        store.showRepChart = false
        store.showNextHezarfen()
    }
}

/// The prototype's SVG line chart of popularity stars (1–5) by day.
private struct RepChart: View {
    let points: [RepPoint]

    var body: some View {
        let stars = points.map { Rules.stars($0.rep) }
        let firstDay = points.first?.day ?? 0
        let lastDay = points.last?.day ?? 0
        return Canvas { ctx, size in
            let left: CGFloat = 30, right: CGFloat = 34, top: CGFloat = 12, bottom: CGFloat = 24
            let n = max(2, stars.count)
            let w = size.width, h = size.height
            func x(_ i: Int) -> CGFloat { left + (w - left - right) * CGFloat(i) / CGFloat(n - 1) }
            func y(_ v: Double) -> CGFloat { top + (h - top - bottom) * CGFloat(5 - v) / 4 }

            for v in 1...5 {
                var grid = Path()
                grid.move(to: CGPoint(x: left, y: y(Double(v))))
                grid.addLine(to: CGPoint(x: w - right, y: y(Double(v))))
                ctx.stroke(grid, with: .color(Theme.line), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                ctx.draw(Text(verbatim: "\(v)★").font(Theme.font(11)).foregroundColor(Theme.ink2),
                         at: CGPoint(x: left - 6, y: y(Double(v))), anchor: .trailing)
            }
            guard let lastStar = stars.last else { return }
            var line = Path()
            for (i, v) in stars.enumerated() {
                let p = CGPoint(x: x(i), y: y(v))
                if i == 0 { line.move(to: p) } else { line.addLine(to: p) }
            }
            let lx = x(stars.count - 1), ly = y(lastStar)
            var area = line
            area.addLine(to: CGPoint(x: lx, y: y(1)))
            area.addLine(to: CGPoint(x: left, y: y(1)))
            area.closeSubpath()
            ctx.fill(area, with: .color(Theme.coral.opacity(0.12)))
            ctx.stroke(line, with: .color(Theme.coral), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            let dot = Path(ellipseIn: CGRect(x: lx - 4.5, y: ly - 4.5, width: 9, height: 9))
            ctx.fill(dot, with: .color(Theme.coral))
            ctx.stroke(dot, with: .color(.white), lineWidth: 2)
            ctx.draw(Text(lastStar.formatted(.number.precision(.fractionLength(0...1)))).font(Theme.font(12, .bold)).foregroundColor(Theme.ink),
                     at: CGPoint(x: lx + 7, y: ly), anchor: .leading)
            ctx.draw(Text(loc("hud.day", num(firstDay))).font(Theme.font(11)).foregroundColor(Theme.ink2),
                     at: CGPoint(x: left, y: h - 6), anchor: .bottomLeading)
            ctx.draw(Text(loc("hud.day", num(lastDay))).font(Theme.font(11)).foregroundColor(Theme.ink2),
                     at: CGPoint(x: w - right, y: h - 6), anchor: .bottomTrailing)
        }
    }
}
