import Foundation

/// v123: the family's letter (`letterDue`, `showLetter`): once, from the morning of day 50, after Hezarfen's cards. The
/// app shows it (not on autopilot, not while travelling) and asks for a review; the core only keeps that it was shown
/// and whether the review button was tapped. Its text lives in the app (`letter.*`).
public enum Letter {
    /// The day the letter comes (its text counts the company's days).
    public static let day = 50
}

extension GameState {
    /// The letter hasn't been shown and its day has come.
    public var letterDue: Bool { letterDay == nil && day >= Letter.day }
}

extension Game {
    /// The letter is on screen: it never comes again.
    public mutating func markLetterShown() {
        guard state.letterDay == nil else { return }
        state.letterDay = state.day
    }

    /// "Write a review on the App Store" was tapped.
    public mutating func markLetterRated() {
        state.letterRated = true
    }
}
