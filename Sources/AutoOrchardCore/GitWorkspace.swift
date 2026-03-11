import Foundation

public struct GitWorkspaceStatus: Sendable, Equatable {
    public var isGitRepository: Bool
    public var hasUncommittedChanges: Bool
    public var gitRoot: URL?

    public init(isGitRepository: Bool, hasUncommittedChanges: Bool, gitRoot: URL? = nil) {
        self.isGitRepository = isGitRepository
        self.hasUncommittedChanges = hasUncommittedChanges
        self.gitRoot = gitRoot
    }
}

public enum KeepRevertAction: Sendable, Equatable {
    case none
    case requireManualReview(reason: String)
}

public struct GitWorkspace: Sendable {
    public init() {}

    public func status(for directory: URL) -> GitWorkspaceStatus {
        let rootResult = runGit(arguments: ["rev-parse", "--show-toplevel"], directory: directory)
        guard rootResult.exitCode == 0 else {
            return GitWorkspaceStatus(isGitRepository: false, hasUncommittedChanges: false, gitRoot: nil)
        }

        let rootPath = rootResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let gitRoot = rootPath.isEmpty ? nil : URL(fileURLWithPath: rootPath)

        let statusResult = runGit(arguments: ["status", "--porcelain"], directory: directory)
        let hasUncommittedChanges = !statusResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return GitWorkspaceStatus(
            isGitRepository: true,
            hasUncommittedChanges: hasUncommittedChanges,
            gitRoot: gitRoot
        )
    }

    @discardableResult
    private func runGit(arguments: [String], directory: URL) -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments
        process.currentDirectoryURL = directory

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
            let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return ProcessResult(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr)
        } catch {
            return ProcessResult(exitCode: 1, stdout: "", stderr: error.localizedDescription)
        }
    }
}

public struct SafeKeepRevertHooks: Sendable {
    public init() {}

    public func action(for result: ExperimentResult, workspace: GitWorkspaceStatus) -> KeepRevertAction {
        guard workspace.isGitRepository else {
            return .requireManualReview(reason: "git repository not detected")
        }

        guard !workspace.hasUncommittedChanges else {
            return .requireManualReview(reason: "working tree is dirty")
        }

        switch result.decision {
        case .keep:
            return .requireManualReview(reason: "candidate won; commit or tag this state after manual review")
        case .revert:
            return .requireManualReview(reason: "candidate lost; restore the previous known-good state before continuing")
        default:
            return .none
        }
    }
}

private struct ProcessResult {
    var exitCode: Int32
    var stdout: String
    var stderr: String
}
