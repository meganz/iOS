import MEGASdk

func MEGALogFatal(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(with: .fatal, message, file: file, line: line)
}

func MEGALogError(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(with: .error, message, file: file, line: line)
}

func MEGALogWarning(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(with: .warning, message, file: file, line: line)
}

func MEGALogInfo(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(with: .info, message, file: file, line: line)
}

func MEGALogDebug(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(with: .debug, message, file: file, line: line)
}

func MEGALogMax(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(with: .max, message, file: file, line: line)
}

private func log(with logLevel: MEGALogLevel, _ message: String, file: String = #file, line: Int = #line) {
    MEGASdk.log(with: logLevel, message: "[iOS] \(message)", filename: file, line: line)
}
