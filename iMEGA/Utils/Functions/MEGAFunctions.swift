import Foundation

func MEGALogFatal(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGASdk.log(with: .fatal, message: "[iOS] \(message)", filename: file, line: line)
}

func MEGALogError(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGASdk.log(with: .error, message: "[iOS] \(message)", filename: file, line: line)
}

func MEGALogWarning(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGASdk.log(with: .warning, message: "[iOS] \(message)", filename: file, line: line)
}

func MEGALogInfo(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGASdk.log(with: .info, message: "[iOS] \(message)", filename: file, line: line)
}

func MEGALogDebug(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGASdk.log(with: .debug, message: "[iOS] \(message)", filename: file, line: line)
}

func MEGALogMax(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGASdk.log(with: .max, message: "[iOS] \(message)", filename: file, line: line)
}
