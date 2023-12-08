import Foundation

public struct ShellError: Error {
    public let code: Int32
    public let description: String
}

public enum ProcessResult {
    public static let success: Int32 = .zero
    public static let error: Int32 = 1
}

public func exitWithError(_ error: Error) -> Never {
    let prefix = "Script finished with error\n"
    
    if let shellError = error as? ShellError {
        print("\(prefix)Shell error: \(shellError.description)")
        exit(shellError.code)
    } else {
        print("\(prefix)Error: \(String(describing: error))\n description: \(error.localizedDescription)")
        exit(ProcessResult.error)
    }
}

@discardableResult
public func runInShell(_ args: String, cwd: URL? = nil, input: String? = nil) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c", args]
    if let cwd {
        process.currentDirectoryURL = cwd
    }
    
    if verbose {
        print("Executing shell command: \(args)")
    }
    
    let stdin = Pipe()
    let stdout = Pipe()
    let stderr = Pipe()
    
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = stderr
    
    try process.run()
    
    if let input = input {
        if verbose {
            print("Giving input to standard input: \(input)")
        }
        
        if let inputData = input.data(using: .utf8) {
            stdin.fileHandleForWriting.write(inputData)
            stdin.fileHandleForWriting.closeFile()
        }
    }
    
    process.waitUntilExit()
    
    guard process.terminationStatus == ProcessResult.success else {
        let stderrString = pipeString(stderr)
        throw ShellError(code: process.terminationStatus, description: stderrString)
    }
    
    let stdoutString = pipeString(stdout)
    
    if verbose {
        print("Standard output for \(args):\n\(stdoutString)")
    }
    
    return stdoutString
}

private func pipeString(_ pipe: Pipe) -> String {
    let pipeData = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: pipeData, encoding: .utf8) ?? ""
}
