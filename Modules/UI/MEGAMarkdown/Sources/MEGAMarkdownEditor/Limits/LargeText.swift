import Foundation

// Checks that stay cheap on a 10-100 MB text. The editor runs them on the main thread.
extension String {
    /// True when the UTF-16 length is over `limit`. O(1) for large texts: a bridged NSString knows its UTF-16 length,
    /// and a native string its UTF-8 length (the UTF-16 length is a third of it up to all of it).
    func hasUTF16Count(over limit: Int) -> Bool {
        let isNative = utf8.withContiguousStorageIfAvailable { _ in true } ?? false
        guard isNative else { return utf16.count > limit }
        let bytes = utf8.count
        if bytes <= limit { return false }
        if bytes > limit * 3 { return true }
        return utf16.count > limit
    }

    /// Byte equality. `==` compares Unicode canonical forms: about 3 ms per MB of equal non-ASCII text.
    func hasSameBytes(as other: String) -> Bool {
        guard utf8.count == other.utf8.count else { return false }
        let fast = utf8.withContiguousStorageIfAvailable { lhs in
            other.utf8.withContiguousStorageIfAvailable { rhs in
                guard let left = lhs.baseAddress, let right = rhs.baseAddress, left != right else { return true }
                return memcmp(left, right, lhs.count) == 0
            }
        }
        return fast.flatMap { $0 } ?? utf8.elementsEqual(other.utf8)
    }
}
