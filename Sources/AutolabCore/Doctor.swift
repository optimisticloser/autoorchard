import Foundation

public struct DoctorReport: Sendable {
    public struct Check: Sendable {
        public var name: String
        public var ok: Bool
        public var detail: String

        public init(name: String, ok: Bool, detail: String) {
            self.name = name
            self.ok = ok
            self.detail = detail
        }
    }

    public var checks: [Check]

    public init(checks: [Check]) {
        self.checks = checks
    }
}

public enum Doctor {
    public static func run() -> DoctorReport {
        DoctorReport(checks: [
            binaryCheck("swift", detail: "Swift toolchain available"),
            binaryCheck("xcodebuild", detail: "Xcode build tools available"),
            binaryCheck("cupertino", detail: "Cupertino exact Apple docs provider available (optional)"),
            binaryCheck("xcrun", detail: "Apple device/simulator tooling available")
        ])
    }

    private static func binaryCheck(_ name: String, detail: String) -> DoctorReport.Check {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [name]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return .init(name: name, ok: task.terminationStatus == 0, detail: path.isEmpty ? detail : "\(detail) @ \(path)")
        } catch {
            return .init(name: name, ok: false, detail: "\(detail) (error: \(error.localizedDescription))")
        }
    }
}
