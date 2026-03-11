import Foundation

public enum ExperimentRunnerError: Error, LocalizedError, Equatable {
    case missingManifest(URL)
    case noScenarios
    case missingEvaluation(scenarioID: String)
    case missingVariantMeasurements(scenarioID: String, variant: ExperimentVariant)

    public var errorDescription: String? {
        switch self {
        case .missingManifest(let url):
            return "Missing scenario manifest at \(url.path)"
        case .noScenarios:
            return "No scenarios were available to evaluate"
        case .missingEvaluation(let scenarioID):
            return "Missing evaluation for scenario '\(scenarioID)'"
        case .missingVariantMeasurements(let scenarioID, let variant):
            return "Missing \(variant.rawValue) measurements for scenario '\(scenarioID)'"
        }
    }
}

public struct ExperimentRunner: Sendable {
    public struct Paths: Sendable, Equatable {
        public var labRoot: URL
        public var configURL: URL
        public var scenarioManifestURL: URL
        public var ledgerURL: URL

        public init(labRoot: URL) {
            self.labRoot = labRoot
            self.configURL = labRoot.appendingPathComponent("Config/lab.json")
            self.scenarioManifestURL = labRoot.appendingPathComponent("Scenarios/manifest.json")
            self.ledgerURL = labRoot.appendingPathComponent("Ledger/results.tsv")
        }
    }

    public var paths: Paths
    public var evaluator: any ScenarioEvaluator
    public var scoreContract: any ScoreContract

    public init(
        paths: Paths,
        evaluator: any ScenarioEvaluator = ManifestScenarioEvaluator(),
        scoreContract: any ScoreContract = ExpectedMetricsScoreContract()
    ) {
        self.paths = paths
        self.evaluator = evaluator
        self.scoreContract = scoreContract
    }

    public func runBaseline() throws -> ExperimentResult {
        try run(variant: .baseline)
    }

    public func runCandidate() throws -> ExperimentResult {
        try run(variant: .candidate)
    }

    public func run(variant: ExperimentVariant) throws -> ExperimentResult {
        let config = try loadConfig()
        let manifest = try loadManifest()
        let scenarios = boundedScenarios(from: manifest.scenarios, budget: config.budget)

        guard !scenarios.isEmpty else {
            throw ExperimentRunnerError.noScenarios
        }

        do {
            let evaluations = try scenarios.map {
                try evaluator.evaluate(scenario: $0, variant: variant, labRoot: paths.labRoot)
            }

            let boundedManifest = ScenarioManifest(version: manifest.version, scenarios: scenarios)
            let score = try scoreContract.score(evaluations: evaluations, manifest: boundedManifest)
            let bestKnownScore = try Ledger.bestRecordedScore(from: paths.ledgerURL)
            let result = makeResult(
                variant: variant,
                scenarioCount: scenarios.count,
                score: score,
                bestKnownScore: bestKnownScore
            )
            try Ledger.append(LedgerEntry(result: result), to: paths.ledgerURL)
            return result
        } catch {
            let crashEntry = LedgerEntry(
                variant: variant,
                decision: .crash,
                summary: "\(variant.rawValue) run crashed",
                notes: [error.localizedDescription]
            )
            try Ledger.append(crashEntry, to: paths.ledgerURL)
            throw error
        }
    }

    private func loadConfig() throws -> LabConfig {
        let data = try Data(contentsOf: paths.configURL)
        return try JSONDecoder().decode(LabConfig.self, from: data)
    }

    private func loadManifest() throws -> ScenarioManifest {
        guard FileManager.default.fileExists(atPath: paths.scenarioManifestURL.path) else {
            throw ExperimentRunnerError.missingManifest(paths.scenarioManifestURL)
        }

        return try ScenarioManifest.load(from: paths.scenarioManifestURL)
    }

    private func boundedScenarios(from scenarios: [ScenarioDefinition], budget: ExperimentBudget) -> [ScenarioDefinition] {
        let limit = budget.maxScenarios ?? scenarios.count
        return Array(scenarios.prefix(limit))
    }

    private func makeResult(
        variant: ExperimentVariant,
        scenarioCount: Int,
        score: ScoreBreakdown,
        bestKnownScore: Double?
    ) -> ExperimentResult {
        let decision: LedgerEntry.Decision
        let summary: String
        let notes: [String]
        let scoreDelta: Double?

        switch variant {
        case .baseline:
            decision = .baseline
            summary = "baseline scored \(format(score.total)) across \(scenarioCount) scenarios"
            notes = []
            scoreDelta = bestKnownScore.map { score.total - $0 }
        case .candidate:
            let delta = bestKnownScore.map { score.total - $0 }
            scoreDelta = delta
            if let bestKnownScore, score.total > bestKnownScore {
                decision = .keep
                summary = "candidate beat best known score by \(format(score.total - bestKnownScore))"
                notes = ["candidate exceeded protected baseline"]
            } else if let bestKnownScore {
                decision = .revert
                summary = "candidate regressed by \(format(bestKnownScore - score.total))"
                notes = ["candidate did not beat protected baseline"]
            } else {
                decision = .keep
                summary = "candidate established the first recorded score"
                notes = ["no baseline was recorded yet"]
            }
        }

        return ExperimentResult(
            variant: variant,
            decision: decision,
            score: score,
            scenarioCount: scenarioCount,
            summary: summary,
            notes: notes,
            bestKnownScore: bestKnownScore,
            scoreDelta: scoreDelta
        )
    }

    private func format(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}

