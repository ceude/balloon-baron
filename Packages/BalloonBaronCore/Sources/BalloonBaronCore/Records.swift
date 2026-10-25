import Foundation

/// Sponsored world records, the holding's fifth desk. Open once you've entered Luxor. Text: `record.<rawValue>`.
public enum RecordAttempt: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case altitude, world

    public var cost: Int { [400000, 900000][index] }
    public var days: Int { [25, 40][index] }
    /// Shown odds. The first attempt at each record always succeeds; the odds apply when you try to beat your own.
    public var odds: Double { [0.65, 0.5][index] }
    /// Lasting demand boost in every region for setting the record.
    public var boost: Double { [0.05, 0.1][index] }
    /// Each time you beat your own record, up to `maxBoost` in all.
    public static let repeatBoost = 0.02, maxBoost = 0.25
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public struct RecordRun: Codable, Equatable, Sendable {
    public var kind: RecordAttempt
    public var done: Int
}

/// A brand's product-shaped balloon, the holding's sixth desk. It pays the holding every day and costs a little
/// popularity in the region where it flies. Text: `adshape.<rawValue>`.
/// A holding investment worth a word from the guide and a story in the paper. Text: `hez.deed.<rawValue>`, `paper.deed.<rawValue>`.
public enum HoldingDeed: String, Codable, Sendable {
    case tv, billboards, celebrity, research, office, record, shape
}

public enum AdShape: String, Codable, CaseIterable, Sendable {
    case bottle, rocket, shoe

    public var days: Int { [30, 45, 60][index] }
    public var pay: Int { [4000, 6500, 9000][index] }
    public var repLoss: Double { [0.001, 0.0015, 0.002][index] }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public struct AdContract: Codable, Equatable, Sendable {
    public var shape: AdShape
    public var until: Int
    public var region: RegionID
}

extension GameState {
    public var recordsOpen: Bool { owns(.lux) }
    public func recordSet(_ k: RecordAttempt) -> Bool { holding.records?[k] != nil }
    /// The shaped balloon over a region today, if any.
    public func adShape(over r: RegionID) -> AdShape? {
        guard let a = holding.adShape, a.until >= day, a.region == r else { return nil }
        return a.shape
    }
}

extension Game {
    @discardableResult
    public mutating func startRecord(_ k: RecordAttempt) -> Bool {
        guard state.recordsOpen, state.holding.record == nil, spendHolding(k.cost) else { return false }
        state.holding.record = RecordRun(kind: k, done: state.day + k.days)
        celebrate(.record)
        return true
    }

    @discardableResult
    public mutating func signAdShape(_ k: AdShape) -> Bool {
        if let a = state.holding.adShape, a.until >= state.day { return false }
        state.holding.adShape = AdContract(shape: k, until: state.day + k.days, region: state.region)
        celebrate(.shape)
        return true
    }

    /// Breaking a running shape deal costs what the brand has paid so far plus half of what's left, so it
    /// is always a loss. Nil when no deal is running.
    public var adBreakFee: Int? {
        guard let a = state.holding.adShape, a.until >= state.day else { return nil }
        let left = min(max(a.until - state.day, 0), a.shape.days), paid = a.shape.days - left
        return jsRound(Double(paid * a.shape.pay + left * a.shape.pay / 2) / 100) * 100
    }

    @discardableResult
    public mutating func breakAdShape() -> Bool {
        guard let fee = adBreakFee, spendHolding(fee) else { return false }
        state.holding.adShape = nil
        return true
    }

    /// The attempt ends on its day. Returns nothing for the ledger; the news says how it went.
    mutating func recordDay() -> Int {
        guard let r = state.holding.record, state.day >= r.done else { return 0 }
        state.holding.record = nil
        let first = !state.recordSet(r.kind)
        if first || rng.chance(r.kind.odds) {
            var set = state.holding.records ?? [:]
            set[r.kind] = state.day
            state.holding.records = set
            state.holding.recordBoost = min(RecordAttempt.maxBoost, (state.holding.recordBoost ?? 0) + (first ? r.kind.boost : RecordAttempt.repeatBoost))
            state.rep = min(1.4, state.rep + 0.1)
            addPaper(.worldRecord(r.kind))
            state.hezQueue.append(.record(r.kind, success: true))
        } else {
            state.hezQueue.append(.record(r.kind, success: false))
        }
        return 0
    }

    /// The brand pays the holding; tourists in its region like the company a little less. Returns the payment.
    mutating func adShapeDay() -> Int {
        guard let a = state.holding.adShape, state.day <= a.until else { return 0 }
        state.holding.cash += a.shape.pay
        state.holding.log(day: state.day, income: a.shape.pay)
        if a.region == state.region {
            state.rep = max(Rules.repRange.lowerBound, state.rep - a.shape.repLoss)
        } else if var p = state.parked[a.region] {
            p.state.rep = max(Rules.repRange.lowerBound, p.state.rep - a.shape.repLoss)
            state.parked[a.region] = p
        }
        return a.shape.pay
    }
}
