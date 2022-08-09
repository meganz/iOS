import Foundation

extension Scanner {

    /// Scans the string until a given string is encountered, accumulating characters into a string and return. This method mean to be compatible with earlier
    /// iOS platforms.
    /// - Parameter string: The string to scan up to.
    /// - Returns: A string contains any characters that were scanned.
    func scanTo(_ string: String) -> String? {
        return scanUpToString(string)
    }
}
