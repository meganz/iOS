import Foundation

// I attempted to use `@preconcurrency import Foundation` and `@preconcurrency import class Foundation.FileManager` with no luck. Forced me to use @unchecked Sendable for FileManager.
extension FileManager: @unchecked @retroactive Sendable { }
