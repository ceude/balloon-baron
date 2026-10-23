import Foundation
import BalloonBaronCore

/// Keeps the save safe. Besides the save itself there is yesterday's copy and an iCloud copy, and a launch guard
/// notices when the app keeps closing before it settles, so a bad save never locks the player out.
enum SaveVault {
    private static var dir: URL {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    private static var current: URL { dir.appendingPathComponent("save.json") }
    private static var previous: URL { dir.appendingPathComponent("save.prev.json") }
    private static let dayKey = "save.day"
    /// Key-value storage holds 1 MB in all, so the iCloud copy is compressed and skipped if it would not fit.
    private static let cloudKey = "save.zlib"
    private static let cloudLimit = 900_000

    /// Writes the save (on the caller's queue). The first write of a new game day keeps the old file as yesterday's copy.
    static func write(_ state: GameState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        let fm = FileManager.default, defaults = UserDefaults.standard
        if defaults.integer(forKey: dayKey) != state.day, fm.fileExists(atPath: current.path) {
            try? fm.removeItem(at: previous)
            try? fm.copyItem(at: current, to: previous)
            defaults.set(state.day, forKey: dayKey)
        }
        try? data.write(to: current, options: .atomic)
        if let packed = try? (data as NSData).compressed(using: .zlib) as Data, packed.count < cloudLimit {
            NSUbiquitousKeyValueStore.default.set(packed, forKey: cloudKey)
        }
    }

    /// The save to play: today's file, else yesterday's, else the iCloud copy (a reinstalled app gets its game back).
    /// `preferPrevious` starts from yesterday's copy when today's keeps crashing the app.
    static func load(preferPrevious: Bool) -> GameState? {
        let files = preferPrevious ? [previous, current] : [current, previous]
        for url in files {
            if let data = try? Data(contentsOf: url), let s = try? JSONDecoder().decode(GameState.self, from: data) { return s }
        }
        let cloud = NSUbiquitousKeyValueStore.default
        cloud.synchronize()
        if let packed = cloud.data(forKey: cloudKey), let data = try? (packed as NSData).decompressed(using: .zlib) as Data {
            return try? JSONDecoder().decode(GameState.self, from: data)
        }
        return nil
    }

    /// Starting over clears every copy, so the old game cannot come back.
    static func wipe() {
        try? FileManager.default.removeItem(at: current)
        try? FileManager.default.removeItem(at: previous)
        UserDefaults.standard.removeObject(forKey: dayKey)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: cloudKey)
    }
}

/// Counts launches that ended before the game settled (a crash at start). Two in a row: the next launch skips the
/// intro and the waiting popups. Three: it also goes back to yesterday's save.
enum LaunchGuard {
    /// A tiny file rather than UserDefaults, which may not reach the disk before a crash.
    private static var url: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("launch.unsettled")
    }

    /// Call once at launch. Returns how many launches before this one never settled.
    static func begin() -> Int {
        let n = (try? String(contentsOf: url, encoding: .utf8)).flatMap { Int($0) } ?? 0
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? String(n + 1).write(to: url, atomically: true, encoding: .utf8)
        return n
    }

    /// The app ran for a while or went to the background: it did not crash at start.
    static func settled() {
        try? FileManager.default.removeItem(at: url)
    }
}
