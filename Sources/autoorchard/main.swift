import Foundation
import AutoOrchardCore

@main
struct AutoOrchardCLI {
    static func main() throws {
        var args = CommandLine.arguments.dropFirst()
        guard let command = args.first else {
            printHelp()
            return
        }
        args = args.dropFirst()

        switch command {
        case "doctor":
            let report = Doctor.run()
            for check in report.checks {
                let symbol = check.ok ? "✅" : "⚠️"
                print("\(symbol) \(check.name): \(check.detail)")
            }
        case "init-lab":
            try runInitLab(args: args)
        case "run-baseline":
            try runExperimentCommand(args: args, variant: .baseline)
        case "run-candidate":
            try runExperimentCommand(args: args, variant: .candidate)
        case "help", "--help", "-h":
            printHelp()
        default:
            fputs("Unknown command: \(command)\n\n", stderr)
            printHelp()
            Foundation.exit(1)
        }
    }

    private static func runInitLab(args: ArraySlice<String>) throws {
        guard args.count >= 2 else {
            fputs("Usage: autoorchard init-lab <path> <kind> [name]\n", stderr)
            Foundation.exit(1)
        }

        let path = String(args[args.startIndex])
        let kind = String(args[args.index(args.startIndex, offsetBy: 1)])
        let name: String
        if args.count >= 3 {
            name = String(args[args.index(args.startIndex, offsetBy: 2)])
        } else {
            name = URL(fileURLWithPath: path).lastPathComponent
        }

        try LabScaffolder.createLab(at: URL(fileURLWithPath: path), name: name, kind: kind)
        print("Created lab at \(path)")
    }

    private static func runExperimentCommand(args: ArraySlice<String>, variant: ExperimentVariant) throws {
        guard let pathArgument = args.first else {
            fputs("Usage: autoorchard run-\(variant.rawValue) <lab-path>\n", stderr)
            Foundation.exit(1)
        }

        let path = URL(fileURLWithPath: String(pathArgument))
        let runner = ExperimentRunner(paths: .init(labRoot: path))
        let result = try runner.run(variant: variant)
        let workspace = GitWorkspace().status(for: path)
        let followUp = SafeKeepRevertHooks().action(for: result, workspace: workspace)

        print("decision: \(result.decision.rawValue)")
        print("variant: \(result.variant.rawValue)")
        print("scenarios: \(result.scenarioCount)")
        print("total: \(formatted(result.score.total))")

        for key in result.score.dimensions.keys.sorted() {
            if let value = result.score.dimensions[key] {
                print("dimension.\(key): \(formatted(value))")
            }
        }

        if let bestKnownScore = result.bestKnownScore {
            print("best-known: \(formatted(bestKnownScore))")
        }

        if let scoreDelta = result.scoreDelta {
            print("delta: \(formatted(scoreDelta))")
        }

        if !result.notes.isEmpty {
            print("notes: \(result.notes.joined(separator: " | "))")
        }

        if workspace.isGitRepository {
            if let gitRoot = workspace.gitRoot?.path {
                print("git-root: \(gitRoot)")
            }
            print("git-dirty: \(workspace.hasUncommittedChanges ? "true" : "false")")
        } else {
            print("git-root: <not a git repository>")
        }

        if case .requireManualReview(let reason) = followUp {
            print("follow-up: \(reason)")
        }
    }

    private static func formatted(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private static func printHelp() {
        print(
            """
            autoorchard

            Commands:
              doctor                              Check Apple tooling and Cupertino availability
              init-lab <path> <kind> [name]      Scaffold a new autonomous lab
              run-baseline <lab-path>            Run the baseline evaluator path and append the ledger
              run-candidate <lab-path>           Run the candidate evaluator path and compare against best known score
              help                                Show this help
            """
        )
    }
}

