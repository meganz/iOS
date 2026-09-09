import Foundation

public extension URL {
    var isDirectory: Bool {
        do {
            let values = try resourceValues(forKeys: [.isDirectoryKey])
            return if let isDirectory = values.isDirectory {
                isDirectory
            } else {
                false
            }
        } catch {
            return false
        }
    }
}
