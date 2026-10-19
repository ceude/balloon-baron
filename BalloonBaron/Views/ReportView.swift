import SwiftUI
import BalloonBaronCore

/// End-of-day flight log: money in and out, what happened, and rival news.
struct ReportView: View {
    @Environment(GameStore.self) private var store
    let report: DayReport

    var body: some View {
        let lg = report.ledger
        let income: [(String, Int)] = [
            (loc("ledger.tickets"), lg.tickets), (loc("ledger.founderBonus"), lg.founderBonus), (loc("ledger.hotelIncome"), lg.hotelIncome),
            (loc("ledger.mission", lg.missionDone?.title ?? ""), lg.mission), (loc("ledger.ads"), lg.ads),
            (loc("ledger.tips"), lg.tips), (loc("ledger.insurancePaid"), lg.insurancePaid), (loc("ledger.seizure"), lg.seizure)
        ].filter { $0.1 != 0 }
        let costs: [(String, Int)] = [
            (loc("ledger.fuel"), lg.fuel), (loc("ledger.wages"), lg.wages), (loc("ledger.upkeep"), lg.upkeep),
            (loc("ledger.insurance"), lg.insurance), (loc("ledger.loans"), lg.loans), (loc("ledger.repairs"), lg.repairs),
            (loc("ledger.compensation"), lg.compensation), (loc("ledger.fines"), lg.fines),
            (loc("ledger.cancellations"), lg.cancellations), (loc("ledger.hotelFees"), lg.hotelFees), (loc("ledger.antitrust"), lg.antitrust)
        ].filter { $0.1 != 0 }

        ZStack {
            Theme.sky.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(loc("report.title")).font(Theme.font(30, .heavy, condensed: true))
                        Spacer()
                        Text(loc("hud.day", num(report.day))).font(Theme.font(18, .bold, condensed: true))
                    }
                    .foregroundStyle(Theme.ink)
                    HStack(spacing: 8) {
                        Circle().fill(Theme.flagColor(report.flag)).frame(width: 12, height: 12)
                        Text(report.flag.title).font(Theme.font(15, .semibold))
                        Spacer()
                        Text(report.skipped ? loc("report.skipped")
                             : "\(loc("report.passengers")): \(num(report.passengers)) / \(loc("report.seats")): \(num(report.capacity))")
                            .font(Theme.font(15, .semibold))
                    }
                    .foregroundStyle(Theme.ink2)

                    section(loc("report.income"), rows: income, sign: 1)
                    section(loc("report.costs"), rows: costs, sign: -1)
                    HStack {
                        Text(loc("report.net")).font(Theme.font(22, .heavy, condensed: true))
                        Spacer()
                        Text(eur(report.net))
                            .font(Theme.font(26, .heavy, condensed: true))
                            .foregroundStyle(report.net >= 0 ? Theme.green : Theme.red)
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.vertical, 6)

                    events(loc("report.events"), report.events)
                    events(loc("report.rivals"), report.rivalEvents)

                    BigButton(title: loc("report.next")) { store.closeReport() }
                        .padding(.top, 6)
                }
                .padding(20)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 26))
                .padding(16)
            }
        }
    }

    private func section(_ title: String, rows: [(String, Int)], sign: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.font(14, .bold)).foregroundStyle(Theme.ink2).textCase(.uppercase)
            ForEach(rows.indices, id: \.self) { i in
                HStack {
                    Text(rows[i].0)
                    Spacer()
                    Text((sign < 0 ? "−" : "+") + eur(rows[i].1)).monospacedDigit()
                }
                .font(Theme.font(16, .medium))
                .foregroundStyle(Theme.ink)
            }
            Divider()
        }
    }

    @ViewBuilder
    private func events(_ title: String, _ list: [DayEvent]) -> some View {
        if !list.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(Theme.font(14, .bold)).foregroundStyle(Theme.ink2).textCase(.uppercase)
                ForEach(list.indices, id: \.self) { i in
                    Text(list[i].text).font(Theme.font(15)).foregroundStyle(Theme.ink)
                }
            }
        }
    }
}
