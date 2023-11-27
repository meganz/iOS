import Foundation

private(set) var verbose = false

public func setVerbose() {
    verbose = CommandLine.arguments.contains("--verbose")
}
