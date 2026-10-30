import SwiftUI
import BalloonBaronCore

/// v125–v125.5: "Bring your fleet" on entering a new region (`showXfer`), in three steps: the balloons (seats picked of
/// 16), the pilots (of 2), and what it all costs; a step with nothing to pick is left out. The lists sit in a framed
/// box that scrolls by itself, so the card fits on the screen. "Skip: start from scratch" on every step.
@MainActor
struct TransferView: View {
    @Environment(GameStore.self) private var store
    @State private var picked: Set<Int>?
    @State private var step = 0
    /// v125.6: the height the card has (the window, not the screen: iPad Split View), for the lists.
    @State private var room: CGFloat = 700

    private enum Step { case balloons, pilots, sum }

    var body: some View {
        if let g = store.game {
            let B = g.transferBalloons, P = g.transferPilots
            let steps: [Step] = (B.isEmpty ? [] : [.balloons]) + (P.isEmpty ? [] : [.pilots]) + [.sum]
            let sel = picked ?? Set(g.transferDefaults.balloons + g.transferDefaults.pilots)
            let k = steps[min(step, steps.count - 1)]
            let bs = B.filter { sel.contains($0.balloon.id) }, ps = P.filter { sel.contains($0.pilot.id) }
            let seats = bs.reduce(0) { $0 + $1.balloon.size.capacity }
            ModalCard {
                HStack(spacing: 6) {
                    ForEach(steps.indices, id: \.self) { i in
                        Capsule().fill(Color(hex: i == step ? "#14a39a" : i < step ? "#8fd4cc" : "#e2dcef")).frame(width: 22, height: 5)
                    }
                    Text(loc("xfer.step", num(step + 1), num(steps.count)))
                        .font(Theme.font(13, .heavy, condensed: true)).tracking(0.6).textCase(.uppercase).foregroundStyle(Theme.ink2)
                        .padding(.leading, 6)
                }
                CardText.title(loc(k == .balloons ? "xfer.whichBalloons" : k == .pilots ? "xfer.whichPilots" : "xfer.title"))
                switch k {
                case .balloons:
                    CardText.hint(loc("xfer.bNote", guideName(g.state.region), num(Transfer.seats), num(Transfer.shipDays)))
                    header(loc("xfer.seatsPicked"), "\(num(seats))/\(num(Transfer.seats))")
                    // v125.6: when nothing more fits, say why the other rows are grey
                    if B.contains(where: { !sel.contains($0.balloon.id) && (bs.count >= Transfer.maxBalloons || seats + $0.balloon.size.capacity > Transfer.seats) }) {
                        fullNote(loc("xfer.cargoFull"))
                    }
                    list {
                        ForEach(B, id: \.balloon.id) { x in
                            let on = sel.contains(x.balloon.id)
                            let full = bs.count >= Transfer.maxBalloons || seats + x.balloon.size.capacity > Transfer.seats
                            row(on: on, disabled: !on && full, title: x.balloon.title,
                                sub: [x.balloon.size.title, loc("xfer.seats", num(x.balloon.size.capacity)), x.region.title,
                                      x.balloon.design != nil ? loc("xfer.designed") : nil].compactMap { $0 }.joined(separator: " · ")) {
                                toggle(x.balloon.id, sel)
                            }
                        }
                    }
                case .pilots:
                    CardText.hint(loc("xfer.pNote", Locale.current.localizedString(forCurrencyCode: g.state.region.currency) ?? g.state.region.currency))
                    header(loc("xfer.pilotsPicked"), "\(num(ps.count))/\(num(Transfer.maxPilots))")
                    if ps.count >= Transfer.maxPilots && P.count > ps.count { fullNote(loc("xfer.pilotsFull")) }
                    list {
                        ForEach(P, id: \.pilot.id) { x in
                            let on = sel.contains(x.pilot.id)
                            row(on: on, disabled: !on && ps.count >= Transfer.maxPilots, title: x.pilot.name,
                                sub: [x.pilot.level.title, x.pilot.trait?.title, x.region.title].compactMap { $0 }.joined(separator: " · ")) {
                                toggle(x.pilot.id, sel)
                            }
                        }
                    }
                case .sum:
                    VStack(spacing: 8) {
                        sumRow(loc("xfer.sumBalloons", num(Transfer.shipDays)), bs.isEmpty ? loc("xfer.nothing") : bs.map(\.balloon.title).joined(separator: ", "))
                        sumRow(loc("xfer.sumPilots"), ps.isEmpty ? loc("xfer.nothing") : ps.map(\.pilot.name).joined(separator: ", "))
                    }
                    .padding(10)
                    .background(Color(hex: "#f6f3fb"), in: RoundedRectangle(cornerRadius: 12))
                    cost(g, bs.map(\.balloon.id), ps.map(\.pilot.id), bs, ps)
                    CardText.hint(loc("xfer.notCounted"))
                }
                HStack(spacing: 8) {
                    if step > 0 {
                        Button(loc("common.back")) { SoundEngine.shared.play(.click); step -= 1 }
                            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
                    }
                    if k != .sum {
                        Button(loc("common.next")) { SoundEngine.shared.play(.click); step += 1 }
                            .buttonStyle(ChunkyButtonStyle(kind: .big))
                    } else {
                        Button(bs.count + ps.count > 0 ? loc("xfer.go", num(bs.count), num(ps.count)) : loc("xfer.none")) {
                            SoundEngine.shared.play(bs.count + ps.count > 0 ? .coin : .click)
                            store.closeTransfer(balloons: bs.map(\.balloon.id), pilots: ps.map(\.pilot.id))
                        }
                        .buttonStyle(ChunkyButtonStyle(kind: .big))
                    }
                }
                Button(loc("xfer.skip")) {
                    SoundEngine.shared.play(.click)
                    store.closeTransfer(balloons: nil, pilots: [])
                }
                .buttonStyle(ChunkyButtonStyle(kind: .ghost, wide: true))
            }
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { room = geo.size.height }
                    .onChange(of: geo.size.height) { _, h in room = h }
            })
        }
    }

    private func fullNote(_ t: String) -> some View {
        Text(t).font(Theme.font(12.5, .semibold)).foregroundStyle(Color(hex: "#8c5a00"))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 2).padding(.top, -6)
    }

    private func toggle(_ id: Int, _ sel: Set<Int>) {
        SoundEngine.shared.play(.click)
        var s = sel
        if s.contains(id) { s.remove(id) } else { s.insert(id) }
        picked = s
    }

    private func header(_ a: String, _ b: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(a).font(Theme.font(13)).foregroundStyle(Theme.ink2)
            Spacer()
            Text(b).font(Theme.font(18, .heavy, condensed: true)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 2)
    }

    /// `.xlist`: a framed box (1.5 pt line, 14 pt corners, light ground); only its inside scrolls.
    private func list<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        let h = min(300, room * 0.36)
        return ScrollView {
            VStack(spacing: 6, content: c).padding(6)
        }
        .frame(minHeight: 96, maxHeight: h)
        .fixedSize(horizontal: false, vertical: false)
        .background(Color(hex: "#faf8fd"), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#cfc8de"), lineWidth: 1.5))
    }

    private func row(on: Bool, disabled: Bool, title: String, sub: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(on ? Color(hex: "#14a39a") : .white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(on ? Color(hex: "#14a39a") : Theme.line, lineWidth: 2))
                    .overlay(Text(on ? "✓" : "").font(.system(size: 14, weight: .heavy)).foregroundStyle(.white))
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(Theme.font(15, .bold)).foregroundStyle(Theme.ink)
                    Text(sub).font(Theme.font(12.5)).foregroundStyle(Theme.ink2)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11).padding(.vertical, 8)
            .background(on ? Color(hex: "#effaf8") : .white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(on ? Color(hex: "#14a39a") : Theme.line, lineWidth: on ? 2 : 1.5))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }

    private func sumRow(_ a: String, _ b: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(a).font(Theme.font(13.5)).foregroundStyle(Theme.ink2)
            Spacer(minLength: 8)
            Text(b).font(Theme.font(16, .heavy, condensed: true)).foregroundStyle(Theme.ink).multilineTextAlignment(.trailing)
        }
    }

    /// "It has a cost": each home region's daily earnings before → after, and the balloons' price and installment.
    @ViewBuilder
    private func cost(_ g: Game, _ bIDs: [Int], _ pIDs: [Int], _ bs: [TransferBalloon], _ ps: [TransferPilot]) -> some View {
        let regions = RegionID.allCases.filter { r in bs.contains { $0.region == r } || ps.contains { $0.region == r } }
        let debt = g.transferCost(balloons: bIDs)
        let lines = regions.map { r -> String in
            let inc = g.transferIncome(r, balloons: bIDs, pilots: pIDs)
            return loc("xfer.income", r.title, eurH(inc.now), eurH(inc.after))
        } + (debt > 0 ? [loc("xfer.debt", eur(debt), num(Transfer.debtDays), eur(jsRoundUI(Double(debt) / Double(Transfer.debtDays))))] : [])
        if !lines.isEmpty {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3).fill(Theme.yellow).frame(width: 5)
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc("xfer.cost")).font(Theme.font(14, .bold))
                    ForEach(lines, id: \.self) { Text($0).font(Theme.font(13.5)) }
                }
                .foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Theme.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
