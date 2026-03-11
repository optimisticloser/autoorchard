import Foundation

public enum Ledger {
    public static func tsvHeader() -> String {
        "timestamp\tdecision\ttotal_score\tsummary\tnotes"
    }

    public static func tsvLine(for entry: LedgerEntry) -> String {
        let total = entry.score.map { String(format: "%.6f", $0.total) } ?? ""
        let notes = entry.notes.joined(separator: " | ")
        return [
            ISO8601DateFormatter().string(from: entry.timestamp),
            entry.decision.rawValue,
            total,
            entry.summary.replacingOccurrences(of: "\t", with: " "),
            notes.replacingOccurrences(of: "\t", with: " ")
        ].joined(separator: "\t")
    }
}
