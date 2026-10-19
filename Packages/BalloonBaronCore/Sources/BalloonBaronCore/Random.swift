import Foundation

/// Seedable generator so simulations and tests are reproducible.
public struct SplitMix64: RandomNumberGenerator, Codable, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension SplitMix64 {
    /// Uniform in [0, 1).
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    mutating func range(_ a: Double, _ b: Double) -> Double { a + unit() * (b - a) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
    mutating func pick<T>(_ items: [T]) -> T { items[Int(unit() * Double(items.count))] }
    mutating func int(_ n: Int) -> Int { Int(unit() * Double(n)) }
}

@inlinable func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T { max(lo, min(hi, v)) }
@inlinable func lerp(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }

/// JavaScript `Math.round` semantics (halves round up), so numbers match the prototype.
@inlinable func jsRound(_ v: Double) -> Int { Int((v + 0.5).rounded(.down)) }
