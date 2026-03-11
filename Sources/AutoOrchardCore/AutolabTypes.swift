import Foundation

public struct ExperimentBudget: Codable, Sendable, Equatable {
    public var maxDurationSeconds: TimeInterval?
    public var maxScenarios: Int?
    public var maxIterations: Int?

    public init(maxDurationSeconds: TimeInterval? = nil, maxScenarios: Int? = nil, maxIterations: Int? = nil) {
        self.maxDurationSeconds = maxDurationSeconds
        self.maxScenarios = maxScenarios
        self.maxIterations = maxIterations
    }
}

public enum ExperimentVariant: String, Codable, Sendable, Equatable, CaseIterable {
    case baseline
    case candidate
}

public struct ScoreBreakdown: Codable, Sendable, Equatable {
    public var dimensions: [String: Double]
    public var total: Double

    public init(dimensions: [String: Double], total: Double) {
        self.dimensions = dimensions
        self.total = total
    }
}

public struct ExperimentResult: Codable, Sendable, Equatable {
    public var variant: ExperimentVariant
    public var decision: LedgerEntry.Decision
    public var score: ScoreBreakdown
    public var scenarioCount: Int
    public var summary: String
    public var notes: [String]
    public var bestKnownScore: Double?
    public var scoreDelta: Double?

    public init(
        variant: ExperimentVariant,
        decision: LedgerEntry.Decision,
        score: ScoreBreakdown,
        scenarioCount: Int,
        summary: String,
        notes: [String] = [],
        bestKnownScore: Double? = nil,
        scoreDelta: Double? = nil
    ) {
        self.variant = variant
        self.decision = decision
        self.score = score
        self.scenarioCount = scenarioCount
        self.summary = summary
        self.notes = notes
        self.bestKnownScore = bestKnownScore
        self.scoreDelta = scoreDelta
    }
}

public struct LedgerEntry: Codable, Sendable, Equatable {
    public enum Decision: String, Codable, Sendable {
        case baseline
        case keep
        case revert
        case crash
        case note
    }

    public var timestamp: Date
    public var variant: ExperimentVariant?
    public var decision: Decision
    public var summary: String
    public var score: ScoreBreakdown?
    public var scenarioCount: Int?
    public var bestKnownScore: Double?
    public var scoreDelta: Double?
    public var notes: [String]

    public init(
        timestamp: Date = .now,
        variant: ExperimentVariant? = nil,
        decision: Decision,
        summary: String,
        score: ScoreBreakdown? = nil,
        scenarioCount: Int? = nil,
        bestKnownScore: Double? = nil,
        scoreDelta: Double? = nil,
        notes: [String] = []
    ) {
        self.timestamp = timestamp
        self.variant = variant
        self.decision = decision
        self.summary = summary
        self.score = score
        self.scenarioCount = scenarioCount
        self.bestKnownScore = bestKnownScore
        self.scoreDelta = scoreDelta
        self.notes = notes
    }

    public init(timestamp: Date = .now, result: ExperimentResult) {
        self.init(
            timestamp: timestamp,
            variant: result.variant,
            decision: result.decision,
            summary: result.summary,
            score: result.score,
            scenarioCount: result.scenarioCount,
            bestKnownScore: result.bestKnownScore,
            scoreDelta: result.scoreDelta,
            notes: result.notes
        )
    }
}

public struct LabConfig: Codable, Sendable, Equatable {
    public var name: String
    public var kind: String
    public var budget: ExperimentBudget
    public var documentationProvider: String

    public init(name: String, kind: String, budget: ExperimentBudget, documentationProvider: String = "cupertino") {
        self.name = name
        self.kind = kind
        self.budget = budget
        self.documentationProvider = documentationProvider
    }
}
