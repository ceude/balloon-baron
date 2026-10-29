import Foundation

extension RegionState {
    /// The region as the save code carries it: the eight reviews on screen and the sixty days of the chart.
    func forCode() -> RegionState {
        var r = self
        r.reviews = Array(reviews.prefix(8))
        r.repHistory = Array(repHistory.suffix(60))
        return r
    }
}

extension GameState {
    /// v124.3: the state the save code carries. It leaves out what the game rebuilds or never shows again:
    /// tomorrow's paper, reviews past the eight on screen, the reputation history past the sixty days in the chart.
    /// Every key stays present, so a trimmed state decodes like a full one.
    public func forCode() -> GameState {
        var s = self
        s.paperNext = nil
        s.local = local.forCode()
        for (id, p) in parked { s.parked[id]?.state = p.state.forCode() }
        return s
    }
}
