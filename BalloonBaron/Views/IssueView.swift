import SwiftUI
import BalloonBaronCore

/// A region's problem: two choices with the region guide's advice. From elsewhere you can also fly over. A parked region's problem
/// halves its income until you decide; in the region you're in, the choice plays out on the spot.
struct IssueView: View {
    @Environment(GameStore.self) private var store
    let region: RegionID

    private var live: Bool { store.state?.region == region }

    var body: some View {
        // No "later": here you decide; from elsewhere you decide or fly over to see it for yourself.
        WorldPopup(topBar: Theme.red, bottom: live) {
            if live, let kind = store.game?.liveIssue {
                content(kind, nil)
            } else if let auto = store.state?.parked[region]?.auto, let open = auto.issue {
                content(open.kind, auto)
                BigButton(title: loc("issueSheet.goThere", region.title), style: .ghost) {
                    store.issueScene = false
                    store.goTo(region)
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ issue: Issue, _ auto: Autopilot?) -> some View {
        Text(loc(auto == nil ? "issueSheet.here" : "issueSheet.region", region.title))
            .font(Theme.font(14, .heavy, condensed: true))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(Theme.red)
        Text(issue.title)
            .font(Theme.font(28, .heavy, condensed: true))
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
        Text(issue.body + " " + (auto.map { loc("issueSheet.halved", eurH($0.today)) } ?? loc("issueSheet.yourCall")))
            .font(Theme.font(16, .medium))
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
        hezarfenLine(issue)
        option(issue, .a, auto)
        option(issue, .b, auto)
    }

    private func hezarfenLine(_ issue: Issue) -> some View {
        HStack(alignment: .top, spacing: 10) {
            GuideAvatar(region: region, size: 34)
            (Text(guideName(region) + ": ").font(Theme.font(14, .bold)) + Text(issue.hezarfen).font(Theme.font(14)))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
    }

    private func option(_ issue: Issue, _ choice: Issue.Choice, _ auto: Autopilot?) -> some View {
        let cost = store.game?.issueCost(in: region, choice: choice) ?? 0
        let affordable = cost == 0 || (store.state?.holding.cash ?? 0) >= cost
        let title = cost > 0 ? "\(issue.option(choice)) (\(eurH(cost)))" : issue.option(choice)
        let isA = choice == .a
        return Button { decide(choice) } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.font(18, .heavy, condensed: true))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(auto == nil ? issue.liveNote(choice) : issue.note(choice))
                    .font(Theme.font(13, .medium))
                    .opacity(0.85)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isA && affordable ? Color.white : isA ? Theme.offText : Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(isA && affordable ? Theme.coral : isA ? Theme.offFill : Color.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isA ? Color.clear : Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
        .opacity(affordable || isA ? 1 : 0.55)
    }

    private func decide(_ choice: Issue.Choice) {
        let r = region
        let wasHere = live
        store.act { g in _ = g.resolveIssue(in: r, choice: choice) }
        if wasHere {
            later()
        } else if store.state?.region == r {
            // "Go and handle it" moved you into the region: close the pages too.
            store.closePage()
        } else {
            later()
        }
    }

    private func later() {
        store.issueRegion = nil
        store.issueScene = false
        store.showNextHezarfen()
    }
}
