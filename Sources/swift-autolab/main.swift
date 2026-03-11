import Foundation
import AutolabCore

@main
struct SwiftAutolabCLI {
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
            guard args.count >= 2 else {
                fputs("Usage: swift-autolab init-lab <path> <kind> [name]\n", stderr)
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
        case "help", "--help", "-h":
            printHelp()
        default:
            fputs("Unknown command: \(command)\n\n", stderr)
            printHelp()
            Foundation.exit(1)
        }
    }

    private static func printHelp() {
        print(
            """
            swift-autolab

            Commands:
              doctor                         Check Apple tooling and Cupertino availability
              init-lab <path> <kind> [name] Scaffold a new autonomous lab
              help                           Show this help
            """
        )
    }
}
