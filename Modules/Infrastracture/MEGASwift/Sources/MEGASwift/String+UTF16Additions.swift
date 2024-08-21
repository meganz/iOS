import Foundation

public extension String {
    /// Truncates the string to a specified maximum length based on its UTF-16 representation,
    /// ensuring that the truncated string is valid and exists within the original string.
    ///
    /// - Parameter maxLength: The maximum number of UTF-16 code units to which the string should be truncated.
    /// - Returns: A truncated version of the string if the truncation results in a valid substring,
    ///            or `nil` if a valid truncation cannot be achieved.
    ///
    /// - Note: This method is particularly useful when dealing with strings that may contain
    ///         characters represented by multiple UTF-16 code units, such as emojis or other
    ///         extended Unicode characters.
    func utf16ValidatedTruncation(to maxLength: Int) -> String? {
        guard maxLength > 0, !isEmpty else { return nil }

        let truncationLength = min(maxLength, utf16.count)
        var truncationIndex = utf16.index(startIndex, offsetBy: truncationLength)

        // Attempt truncation
        var truncatedText = String(decoding: utf16[..<truncationIndex], as: UTF16.self)

        // If the truncated text is not found in the original string, backtrack to find the first valid truncation
        while !contains(truncatedText) && startIndex < truncationIndex {
            truncationIndex = utf16.index(before: truncationIndex)
            truncatedText = String(decoding: utf16[..<truncationIndex], as: UTF16.self)
        }

        guard truncatedText.isNotEmpty else { return nil }
        return truncatedText
    }
}
