import Foundation
@testable import MEGAMarkdownEditor
import Testing

@Suite("Large text checks")
struct LargeTextTests {
    @Test func utf16CountLimitIsExclusive() {
        #expect(!"abc".hasUTF16Count(over: 3))
        #expect("abcd".hasUTF16Count(over: 3))
    }

    @Test func utf16CountUsesUTF16UnitsNotBytes() {
        // "é" is 2 UTF-8 bytes and 1 UTF-16 unit. "😀" is 4 bytes and 2 units.
        #expect(!"éé".hasUTF16Count(over: 2))
        #expect("é😀".hasUTF16Count(over: 2))
        #expect(!"😀".hasUTF16Count(over: 2))
    }

    @Test func utf16CountOfABridgedStringMatchesTheNativeAnswer() {
        let bridged = NSString(string: "é😀abc") as String
        // 1 + 2 + 3 = 6 UTF-16 units.
        #expect(bridged.hasUTF16Count(over: 5))
        #expect(!bridged.hasUTF16Count(over: 6))
    }

    @Test func emptyTextIsNeverOverALimit() {
        #expect(!"".hasUTF16Count(over: 0))
    }

    @Test func sameBytesIsTrueForEqualText() {
        #expect("abc".hasSameBytes(as: "abc"))
        #expect("".hasSameBytes(as: ""))
    }

    @Test func sameBytesIsFalseForDifferentText() {
        #expect(!"abc".hasSameBytes(as: "abd"))
        #expect(!"abc".hasSameBytes(as: "ab"))
    }

    @Test func sameBytesDistinguishesCanonicallyEqualText() {
        let composed = "\u{00E9}"
        let decomposed = "e\u{0301}"
        #expect(composed == decomposed)
        #expect(!composed.hasSameBytes(as: decomposed))
    }

    @Test func sameBytesWorksForABridgedString() {
        let bridged = NSString(string: "é😀") as String
        #expect(bridged.hasSameBytes(as: "é😀"))
        #expect(!bridged.hasSameBytes(as: "é"))
    }
}
