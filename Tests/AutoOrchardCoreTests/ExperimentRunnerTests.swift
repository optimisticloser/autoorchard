import Foundation
import Testing
@testable import AutoOrchardCore

@Test("ledger emits stable experiment columns")
func ledgerLineIncludesVariantAndComparisonFields() {
    let entry = LedgerEntry(
        timestamp: Date(timeIntervalSince1970: 0),
        variant: .candidate,
        decision: .keep,
        summary: "improved receipt fidelity",
        score: .init(dimensions: ["total": 0.9], total: 0.9),
        scenarioCount: 2,
        bestKnownScore: 0.8,
        scoreDelta: 0.1,
        notes: ["baseline protected"]
    )

    let line = Ledger.tsvLine(for: entry)
    #expect(line.contains("candidate"))
    #expect(line.contains("keep"))
    #expect(line.contains("0.900000"))
    #expect(line.contains("0.800000"))
    #expect(line.contains("0.100000"))
}

@Test("scenario manifest loads deterministically")
func scenarioManifestLoadingIsDeterministic() throws {
    let labRoot = try makeLabRoot()
    let manifestURL = labRoot.appendingPathComponent("Scenarios/manifest.json")
    let manifest = try ScenarioManifest.load(from: manifestURL)

    #expect(manifest.version == 1)
    #expect(manifest.scenarios.count == 2)
    #expect(manifest.scenarios.map(\.id) == ["protected-baseline", "weak-case"])
}

@Test("baseline run appends a baseline ledger entry")
func baselineRunWritesLedgerEntry() throws {
    let labRoot = try makeLabRoot()
    let runner = ExperimentRunner(paths: .init(labRoot: labRoot))

    let result = try runner.runBaseline()

    #expect(result.variant == .baseline)
    #expect(result.decision == .baseline)
    #expect(result.scenarioCount == 2)
    #expect(result.score.total > 0.8)

    let ledger = try String(contentsOf: labRoot.appendingPathComponent("Ledger/results.tsv"), encoding: .utf8)
    #expect(ledger.contains("\tbaseline\tbaseline\t"))
}

@Test("candidate run compares against best known baseline and keeps improvements")
func candidateRunKeepsWhenItBeatsBaseline() throws {
    let labRoot = try makeLabRoot()
    let runner = ExperimentRunner(paths: .init(labRoot: labRoot))

    _ = try runner.runBaseline()
    let result = try runner.runCandidate()

    #expect(result.variant == .candidate)
    #expect(result.decision == .keep)
    #expect(result.bestKnownScore != nil)
    #expect((result.scoreDelta ?? 0) > 0)

    let ledger = try String(contentsOf: labRoot.appendingPathComponent("Ledger/results.tsv"), encoding: .utf8)
    #expect(ledger.contains("\tcandidate\tkeep\t"))
}

@Test("failed runs still append crash ledger notes")
func failedRunsWriteCrashEntry() throws {
    struct FailingEvaluator: ScenarioEvaluator {
        func evaluate(scenario: ScenarioDefinition, variant: ExperimentVariant, labRoot: URL) throws -> ScenarioEvaluation {
            struct TestFailure: LocalizedError {
                var errorDescription: String? { "intentional failure" }
            }
            throw TestFailure()
        }
    }

    let labRoot = try makeLabRoot()
    let runner = ExperimentRunner(paths: .init(labRoot: labRoot), evaluator: FailingEvaluator())

    #expect(throws: Error.self) {
        try runner.runBaseline()
    }

    let ledger = try String(contentsOf: labRoot.appendingPathComponent("Ledger/results.tsv"), encoding: .utf8)
    #expect(ledger.contains("\tbaseline\tcrash\t"))
    #expect(ledger.contains("intentional failure"))
}

@Test("keep revert hooks stay manual until git integration lands")
func keepRevertHooksReportSafeManualAction() {
    let result = ExperimentResult(
        variant: .candidate,
        decision: .revert,
        score: .init(dimensions: ["fidelity": 0.5], total: 0.5),
        scenarioCount: 1,
        summary: "candidate regressed"
    )
    let hooks = SafeKeepRevertHooks()
    let action = hooks.action(for: result, workspace: .init(isGitRepository: true, hasUncommittedChanges: false))

    #expect(action == .requireManualReview(reason: "candidate lost; restore the previous known-good state before continuing"))
}

private func makeLabRoot() throws -> URL {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: root.appendingPathComponent("Config"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: root.appendingPathComponent("Scenarios"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: root.appendingPathComponent("Ledger"), withIntermediateDirectories: true)

    let config = LabConfig(
        name: "Receipt Lab",
        kind: "receipt-pipeline",
        budget: .init(maxScenarios: 2)
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(config).write(to: root.appendingPathComponent("Config/lab.json"))

    let manifest = ScenarioManifest(
        scenarios: [
            ScenarioDefinition(
                id: "protected-baseline",
                expectedMetrics: ["fidelity": 1, "truthfulness": 1],
                variantMeasurements: [
                    .baseline: ["fidelity": 0.9, "truthfulness": 1],
                    .candidate: ["fidelity": 0.96, "truthfulness": 1]
                ],
                tags: ["protected"]
            ),
            ScenarioDefinition(
                id: "weak-case",
                expectedMetrics: ["fidelity": 1, "truthfulness": 1],
                variantMeasurements: [
                    .baseline: ["fidelity": 0.7, "truthfulness": 1],
                    .candidate: ["fidelity": 0.9, "truthfulness": 1]
                ],
                tags: ["weak"]
            )
        ]
    )
    try encoder.encode(manifest).write(to: root.appendingPathComponent("Scenarios/manifest.json"))
    try (Ledger.tsvHeader() + "\n").write(to: root.appendingPathComponent("Ledger/results.tsv"), atomically: true, encoding: .utf8)
    return root
}

