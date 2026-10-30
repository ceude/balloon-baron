import SwiftUI
import BalloonBaronCore

/// `showReport()`: the end-of-day flight log as a ticket. Dark stub, perforation, ledger,
/// callouts, the day's events and the button to the next morning.
struct ReportView: View {
    @Environment(GameStore.self) private var store
    let report: DayReport
    /// "Only company in the sky" shows once per company and region.
    @State private var monopoly = false

    var body: some View {
        ZStack {
            Theme.sky.ignoresSafeArea()
            Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.55).ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                ticket
                ScrollView { ticket }
            }
        }
        .onAppear {
            SoundEngine.shared.play(report.net >= 0 ? .coin : .low)
            checkMonopoly()
        }
    }

    private var ticket: some View {
        VStack(spacing: 0) {
            stub
            Perforation()
            ticketBody
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .compositingGroup()
        .shadow(color: .black.opacity(0.35), radius: 20, y: 20)
        .frame(maxWidth: 420)
        .padding(16)
        .frame(maxWidth: .infinity)
    }

    // MARK: Stub

    private var stub: some View {
        let sub = report.skipped
            ? loc("report.stubSkipped", report.flag.title)
            : loc("report.stubFlew", report.flag.title, num(report.passengers), num(report.capacity))
        return HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc("hud.day", num(report.day))).font(Theme.font(34, .heavy, condensed: true))
                Text(sub).font(Theme.font(13)).opacity(0.75).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(loc("report.title")).font(Theme.font(13)).opacity(0.75)
                Text(store.state?.company ?? "")
                    .font(Theme.font(24, .heavy, condensed: true))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(Theme.ink)
    }

    // MARK: Body

    private var ticketBody: some View {
        let lg = report.ledger
        let s = store.state
        return VStack(alignment: .leading, spacing: 14) {
            ledger(lg, cash: s?.cash ?? 0)
            if lg.holdingNet != 0, let s {
                let names = s.parked.keys.sorted { $0.rawValue < $1.rawValue }.map(\.title).joined(separator: ", ")
                ProtoCallout(tone: .green, title: loc("report.holdTitle", eurH(lg.holdingNet)),
                             text: loc("report.holdBody", names, percent(s.holding.expenseRate), eurH(s.holding.cash)))
            }
            // v124.6: the stars, yesterday → today, with the biggest reasons
            if let r0 = report.repFrom, let r1 = report.repTo, starsText(r0) != starsText(r1) {
                let why = report.repReasons.map { loc("repWhy.\($0.0.rawValue)") + " " + ($0.1 > 0 ? "+" : "−") + Self.starDelta(abs($0.1) * 4) }
                ProtoCallout(tone: r1 > r0 ? .green : .red, title: loc("report.repTitle", starsText(r0), starsText(r1)),
                             text: why.joined(separator: " · "))
            }
            if Self.shows(lg.designRep * 4) {
                ProtoCallout(tone: .green, title: loc("report.designTitle"), text: loc("report.designBody", Self.starDelta(lg.designRep * 4)))
            }
            if Self.shows(lg.adRepLoss * 4) {
                ProtoCallout(tone: .yellow, title: loc("report.adTitle"), text: loc("report.adBody", Self.starDelta(lg.adRepLoss * 4)))
            }
            if !report.events.isEmpty || !report.rivalEvents.isEmpty {
                events
            }
            footer(s)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    @ViewBuilder
    private func footer(_ s: GameState?) -> some View {
        if s?.over ?? false {
            ProtoCallout(tone: .red, title: loc("report.overTitle"), text: loc("report.overBody", s?.company ?? ""))
            Button(loc("report.newCompany")) {
                SoundEngine.shared.play(.click)
                store.startOver()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        } else {
            if monopoly {
                ProtoCallout(tone: .green, title: loc("report.monoTitle", (s?.region ?? .cap).title), text: loc("report.monoBody"))
            }
            if let w = s?.weather {
                CardText.hint(loc("report.tomorrow", w.flag.title, num(w.surfaceWind)))
            }
            Button(loc("report.nextDay", num(s?.day ?? report.day + 1))) {
                SoundEngine.shared.play(.click)
                store.closeReport()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }

    // MARK: Ledger

    /// Prototype order; zero lines are left out. Costs are negative.
    private func lines(_ lg: Ledger) -> [(String, Int)] {
        let mission = lg.missionDone.map { loc("ledger.mission", $0.title) } ?? loc("ledger.missionReward")
        let all: [(String, Int)] = [
            (loc("ledger.tickets"), lg.tickets), (loc("ledger.evening"), lg.evening ?? 0), (loc("ledger.founderBonus"), lg.founderBonus), (mission, lg.mission),
            (loc("ledger.ads"), lg.ads), (loc("ledger.tips"), lg.tips), (loc("ledger.fuel"), -lg.fuel),
            (loc("ledger.wages"), -lg.wages), (loc("ledger.upkeep"), -lg.upkeep), (loc("ledger.insurance"), -lg.insurance),
            (loc("ledger.loans"), -lg.loans), (loc("ledger.repairs"), -lg.repairs), (loc("ledger.compensation"), -lg.compensation),
            (loc("ledger.insurancePaid"), lg.insurancePaid), (loc("ledger.hotelIncome"), lg.hotelIncome),
            (loc("ledger.hotelFees"), -lg.hotelFees), (loc("ledger.antitrust"), -lg.antitrust),
            (loc("ledger.cancellations"), -lg.cancellations), (loc("ledger.fines"), -lg.fines),
            (loc("ledger.seizure"), lg.seizure), (loc("ledger.chapterReward"), lg.chapterReward)
        ]
        return all.filter { $0.1 != 0 }
    }

    private func ledger(_ lg: Ledger, cash: Int) -> some View {
        let rows = lines(lg)
        return VStack(alignment: .leading, spacing: 5) {
            ForEach(rows.indices, id: \.self) { i in
                ledgerRow(rows[i].0, value: Self.signed(rows[i].1), color: rows[i].1 > 0 ? Theme.green : Theme.red, size: 17)
            }
            ledgerRow(loc("report.net"), value: Self.signed(report.net), color: report.net >= 0 ? Theme.green : Theme.red,
                      size: 22, bold: true)
                .padding(.top, 8)
                .overlay(alignment: .top) { Rectangle().fill(Theme.ink).frame(height: 2) }
                .padding(.top, 4)
            ledgerRow(loc("report.cash"), value: eur(cash), color: Theme.ink, size: 17)
        }
    }

    private func ledgerRow(_ label: String, value: String, color: Color, size: CGFloat, bold: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(Theme.font(14.5, bold ? .bold : .regular))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(value)
                .font(Theme.font(size, .bold, condensed: true))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }

    // MARK: Events

    /// `ul.ev`: own events with a coral dot, rival news greyed.
    private var events: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(report.events.indices, id: \.self) { i in
                eventRow(report.events[i].text, rival: false)
            }
            ForEach(report.rivalEvents.indices, id: \.self) { i in
                eventRow(report.rivalEvents[i].text, rival: true)
            }
        }
    }

    private func eventRow(_ text: String, rival: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(rival ? Color(hex: "#c3bbd6") : Theme.coral)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(Theme.font(14))
                .foregroundStyle(rival ? Theme.ink2 : Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Helpers

    private func checkMonopoly() {
        guard let s = store.state, !s.over, !s.rivals.isEmpty, s.rivals.allSatisfy({ !$0.alive }) else { return }
        let key = "monopolyShown.\(s.company).\(s.region.rawValue)"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            monopoly = true
        }
    }

    /// "+€120" / "−€40".
    static func signed(_ n: Int) -> String {
        n > 0 ? "+" + eur(n) : n < 0 ? "−" + eur(-n) : eur(0)
    }

    /// Star change with up to two decimals, e.g. "0.12★".
    /// A popularity note only appears when its change shows as at least 0.01★ (never "+0★").
    static func shows(_ x: Double) -> Bool { (x * 100).rounded() >= 1 }

    static func starDelta(_ x: Double) -> String {
        x.formatted(.number.precision(.fractionLength(0...2))) + "★"
    }
}

/// The prototype's `.perf`: a strip with round notches on both sides and a dashed tear line.
private struct Perforation: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.white)
            HStack(spacing: 0) {
                Circle().frame(width: 18, height: 18).offset(x: -9)
                Spacer(minLength: 0)
                Circle().frame(width: 18, height: 18).offset(x: 9)
            }
            .blendMode(.destinationOut)
            Line()
                .stroke(Theme.line, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .frame(height: 2)
                .padding(.horizontal, 16)
        }
        .compositingGroup()
        .frame(height: 18)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}

/// The prototype's `.callout` with a bold lead-in: red, yellow or green.
struct ProtoCallout: View {
    enum Tone { case red, yellow, green }
    let tone: Tone
    let title: String
    var text: String = ""

    var body: some View {
        (Text(title).font(Theme.font(14, .bold)) + Text(text.isEmpty ? "" : " " + text).font(Theme.font(14)))
            .foregroundStyle(fg)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(bg, in: RoundedRectangle(cornerRadius: 14))
    }

    private var bg: Color {
        switch tone {
        case .red: Color(hex: "#fde6e2")
        case .yellow: Color(hex: "#fff3cf")
        case .green: Color(hex: "#dcf3e5")
        }
    }

    private var fg: Color {
        switch tone {
        case .red: Color(hex: "#8c2414")
        case .yellow: Color(hex: "#6b4c00")
        case .green: Color(hex: "#145c34")
        }
    }
}
