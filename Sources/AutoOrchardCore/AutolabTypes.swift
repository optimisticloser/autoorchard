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

public struct ScoreBreakdown: Codable, Sendable, Equatable {
    public var dimensions: [String: Double]
    public var total: Double

    public init(dimensions: [String: Double], total: Double) {
        self.dimensions = dimensions
        self.total = total
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
    public var decision: Decision
    public var summary: String
    public var score: ScoreBreakdown?
    public var notes: [String]

    public init(timestamp: Date = .now, decision: Decision, summary: String, score: ScoreBreakdown? = nil, notes: [String] = []) {
        self.timestamp = timestamp
        self.decision = decision
        self.summary = summary
        self.score = score
        self.notes = notes
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
