import Foundation

public enum LabScaffolder {
    public static func createLab(at root: URL, name: String, kind: String) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("Config"), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("Ledger"), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("Scenarios"), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("MutableSurface"), withIntermediateDirectories: true)

        let config = LabConfig(
            name: name,
            kind: kind,
            budget: .init(maxDurationSeconds: 300, maxScenarios: 20, maxIterations: 1)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let configData = try encoder.encode(config)
        try configData.write(to: root.appendingPathComponent("Config/lab.json"))

        let program = defaultProgram(name: name, kind: kind)
        try program.write(to: root.appendingPathComponent("program.md"), atomically: true, encoding: .utf8)

        try (Ledger.tsvHeader() + "\n").write(to: root.appendingPathComponent("Ledger/results.tsv"), atomically: true, encoding: .utf8)
        try defaultScenarioManifest().write(to: root.appendingPathComponent("Scenarios/manifest.json"), atomically: true, encoding: .utf8)

        try scenarioREADME(for: kind).write(to: root.appendingPathComponent("Scenarios/README.md"), atomically: true, encoding: .utf8)
        try mutableSurfaceREADME(for: kind).write(to: root.appendingPathComponent("MutableSurface/README.md"), atomically: true, encoding: .utf8)
    }

    private static func defaultProgram(name: String, kind: String) -> String {
        """
        # \(name)

        Kind: \(kind)

        This lab follows the Karpathy-style autonomous experiment loop:

        1. mutate one bounded surface
        2. run the fixed evaluation budget
        3. compare the score
        4. keep wins
        5. revert losses
        6. record everything in the ledger

        ## Rules

        - Do not mutate outside `MutableSurface/` until the lab explicitly grows beyond v0.
        - Use Cupertino for exact Apple API documentation whenever framework behavior is unclear.
        - Prefer simpler winning changes over complex fragile wins.
        - Protect existing baselines. A new edge-case win does not justify a core regression.
        """
    }

    private static func scenarioREADME(for kind: String) -> String {
        """
        # Scenarios

        Put your fixed evaluation scenarios here.

        Suggested contents for `\(kind)`:

        - canonical strong cases
        - weak / failure cases
        - protected baselines
        - notes on expected outputs
        """
    }

    private static func mutableSurfaceREADME(for kind: String) -> String {
        """
        # Mutable Surface

        This folder is where autonomous mutation should begin for `\(kind)`.

        Examples:
        - prompt templates
        - strategy objects
        - threshold tables
        - routing policies
        - parser heuristics

        Keep the surface small. Elegance comes from bounded change.
        """
    }

    private static func defaultScenarioManifest() -> String {
        """
        {
          "version" : 1,
          "scenarios" : [
            {
              "expectedMetrics" : {
                "fidelity" : 1,
                "truthfulness" : 1
              },
              "id" : "protected-baseline",
              "notes" : "Replace these measurements with real harness outputs.",
              "tags" : [
                "protected"
              ],
              "variantMeasurements" : {
                "baseline" : {
                  "fidelity" : 0.9,
                  "truthfulness" : 1
                },
                "candidate" : {
                  "fidelity" : 0.92,
                  "truthfulness" : 1
                }
              }
            }
          ]
        }
        """
    }
}
