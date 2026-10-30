import SwiftUI
import BalloonBaronCore

/// v125: the offer card, spoken by the company's owner (`ctrCard`): who, what they say (with an introduction the
/// first time), the four facts, Bristol's fog forecast, the rule, trust, and Accept / Negotiate / Decline. Then the
/// answer in the owner's words (`ctrResult`). The first one in a region comes after the scene at the off-map place.
@MainActor
struct ContractOfferView: View {
    @Environment(GameStore.self) private var store
    /// The answer, once given: the offer as it was, what was said, and the rival that took the group.
    @State private var result: (offer: ContractOffer, line: String, good: Bool, rival: String?)?
    /// v125.6: the owner's introduction, behind "More" the first time.
    @State private var intro = false
    /// v125.6: a short screen (iPhone SE): a little tighter so the card fits without scrolling.
    @State private var compact = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(store.contractScene != nil ? 0.08 : 0.3).ignoresSafeArea()
                .contentShape(Rectangle()).onTapGesture {}
                .background(GeometryReader { g in Color.clear.onAppear { compact = g.size.height < 720 } })
            ViewThatFits(in: .vertical) {
                content
                ScrollView { content }.defaultScrollAnchor(.top)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let s = store.state, let K = s.contractConfig {
            if let r = result { resultCard(s, K, r) } else if let o = s.local.contracts?.offer { offerCard(s, K, o) }
        }
    }

