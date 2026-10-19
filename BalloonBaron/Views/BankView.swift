import SwiftUI
import BalloonBaronCore

/// Bank page (prototype `tabBank`): active loans with early payoff, and loan offers.
struct BankView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let s: GameState? = store.state
        return FleetUI.PageFrame(title: loc("bank.title"), cash: s?.cash ?? 0, close: { store.closePage() }) {
            if let s {
                if s.region != .cap || !s.parked.isEmpty {
                    regionCallout(s.region)
                }
                loansCard(s)
                offersCard(s)
            }
        }
    }

    private func regionCallout(_ r: RegionID) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.green)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 4) {
                FleetUI.Title(loc("bank.regional.title", r.title))
                FleetUI.Detail(loc("bank.regional.body"))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16))
    }

    private func loansCard(_ s: GameState) -> some View {
        let loans: [Loan] = s.loans
        return FleetUI.Card(loc("bank.yourLoans")) {
            if loans.isEmpty {
                FleetUI.Hint(loc("bank.noDebt"))
            }
            ForEach(Array(loans.enumerated()), id: \.offset) { i, l in
                loanRow(i, l, cash: s.cash)
            }
        }
    }

    private func loanRow(_ i: Int, _ l: Loan, cash: Int) -> some View {
        FleetUI.Item {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    FleetUI.Title(loc("bank.loan", eur(l.amount)))
                    FleetUI.Detail(loc("bank.loanDetail", eur(l.installment), num(l.daysLeft)))
                }
                Spacer(minLength: 0)
                FleetUI.SmallButton(title: loc("bank.payoff", eur(l.payoff)), ghost: true, disabled: cash < l.payoff) {
                    SoundEngine.shared.play(.click)
                    store.act { _ = $0.repayLoan(i) }
                }
                .frame(width: 130)
            }
        }
    }

    private func offersCard(_ s: GameState) -> some View {
        FleetUI.Card(loc("bank.offers")) {
            ForEach(Array(Rules.loans.enumerated()), id: \.offset) { i, o in
                offerRow(i, o)
            }
            FleetUI.Hint(loc("bank.hint", eur(Rules.seizeBelow)))
        }
    }

    private func offerRow(_ i: Int, _ o: LoanOffer) -> some View {
        let canTake: Bool = store.game?.canTakeLoan(o) ?? false
        return FleetUI.Item {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    FleetUI.Title(loc("bank.offer", eur(o.amount), num(o.days)))
                    FleetUI.Tag(text: loc("bank.interest", percent(o.interest)),
                                color: o.interest > 0.22 ? Theme.red : Theme.yellow)
                    FleetUI.Detail(offerDetail(o))
                }
                Spacer(minLength: 0)
                FleetUI.SmallButton(title: loc("bank.take"), disabled: !canTake) {
                    SoundEngine.shared.play(.coin)
                    store.act { _ = $0.takeLoan(i) }
                }
                .frame(width: 110)
            }
        }
    }

    private func offerDetail(_ o: LoanOffer) -> String {
        let base = loc("bank.offerDetail", eur(o.installment), eur(o.total))
        return o.balloonsNeeded > 0 ? base + " " + loc("bank.need", num(o.balloonsNeeded)) : base
    }
}
