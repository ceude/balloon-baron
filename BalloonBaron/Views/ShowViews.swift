import SwiftUI
import BalloonBaronCore

/// v111: the Balloon Show's card (`showCard`): what it costs (every balloon that can fly), what it brings, and the
/// wait until the next one. Booked, it plays over the town that night.
struct ShowCardView: View {
    @Environment(GameStore.self) private var store
    /// Booked in this card: it now says when the show starts.
    @State private var booked = false

    var body: some View {
        ModalCard {
            if let g = store.game {
                if booked || g.showState == .booked { done(g) } else { offer(g) }
            }
        }
    }

    @ViewBuilder
    private func offer(_ g: Game) -> some View {
        let st = g.showState, n = g.showFleet.count
        CardText.title(loc("show.openTitle"))
        CardText.lead(loc("show.intro"))
        VStack(alignment: .leading, spacing: 4) {
            Text(loc("show.gainsTitle")).font(Theme.font(14, .bold)).foregroundStyle(Theme.ink)
            ForEach([loc("show.gainRep"), loc("show.gainPax", num(Int(Rules.showPax)), num(Int(Rules.showPax) * n)),
                     loc("show.gainCap"), loc("show.gainPaper")], id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•").foregroundStyle(Theme.coral)
                    Text(line).fixedSize(horizontal: false, vertical: true)
                }
                .font(Theme.font(13.5)).foregroundStyle(Theme.ink)
            }
            Text(loc("show.gainNote", num(Rules.showCooldown))).font(Theme.font(12)).foregroundStyle(Theme.ink2).padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "#f4f0fb"), in: RoundedRectangle(cornerRadius: 14))
        figurePicker(g.state)
        if st == .ok {
            Grid(alignment: .leading, verticalSpacing: 4) {
                GridRow { Text(loc("show.calcBalloons")); Text(num(n)).bold().gridColumnAlignment(.trailing) }
                GridRow { Text(loc("show.calcEach")); Text(eur(Rules.showPerBalloon)).bold() }
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    Text(loc("show.calcTotal", num(n), eur(Rules.showPerBalloon))).bold()
                    Text(eur(g.showCost)).font(Theme.font(15, .heavy))
                }
            }
            .font(Theme.font(14)).foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.sun.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
            Button(loc("show.confirm", eur(g.showCost))) {
                SoundEngine.shared.play(.coin)
                store.act { _ = $0.bookShow() }
                withAnimation(.easeOut(duration: 0.2)) { booked = true }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
            Button {
                SoundEngine.shared.play(.click)
                store.closeShowCard()
            } label: { Text(loc("show.cancelBtn")).frame(maxWidth: .infinity) }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost, wide: true))
        } else {
            Text(ShowCardView.why(st, g))
                .font(Theme.font(14, .bold)).foregroundStyle(Theme.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            Button(loc("home.close")) {
                SoundEngine.shared.play(.click)
                store.closeShowCard()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
        }
    }

    @ViewBuilder
    private func done(_ g: Game) -> some View {
        CardText.title(loc("show.doneTitle"))
        CardText.lead(loc("show.doneBody", num(g.state.local.showIDs?.count ?? 0)))
        Text(loc("show.doneNote", num(Rules.showMinBalloons)))
            .font(Theme.font(12.5)).foregroundStyle(Theme.ink2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        figurePicker(g.state)
        Button(loc("show.ok")) {
            SoundEngine.shared.play(.click)
            store.closeShowCard()
        }
        .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
    }

    /// v113: the finale's figure. The free one follows the fleet (a V, a ring, a heart); bought figures are yours to pick,
    /// a locked one opens its purchase card.
    private func figurePicker(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc("show.figure")).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    figureChip(nil, s)
                    ForEach(StoreItem.allCases.filter { $0.kind == .figure }, id: \.self) { k in figureChip(k, s) }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func figureChip(_ k: StoreItem?, _ s: GameState) -> some View {
        let lock = k.map { !s.owned($0) } ?? false, on = s.showFigure == k
        return Button {
            SoundEngine.shared.play(.click)
            if let k, lock { store.storeItem = .figurePack } else { store.act { $0.state.showFig = k } }
        } label: {
            VStack(spacing: 2) {
                Group {
                    if let k {
                        FigureThumb(item: k, colors: s.colors, company: s.company)
                    } else {
                        // v122.2: drawn, not text: the ♥ turned into an emoji on the phone
                        AutoFigureGlyph().background(Color(hex: "#141838"))
                    }
                }
                .frame(width: 48, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
                Text(k.map { $0 == .figInitial ? "\($0.title): \(ShowCardView.initial(s.company))" : $0.title } ?? loc("show.figAuto"))
                    .font(Theme.font(12, .bold)).foregroundStyle(Theme.ink).lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
                if let k, lock {
                    HStack(spacing: 3) {
                        LockGlyph(size: 10)
                        Text(loc("show.inPack")).font(Theme.font(11, .heavy))
                    }
                    .foregroundStyle(Theme.coral)
                }
            }
            .frame(width: 78, height: 96, alignment: .top) // v122.2: every chip the same size
            .padding(.vertical, 6).padding(.horizontal, 4)
            .background(on ? Color.white : Color(hex: "#fff8ea"), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Theme.coral : Color(hex: "#e6cfa6"), lineWidth: on ? 2.5 : 1.5))
        }
        .buttonStyle(.plain)
    }

    static func initial(_ company: String) -> String {
        String(company.trimmingCharacters(in: .whitespaces).first ?? "B").uppercased(with: Locale(identifier: "tr"))
    }

    /// Why the show can't be booked now; also the short status on the entry rows.
    static func why(_ st: ShowState, _ g: Game) -> String {
        switch st {
        case .locked: loc("show.locked")
        case .booked: loc("show.booked")
        case .wait(let d): loc("show.wait", num(d))
        case .few: loc("show.few", num(Rules.showMinBalloons), num(g.showFleet.count))
        case .cash: loc("show.cash", eur(g.showCost))
        case .ok: loc("show.ready", num(g.showFleet.count), eur(g.showCost))
        }
    }

    /// Whether the show is worth a row on the pages: the market is open and the fleet is big enough.
    static func offered(_ g: Game) -> Bool { g.state.unlocked.contains(.market) && g.state.balloons.count >= Rules.showMinBalloons }
}

/// v122.2: the free finale figure's thumbnail, the three shapes it can draw: a V, a ring and a heart.
struct AutoFigureGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width / 48, size.height / 54), ox = (size.width - 48 * k) / 2, oy = (size.height - 54 * k) / 2
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * k, y: oy + y * k) }
            let gold = Color(hex: "#ffd27a")
            var v = Path()
            v.move(to: p(6, 22)); v.addLine(to: p(11, 32)); v.addLine(to: p(16, 22))
            ctx.stroke(v, with: .color(gold), style: StrokeStyle(lineWidth: 1.8 * k, lineCap: .round, lineJoin: .round))
            ctx.stroke(Path(ellipseIn: CGRect(origin: p(19, 22), size: CGSize(width: 10 * k, height: 10 * k))), with: .color(gold), lineWidth: 1.8 * k)
            var h = Path()
            h.move(to: p(38, 32))
            h.addCurve(to: p(34.6, 23.4), control1: p(33, 28.5), control2: p(32, 25))
            h.addCurve(to: p(38, 24.6), control1: p(36.4, 22.4), control2: p(37.7, 23.6))
            h.addCurve(to: p(41.4, 23.4), control1: p(38.3, 23.6), control2: p(39.6, 22.4))
            h.addCurve(to: p(38, 32), control1: p(44, 25), control2: p(43, 28.5))
            h.closeSubpath()
            ctx.fill(h, with: .color(gold))
        }
    }
}
