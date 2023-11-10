import Foundation

struct ShellError: Error {
    let code: Int32
    let description: String
}

enum ProcessResult {
    static let success: Int32 = .zero
    static let error: Int32 = 1
}

func runInShell(_ args: String, cwd: URL? = nil) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c", args]
    if let cwd {
        process.currentDirectoryURL = cwd
    }

    let stdout = Pipe()
    let stderr = Pipe()

    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != ProcessResult.success {
        try handleShellError(stderr: stderr, code: process.terminationStatus)
    }
}

private func handleShellError(stderr: Pipe, code: Int32) throws {
    let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
    let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
    throw ShellError(code: code, description: stderrString)
}
