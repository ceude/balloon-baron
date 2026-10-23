import SwiftUI
import BalloonBaronCore

/// A parked region's problem: two choices with the region guide's advice, or decide later.
struct IssueView: View {
    @Environment(GameStore.self) private var store
    let region: RegionID

    var body: some View {
        WorldPopup(topBar: Theme.red, onClose: later) {
            if let auto = store.state?.parked[region]?.auto, let open = auto.issue {
                content(open.kind, auto)
            }
            BigButton(title: loc("issueSheet.later"), style: .ghost) { later() }
        }
    }

    @ViewBuilder
    private func content(_ issue: Issue, _ auto: Autopilot) -> some View {
        Text(loc("issueSheet.region", region.title))
            .font(Theme.font(14, .heavy, condensed: true))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(Theme.red)
        Text(issue.title)
            .font(Theme.font(28, .heavy, condensed: true))
            .foregroundStyle(Theme.ink)
        Text(issue.body + " " + loc("issueSheet.halved", eurH(auto.today)))
            .font(Theme.font(16, .medium))
            .foregroundStyle(Theme.ink)
        hezarfenLine(issue)
        option(issue, .a, auto)
        option(issue, .b, auto)
    }

    private func hezarfenLine(_ issue: Issue) -> some View {
        HStack(alignment: .top, spacing: 10) {
            GuideAvatar(region: region, size: 34)
            (Text(guideName(region) + ": ").font(Theme.font(14, .bold)) + Text(issue.hezarfen).font(Theme.font(14)))
                .foregroundStyle(Theme.ink)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
    }

    private func option(_ issue: Issue, _ choice: Issue.Choice, _ auto: Autopilot) -> some View {
        let cost = issue.cost(choice, base: auto.base)
        let affordable = cost == 0 || (store.state?.holding.cash ?? 0) >= cost
        let title = cost > 0 ? "\(issue.option(choice)) (\(eurH(cost)))" : issue.option(choice)
        let isA = choice == .a
        return Button { decide(choice) } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.font(18, .heavy, condensed: true))
                Text(issue.note(choice))
                    .font(Theme.font(13, .medium))
                    .opacity(0.85)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(isA ? Color.white : Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(isA ? Theme.coral : Color.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isA ? Color.clear : Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
        .opacity(affordable ? 1 : 0.45)
    }

    private func decide(_ choice: Issue.Choice) {
        let r = region
        store.act { g in _ = g.resolveIssue(in: r, choice: choice) }
        if store.state?.region == r {
            // "Go and handle it" moved you into the region: close the pages too.
            store.closePage()
        } else {
            later()
        }
    }

    private func later() {
        store.issueRegion = nil
        store.showNextHezarfen()
    }
}
