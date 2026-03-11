import Foundation

public enum Ledger {
    public static func tsvHeader() -> String {
        "timestamp\tvariant\tdecision\ttotal_score\tscenario_count\tbest_known_score\tscore_delta\tsummary\tnotes"
    }

    public static func tsvLine(for entry: LedgerEntry) -> String {
        let total = entry.score.map { format($0.total) } ?? ""
        let scenarioCount = entry.scenarioCount.map(String.init) ?? ""
        let bestKnownScore = entry.bestKnownScore.map(format) ?? ""
        let scoreDelta = entry.scoreDelta.map(format) ?? ""
        let notes = entry.notes.joined(separator: " | ")

        return [
            ISO8601DateFormatter().string(from: entry.timestamp),
            entry.variant?.rawValue ?? "",
            entry.decision.rawValue,
            total,
            scenarioCount,
            bestKnownScore,
            scoreDelta,
            sanitize(entry.summary),
            sanitize(notes)
        ].joined(separator: "\t")
    }

    public static func append(_ entry: LedgerEntry, to url: URL) throws {
        let fileManager = FileManager.default
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let needsHeader = !fileManager.fileExists(atPath: url.path) || ((try? String(contentsOf: url, encoding: .utf8).isEmpty) ?? true)
        let prefix = needsHeader ? tsvHeader() + "\n" : ""
        let line = prefix + tsvLine(for: entry) + "\n"
        let data = Data(line.utf8)

        if fileManager.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } else {
            try data.write(to: url)
        }
    }

    public static func bestRecordedScore(from url: URL) throws -> Double? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let lines = try String(contentsOf: url, encoding: .utf8)
            .split(whereSeparator: \ .isNewline)
            .map(String.init)

        guard lines.count > 1 else {
            return nil
        }

        let scores = lines.dropFirst().compactMap { line -> Double? in
            let columns = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard columns.count >= 4 else {
                return nil
            }

            let decision = String(columns[2])
            guard decision == LedgerEntry.Decision.baseline.rawValue || decision == LedgerEntry.Decision.keep.rawValue else {
                return nil
            }

            return Double(columns[3])
        }

        return scores.max()
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "\t", with: " ")
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}