    private func cardFrame<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 9, content: c)
            .padding(.horizontal, compact ? 16 : 18)
            .padding(.vertical, compact ? 13 : 16)
            .frame(maxWidth: 440, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(alignment: .top) { UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24).fill(Color(hex: "#2ab0a8")).frame(height: 6) }
            .compositingGroup()
            .shadow(color: .black.opacity(0.35), radius: 25, y: 20)
            .padding(14)
            .frame(maxWidth: .infinity)
    }

    private func offerCard(_ s: GameState, _ K: ContractConfig, _ o: ContractOffer) -> some View {
        let c = s.local.contracts ?? ContractState(), w = o.owner, riv = s.contractRival?.name
        // v125.6: the offer itself; the first time, the owner's introduction waits behind "More"
        let say = ctrText(w, "offer", n: o.n, day: o.day, len: o.len, price: o.price)
        let neg = s.negotiatedPrice(o)
        return cardFrame {
            ContractHead(owner: w, tag: c.met ? loc("ctr.\(s.region.rawValue).tag") : loc("ctr.newContact"), avatar: compact ? 46 : 56)
            if c.met || intro {
                ContractSpeech(text: (c.met ? "" : ctrText(w, "intro") + " ") + say, size: compact ? 13.5 : 14.5)
            } else {
                ContractSpeech(text: say, size: compact ? 13.5 : 14.5, more: { withAnimation(.easeOut(duration: 0.2)) { intro = true } })
            }
            facts(s, K, o)
            if let fp = o.fogP { fogRow(o, fp) }
            penalty(K, o)
            Text(riv.map { loc("ctr.rule.rival", $0) } ?? loc("ctr.rule.rivalAny"))
                .font(Theme.font(12.5)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
            ContractTrust(owner: w, promise: !c.pref && c.okWho < K.prefNeed, size: compact ? 12 : 12.5)
            Button(loc("ctr.accept", eur(o.total))) {
                SoundEngine.shared.play(.coin)
                let o0 = o
                store.act { $0.acceptContract() }
                withAnimation { result = (o0, loc("ctr.\(s.region.rawValue).accepted"), true, nil) }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big, height: compact ? 48 : 54))
            HStack(alignment: .top, spacing: 8) {
                if !o.negotiated && neg > o.price {
                    option(loc("ctr.negotiate", eur(neg)), c.pref ? loc("ctr.negotiate.safe") : loc("ctr.negotiate.risk"), red: false) {
                        var ok: Bool?
                        store.act { ok = $0.negotiateContract() }
                        if ok == true {
                            SoundEngine.shared.play(.coin)
                            var o1 = o
                            o1.price = neg
                            store.act { $0.acceptContract() }
                            withAnimation { result = (o1, ctrText(w, "negOk", price: neg), true, nil) }
                        } else {
                            SoundEngine.shared.play(.low)
                            withAnimation { result = (o, ctrText(w, "negWalk", rival: riv ?? loc("ctr.rival")), false, riv) }
                        }
                    }
                }
                option(loc("ctr.decline"), loc("ctr.decline.sub"), red: true) {
                    SoundEngine.shared.play(.click)
                    store.act { $0.declineContract() }
                    withAnimation { result = (o, ctrText(w, "decline", rival: riv ?? loc("ctr.rival")), false, riv) }
                }
            }
        }
    }

    private func facts(_ s: GameState, _ K: ContractConfig, _ o: ContractOffer) -> some View {
        let seats = num(s.fleetSeats)
        let when = o.len > 1 ? loc("ctr.when.range", num(o.day), num(o.lastDay)) : loc("ctr.when.one", num(o.day))
        let whenSub = K.weekend ? "\(weekdayName(o.day))–\(weekdayName(o.day + 1))"
            : o.len > 1 ? loc("ctr.fact.inDaysFor", num(o.day - s.day), num(o.len)) : loc("ctr.fact.inDays", num(o.day - s.day))
        let cells: [(String, String)] = [
            (o.len > 1 ? "\(num(o.n)) × \(num(o.len))" : num(o.n), o.len > 1 ? loc("ctr.fact.peopleDaily", seats) : loc("ctr.fact.people", seats)),
            (when, whenSub), (eur(o.price), loc("ctr.fact.perHead")), (eur(o.total), loc("ctr.fact.total"))
        ]
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible())], spacing: 6) {
            ForEach(cells.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 1) {
                    Text(cells[i].0).font(Theme.font(compact ? 17 : 19, .heavy, condensed: true)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.7)
                    Text(cells[i].1).font(Theme.font(12)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 10).padding(.vertical, compact ? 5 : 7)
                .background(Color(red: 108 / 255, green: 100 / 255, blue: 136 / 255).opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    /// `.ctrfog`: each day's fog forecast.
    private func fogRow(_ o: ContractOffer, _ fp: [Double]) -> some View {
        HStack(spacing: 8) {
            Text(loc("ctr.fogForecast")).font(Theme.font(12.5)).foregroundStyle(Theme.ink2)
            ForEach(fp.indices, id: \.self) { i in
                let p = fp[i], hi = p >= 0.4, mid = p >= 0.25
                Text("\(weekdayShort(o.day + i)) \(percent(p))")
                    .font(Theme.font(15, .heavy, condensed: true))
                    .foregroundStyle(Color(hex: hi ? "#8c2414" : mid ? "#6b4c00" : "#3a5a7a"))
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color(hex: hi ? "#fde6e2" : mid ? "#fff3cf" : "#e6eef4"), in: Capsule())
            }
        }
    }

    /// v125.6: the penalty in its own callout, red bar on the left like the result card's, the rest of the rule under it.
    private func penalty(_ K: ContractConfig, _ o: ContractOffer) -> some View {
        let rule = K.fogGuarantee ? loc("ctr.rule2.fog", eur(jsRoundUI(Double(o.price) * K.voucher)))
            : o.len > 1 ? loc("ctr.rule2.block", num(o.len)) : loc("ctr.rule2.one", percent(K.redCut))
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3).fill(Theme.red).frame(width: 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(loc("ctr.penalty", eur(jsRoundUI(Double(o.price) * K.pen)))).font(Theme.font(14, .bold))
                Text(rule).font(Theme.font(compact ? 13 : 13.5))
            }
            .foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, compact ? 7 : 9).padding(.leading, 8).padding(.trailing, 10)
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
    }

    private func option(_ title: String, _ sub: String, red: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            // v125.6: both buttons the same text sizes; a long subtitle takes a second line instead of shrinking
            VStack(spacing: 1) {
                Text(title).font(Theme.font(14.5, .bold)).foregroundStyle(red ? Color(hex: "#a8302a") : Theme.ink).lineLimit(2)
                Text(sub).font(Theme.font(12)).foregroundStyle(Theme.ink2).lineLimit(2)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, compact ? 6 : 8)
            .frame(maxWidth: .infinity, minHeight: compact ? 46 : 50)
            .padding(.horizontal, 10)
            .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.line).offset(y: 3))
        }
        .buttonStyle(.plain)
    }

    private func resultCard(_ s: GameState, _ K: ContractConfig, _ r: (offer: ContractOffer, line: String, good: Bool, rival: String?)) -> some View {
        let o = r.offer
        let when = o.len > 1 ? loc("ctr.when.range", num(o.day), num(o.lastDay)) : loc("ctr.when.one", num(o.day))
        return cardFrame {
            ContractHead(owner: o.owner, tag: loc(r.good ? "ctr.deal" : "ctr.lost"))
            ContractSpeech(text: r.line)
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3).fill(r.good ? Theme.green : Theme.red).frame(width: 5)
                Group {
                    if r.good {
                        Text(loc(o.len > 1 ? "ctr.deal.daily" : "ctr.deal.one", when, num(o.n), eur(o.price))).bold()
                            + Text(" " + loc("ctr.\(s.region.rawValue).where"))
                    } else {
                        Text(loc(o.len > 1 ? "ctr.lost.daily" : "ctr.lost.one", r.rival ?? loc("ctr.rival"), num(o.n))).bold()
                            + Text(" " + loc("ctr.lost.why"))
                    }
                }
                .font(Theme.font(14)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(10)
            .fixedSize(horizontal: false, vertical: true)
            .background((r.good ? Theme.green : Theme.red).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            Button(loc("hez.ok")) {
                SoundEngine.shared.play(.click)
                store.closeContractCard()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }
}

/// `ctrStatusCard`: tapping the off-map place: what's booked.
@MainActor
struct ContractStatusView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        if let s = store.state, let K = s.contractConfig, let w = s.contractOwner {
            let c = s.local.contracts ?? ContractState()
            let mine = c.booked.filter(\.mine).sorted { $0.day < $1.day }
            ModalCard(onClose: { store.closeContractCard() }) {
                ContractHead(owner: w, tag: loc("ctr.\(s.region.rawValue).place"), closeSpace: true)
                if mine.isEmpty {
                    CardText.lead(loc(c.met || c.ok > 0 ? "ctr.\(s.region.rawValue).empty" : "ctr.\(s.region.rawValue).fresh"))
                } else {
                    ForEach(mine) { k in
                        VStack(spacing: 6) {
                            row(k.owner.company, k.len > 1 ? loc("ctr.when.range", num(k.day), num(k.lastDay)) : loc("ctr.when.one", num(k.day)))
                            row(loc("ctr.group"), k.len > 1 ? loc("ctr.group.sizeDaily", num(k.n), num(k.len), eur(k.price)) : loc("ctr.group.size", num(k.n), eur(k.price)))
                        }
                        .padding(10)
                        .background(Color(hex: "#f6f3fb"), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                ContractTrust(owner: w, promise: false, need: K.prefNeed)
                Button(loc("fleetPage.close")) { store.closeContractCard() }
                    .buttonStyle(ChunkyButtonStyle(kind: .big))
            }
        }
    }

    private func row(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(Theme.font(13.5)).foregroundStyle(Theme.ink2)
            Spacer(minLength: 8)
            Text(b).font(Theme.font(16, .heavy, condensed: true)).foregroundStyle(Theme.ink).multilineTextAlignment(.trailing)
        }
    }
}

/// The owner's portrait, a tag, the name and the title (`ctrHead`).
struct ContractHead: View {
    let owner: ContractOwner
    let tag: String
    var avatar: CGFloat = 56
    /// Room for a card's ✕ in the top right corner (only the status card has one).
    var closeSpace = false

    var body: some View {
        HStack(spacing: 12) {
            ContractAvatar(owner: owner, size: avatar)
            VStack(alignment: .leading, spacing: 1) {
                Text(tag).font(Theme.font(12.5, .heavy, condensed: true)).tracking(0.7).textCase(.uppercase).foregroundStyle(Color(hex: "#14a39a"))
                Text(owner.title).font(Theme.font(21, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                Text(owner.role).font(Theme.font(13)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.trailing, closeSpace ? 30 : 0)
    }
}

/// `.ctrsay`: what the owner says, in a speech bubble.
struct ContractSpeech: View {
    let text: String
    var size: CGFloat = 14.5
    /// v125.6: "More" after the text; tapping the bubble shows the rest.
    var more: (() -> Void)? = nil

    @ViewBuilder var body: some View {
        if let more {
            bubble
                .contentShape(Rectangle())
                .onTapGesture { more() }
                .accessibilityElement(children: .combine)
                .accessibilityAction(named: loc("tut.more")) { more() }
        } else {
            bubble
        }
    }

    private var line: Text {
        guard more != nil else { return Text(text) }
        return Text(text) + Text("  " + loc("tut.more")).font(Theme.font(size - 1, .bold)).foregroundStyle(Theme.ink2).underline()
    }

    private var bubble: some View {
        line
            .font(Theme.font(size)).foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12).padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#eef8f7"), in: RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .topLeading) {
                Path { p in p.move(to: CGPoint(x: 0, y: 7)); p.addLine(to: CGPoint(x: 7, y: 0)); p.addLine(to: CGPoint(x: 14, y: 7)) }
                    .fill(Color(hex: "#eef8f7")).frame(width: 14, height: 7).offset(x: 15, y: -7)
            }
    }
}

/// `ctrTrust`: the preferred operator's badge, or the dots of jobs done (with the owner's promise).
struct ContractTrust: View {
    @Environment(GameStore.self) private var store
    let owner: ContractOwner
    let promise: Bool
    var need = 3
    var size: CGFloat = 12.5

    var body: some View {
        let c = store.state?.local.contracts ?? ContractState(), K = store.state?.contractConfig
        let n = K?.prefNeed ?? need
        HStack(spacing: 10) {
            if c.pref {
                Text(loc("ctr.pref")).font(Theme.font(14, .heavy, condensed: true)).foregroundStyle(.white)
                    .padding(.horizontal, 9).padding(.vertical, 3).background(Color(hex: "#14a39a"), in: Capsule())
                Text(loc("ctr.pref.sub", percent((K?.prefPrice ?? 1.06) - 1)))
            } else {
                HStack(spacing: 5) {
                    ForEach(0..<n, id: \.self) { i in
                        Circle().fill(i < min(c.okWho, n) ? Color(hex: "#14a39a") : .white)
                            .overlay(Circle().stroke(Color(hex: "#14a39a"), lineWidth: 2)).frame(width: 14, height: 14)
                    }
                }
                Text(promise ? "“" + ctrText(owner, "promise") + "”" : loc("ctr.trust", num(min(c.okWho, n)), num(n)))
            }
        }
        .font(Theme.font(size).italic()).foregroundStyle(Theme.ink2)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// The first offer's scene: the region's guide says what's coming, at the off-map place (`ctrScene`, `storySay2`).
@MainActor
struct ContractSceneView: View {
    @Environment(GameStore.self) private var store
    let line: Int
    @State private var shown = 0

    var body: some View {
        let r = currentRegion, text = loc("ctr.\(r.rawValue).scene.\(line)")
        VStack {
            Spacer()
            HStack(alignment: .bottom, spacing: 10) {
                // v125.6: the name on a dark capsule (`.hzname`), readable over any part of the town
                VStack(spacing: -8) {
                    GuideAvatar(region: r, size: 64)
                    Text(guideName(r)).font(Theme.font(13, .heavy, condensed: true)).foregroundStyle(Color(hex: "#ffd27a")).fixedSize()
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e8b04a"), lineWidth: 1.5))
                }
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        Text(text).opacity(0)
                        Text(String(text.prefix(shown)))
                    }
                    .font(Theme.font(17, .medium)).foregroundStyle(Theme.ink)
                    HStack(spacing: 10) {
                        Button(loc("ctr.scene.skip")) {
                            SoundEngine.shared.play(.click)
                            store.nextContractLine(skip: true)
                        }
                        .buttonStyle(ChunkyButtonStyle(kind: .ghost, height: 46))
                        Button(loc(line < 3 ? "ctr.scene.next" : "ctr.scene.offer")) {
                            if shown < text.count { shown = text.count; return }
                            SoundEngine.shared.play(.click)
                            store.nextContractLine()
                        }
                        .buttonStyle(ChunkyButtonStyle(kind: .big, height: 46))
                    }
                }
                .padding(16)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 22))
                .compositingGroup()
                .shadow(color: .black.opacity(0.35), radius: 25, y: 20)
                .onTapGesture { shown = text.count }
            }
            .padding(16)
        }
        // a light scrim at the bottom so the bubble stands off the busy town
        .background(alignment: .bottom) {
            LinearGradient(colors: [Color(red: 20 / 255, green: 14 / 255, blue: 40 / 255).opacity(0), Color(red: 20 / 255, green: 14 / 255, blue: 40 / 255).opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 320)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .task(id: text) {
            shown = 0
            while shown < text.count {
                try? await Task.sleep(for: .milliseconds(22))
                shown = min(text.count, shown + 2)
                if shown % 8 == 0 { SoundEngine.shared.play(.blip) }
            }
        }
    }
}

/// JavaScript `Math.round` (halves up), like the core's.
func jsRoundUI(_ v: Double) -> Int { Int((v + 0.5).rounded(.down)) }
