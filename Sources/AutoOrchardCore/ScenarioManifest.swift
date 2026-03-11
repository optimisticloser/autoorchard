import Foundation

public struct ScenarioManifest: Codable, Sendable, Equatable {
    public var version: Int
    public var scenarios: [ScenarioDefinition]

    public init(version: Int = 1, scenarios: [ScenarioDefinition]) {
        self.version = version
        self.scenarios = scenarios
    }

    public static func load(from url: URL) throws -> ScenarioManifest {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(ScenarioManifest.self, from: data)
    }
}

public struct ScenarioDefinition: Codable, Sendable, Equatable {
    public var id: String
    public var fixturePath: String?
    public var expectedMetrics: [String: Double]
    public var variantMeasurements: [ExperimentVariant: [String: Double]]
    public var tags: [String]
    public var notes: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case fixturePath
        case expectedMetrics
        case variantMeasurements
        case tags
        case notes
    }

    public init(
        id: String,
        fixturePath: String? = nil,
        expectedMetrics: [String: Double],
        variantMeasurements: [ExperimentVariant: [String: Double]],
        tags: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.fixturePath = fixturePath
        self.expectedMetrics = expectedMetrics
        self.variantMeasurements = variantMeasurements
        self.tags = tags
        self.notes = notes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fixturePath = try container.decodeIfPresent(String.self, forKey: .fixturePath)
        expectedMetrics = try container.decode([String: Double].self, forKey: .expectedMetrics)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        let rawMeasurements = try container.decode([String: [String: Double]].self, forKey: .variantMeasurements)
        variantMeasurements = rawMeasurements.reduce(into: [:]) { partialResult, pair in
            if let variant = ExperimentVariant(rawValue: pair.key) {
                partialResult[variant] = pair.value
            }
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(fixturePath, forKey: .fixturePath)
        try container.encode(expectedMetrics, forKey: .expectedMetrics)
        try container.encode(Dictionary(uniqueKeysWithValues: variantMeasurements.map { ($0.key.rawValue, $0.value) }), forKey: .variantMeasurements)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

public struct ScenarioEvaluation: Codable, Sendable, Equatable {
    public var scenarioID: String
    public var measurements: [String: Double]
    public var notes: [String]

    public init(scenarioID: String, measurements: [String: Double], notes: [String] = []) {
        self.scenarioID = scenarioID
        self.measurements = measurements
        self.notes = notes
    }
}
