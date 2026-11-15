import SwiftUI
import BalloonBaronCore

/// v143: a parked region's autopilot report, opened from its card on the holding's Regions page. How yesterday's
/// autopilot money was worked out (the core's `AutoDay`, exactly what `holdingDay` booked), the last seven days, and
/// the region as you left it (`AutoSnapshot`: its last days' report lines on average, seats, fleet, prices), with a
/// way back there to tune it.
struct AutoReportView: View {
    @Environment(GameStore.self) private var store
    let region: RegionID

    var body: some View {
        WorldPopup(topBar: Theme.coral, onClose: close) {
            if let auto = store.state?.parked[region]?.auto {
                header(auto)
                today(auto)
                if let week = auto.week, !week.isEmpty { sparkline(week) }
                left(auto)
                Text(loc("autoRep.explain"))
                    .font(Theme.font(13.5))
                    .foregroundStyle(Theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                BigButton(title: loc("map.go")) { store.goTo(region) }
            }
        }
    }

    private func close() {
        SoundEngine.shared.play(.click)
        store.autoReport = nil
    }

    // MARK: Parts

    private func header(_ auto: Autopilot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(loc("autoRep.kicker"))
                .font(Theme.font(13, .heavy, condensed: true))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Theme.coral)
            Text(region.title)
                .font(Theme.font(28, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            Text(loc("autoRep.sub", num(auto.left?.day ?? auto.since)))
                .font(Theme.font(14))
                .foregroundStyle(Theme.ink2)
        }
        .padding(.trailing, 30)
    }

    @ViewBuilder
    private func today(_ auto: Autopilot) -> some View {
        if let d = auto.lastDay {
            VStack(alignment: .leading, spacing: 5) {
                sectionTitle(loc("autoRep.yesterday", num(d.day)))
                row(loc("autoRep.base"), eurH(Int(d.base.rounded())))
                row(loc("autoRep.swing"), Self.change(d.swing), color: d.swing >= 1 ? Theme.green : Theme.red)
                ForEach(d.factors.indices, id: \.self) { i in
                    let f = d.factors[i]
                    row(loc("autoRep.f.\(f.kind.rawValue)"), Self.change(f.mult), color: f.mult >= 1 ? Theme.green : Theme.red)
                }
                total(loc("autoRep.gross"), eurH(d.gross))
                row(loc("autoRep.expense", percent(d.expenseRate)), "−" + eurH(d.expense), color: Theme.red)
                if d.rent > 0 { row(loc("autoRep.rent"), "−" + eurH(d.rent), color: Theme.red) }
                if d.sent || d.kept == nil {
                    total(loc("autoRep.toHolding"), eurH(d.net), color: d.net >= 0 ? Theme.green : Theme.red)
                } else {
                    total(loc("autoRep.kept"), money(d.kept ?? 0, in: region), color: Theme.green)
                }
            }
        } else {
            Text(loc("autoRep.firstEvening"))
                .font(Theme.font(14))
                .foregroundStyle(Theme.ink2)
        }
    }

    private func sparkline(_ week: [Int]) -> some View {
        let lo = week.min() ?? 0, hi = max(lo + 1, week.max() ?? 1)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(loc("autoRep.week")).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
                Spacer(minLength: 6)
                Text(eurH(week.last ?? 0)).font(Theme.font(13, .bold, condensed: true)).foregroundStyle(Theme.ink).monospacedDigit()
            }
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                let pts = week.indices.map { i -> CGPoint in
                    let x = week.count > 1 ? w * CGFloat(i) / CGFloat(week.count - 1) : w / 2
                    let y = h - 4 - (h - 8) * CGFloat(Double(week[i] - lo) / Double(hi - lo))
                    return CGPoint(x: x, y: y)
                }
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    pts.dropFirst().forEach { p.addLine(to: $0) }
                }
                .stroke(Theme.coral, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                ForEach(pts.indices, id: \.self) { i in
                    Circle().fill(i == pts.count - 1 ? Theme.coral : Color.white)
                        .overlay(Circle().stroke(Theme.coral, lineWidth: 2))
                        .frame(width: 7, height: 7)
                        .position(pts[i])
                }
            }
            .frame(height: 44)
        }
        .padding(10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loc("autoRep.weekA11y", listText(week.map(eurH))))
    }

    @ViewBuilder
    private func left(_ auto: Autopilot) -> some View {
        if let s = auto.left {
            let a = s.avg
            let lines: [(String, Int)] = [
                (loc("ledger.tickets"), a.tickets), (loc("ledger.tips"), a.tips), (loc("autoRep.contract"), a.contract),
                (loc("autoRep.hotels"), a.hotels), (loc("ledger.fuel"), -a.fuel), (loc("ledger.park"), -a.park),
                (loc("ledger.wages"), -a.wages), (loc("ledger.upkeep"), -a.upkeep), (loc("ledger.insurance"), -a.insurance),
                (loc("ledger.loans"), -a.loans), (loc("ledger.transfer"), -a.transfer), (loc("autoRep.other"), a.other)
            ].filter { $0.1 != 0 }
            VStack(alignment: .leading, spacing: 5) {
                sectionTitle(loc("autoRep.left", num(s.days)))
                if s.days > 0 {
                    ForEach(lines.indices, id: \.self) { i in
                        row(lines[i].0, signed(lines[i].1), color: lines[i].1 > 0 ? Theme.green : Theme.red)
                    }
                    total(loc("report.net"), signed(a.net), color: a.net >= 0 ? Theme.green : Theme.red)
                }
                VStack(alignment: .leading, spacing: 3) {
                    if let occ = s.occupancy {
                        fact(loc("autoRep.occupancy", percent(occ), num(a.pax), num(a.seats)))
                    } else {
                        fact(loc("autoRep.noFlights"))
                    }
                    fact(loc("autoRep.fleet", num(s.balloons), num(s.seats), num(s.pilots)))
                    if let lo = s.rivalMin, let avg = s.rivalAvg {
                        fact(loc("autoRep.price", money(s.price, in: region), money(lo, in: region), money(avg, in: region)))
                    } else {
                        fact(loc("autoRep.priceAlone", money(s.price, in: region)))
                    }
                }
                .padding(.top, 4)
            }
        } else {
            ProtoCallout(tone: .yellow, title: loc("autoRep.old"))
        }
    }

    // MARK: Helpers

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(Theme.font(17, .heavy, condensed: true))
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 2)
    }

    private func row(_ label: String, _ value: String, color: Color = Theme.ink) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label).font(Theme.font(14)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(value).font(Theme.font(15, .bold, condensed: true)).foregroundStyle(color).monospacedDigit()
        }
    }

    private func total(_ label: String, _ value: String, color: Color = Theme.ink) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label).font(Theme.font(14.5, .bold)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(value).font(Theme.font(18, .bold, condensed: true)).foregroundStyle(color).monospacedDigit()
        }
        .padding(.top, 6)
        .overlay(alignment: .top) { Rectangle().fill(Theme.ink).frame(height: 1.5) }
        .padding(.top, 2)
    }

    private func fact(_ t: String) -> some View {
        Text(t).font(Theme.font(13.5)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
    }

    private func signed(_ n: Int) -> String {
        n > 0 ? "+" + money(n, in: region) : n < 0 ? "−" + money(-n, in: region) : money(0, in: region)
    }

    /// A multiplier as a change: ×1.2 → "+20%", ×0.5 → "−50%".
    static func change(_ m: Double) -> String {
        let d = m - 1
        return (d >= 0 ? "+" : "−") + percent(abs(d))
    }
}
