import Foundation

/// Hezarfen notices a good move early on. Text: `hez.praise.<rawValue>`.
public enum Praise: String, Codable, CaseIterable, Sendable {
    /// Stayed on the ground on a red-flag day.
    case red
    /// First perfect landing; first special request done; three good landings in a row.
    case perfect, mission, run
    /// Second balloon, first pilot, first hotel deal, first building upgrade.
    case fleet, pilot, hotel, build
    /// Five profitable days in a row; 4.3 stars.
    case profit, stars
}

extension Game {
    /// Whether a waiting praise still holds when its turn comes (v121.12).
    func praiseStillTrue(_ p: Praise) -> Bool {
        switch p {
        case .fleet: return state.balloons.count >= 2
        case .pilot: return !state.pilots.isEmpty
        case .hotel: return !state.hotelDeals.isEmpty
        case .stars: return state.stars >= 4.3
        default: return true
        }
    }

    /// In the first 40 days in Cappadocia: each praise once, at most every other day, one waiting at a time.
    /// Port of the prototype's `praiseCheck`.
    mutating func praiseCheck(flight: FlightResult?, waitedOutRed: Bool) {
        guard state.region == .cap, state.day <= 40 else { return }
        if let f = flight {
            state.goodRun = f.landing == .perfect || f.landing == .good ? (state.goodRun ?? 0) + 1 : 0
        }
        if state.hezQueue.contains(where: { if case .praise = $0 { return true } else { return false } }) { return }
        if state.day - (state.praiseDay ?? -9) < 2 { return }
        let net = state.netHistory
        func ok(_ p: Praise) -> Bool {
            switch p {
            case .red: return waitedOutRed
            case .perfect: return flight?.landing == .perfect
            case .mission: return flight?.missionDone == true && flight?.mission != nil
            case .run: return (state.goodRun ?? 0) >= 3
            case .fleet: return state.balloons.count >= 2
            case .pilot: return !state.pilots.isEmpty
            case .hotel: return !state.hotelDeals.isEmpty
            case .build: return (state.local.buildings ?? [:]).values.contains { $0 >= 2 }
            case .profit: return net.count >= 5 && net.suffix(5).allSatisfy { $0 > 0 }
            case .stars: return state.stars >= 4.3
            }
        }
        guard let p = Praise.allCases.first(where: { ok($0) && !(state.praised ?? []).contains($0) }) else { return }
        state.praised = (state.praised ?? []).union([p])
        state.praiseDay = state.day
        state.hezQueue.append(.praise(p))
    }
}
