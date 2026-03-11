import Testing
@testable import AutolabCore

@Test("ledger emits a stable TSV line")
func ledgerLineIncludesDecisionAndScore() {
    let entry = LedgerEntry(
        decision: .keep,
        summary: "improved receipt fidelity",
        score: .init(dimensions: ["total": 0.9], total: 0.9),
        notes: ["baseline protected"]
    )

    let line = Ledger.tsvLine(for: entry)
    #expect(line.contains("keep"))
    #expect(line.contains("0.900000"))
    #expect(line.contains("improved receipt fidelity"))
}
