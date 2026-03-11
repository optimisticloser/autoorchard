import Foundation

public protocol ScenarioEvaluator: Sendable {
    func evaluate(
        scenario: ScenarioDefinition,
        variant: ExperimentVariant,
        labRoot: URL
    ) throws -> ScenarioEvaluation
}

public protocol ScoreContract: Sendable {
    func score(
        evaluations: [ScenarioEvaluation],
        manifest: ScenarioManifest
    ) throws -> ScoreBreakdown
}

public struct ExpectedMetricsScoreContract: ScoreContract {
    public init() {}

    public func score(
        evaluations: [ScenarioEvaluation],
        manifest: ScenarioManifest
    ) throws -> ScoreBreakdown {
        let evaluationsByID = Dictionary(uniqueKeysWithValues: evaluations.map { ($0.scenarioID, $0) })
        var dimensionValues: [String: [Double]] = [:]

        for scenario in manifest.scenarios {
            guard let evaluation = evaluationsByID[scenario.id] else {
                throw ExperimentRunnerError.missingEvaluation(scenarioID: scenario.id)
            }

            for (dimension, expected) in scenario.expectedMetrics.sorted(by: { $0.key < $1.key }) {
                let actual = evaluation.measurements[dimension] ?? 0
                let difference = abs(expected - actual)
                let normalized = max(0, 1 - difference)
                dimensionValues[dimension, default: []].append(normalized)
            }
        }

        let sortedDimensions = dimensionValues.keys.sorted()
        let breakdown = sortedDimensions.reduce(into: [String: Double]()) { partialResult, dimension in
            let values = dimensionValues[dimension] ?? []
            partialResult[dimension] = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        }

        let total: Double
        if breakdown.isEmpty {
            total = 0
        } else {
            total = breakdown.values.reduce(0, +) / Double(breakdown.count)
        }

        return ScoreBreakdown(dimensions: breakdown, total: total)
    }
}

public struct ManifestScenarioEvaluator: ScenarioEvaluator {
    public init() {}

    public func evaluate(
        scenario: ScenarioDefinition,
        variant: ExperimentVariant,
        labRoot: URL
    ) throws -> ScenarioEvaluation {
        guard let measurements = scenario.variantMeasurements[variant] else {
            throw ExperimentRunnerError.missingVariantMeasurements(
                scenarioID: scenario.id,
                variant: variant
            )
        }

        var notes: [String] = []
        if let fixturePath = scenario.fixturePath {
            notes.append("fixture=\(fixturePath)")
            let fixtureURL = labRoot.appendingPathComponent(fixturePath)
            if !FileManager.default.fileExists(atPath: fixtureURL.path) {
                notes.append("fixture-missing")
            }
        }

        return ScenarioEvaluation(scenarioID: scenario.id, measurements: measurements, notes: notes)
    }
}

