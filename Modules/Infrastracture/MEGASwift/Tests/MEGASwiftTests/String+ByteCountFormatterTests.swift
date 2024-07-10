import XCTest

class StringByteCountFormatterTests: XCTestCase {
    func testMemoryStyleString_withUnit_FormattedString() {
        let formattedString = String.memoryStyleString(fromByteCount: 1024)
        XCTAssertEqual(formattedString, "1 KB", "Formatted string should be '1 KB'")
    }
    
    func testMemoryStyleString_withoutUnit_FormattedString() {
        let formattedString = String.memoryStyleString(fromByteCount: 1024, includesUnit: false)
        XCTAssertEqual(formattedString, "1", "Formatted string should be '1' when includesUnit is false")
    }
    
    func testFormattedByteCountString_validByteCountString_FormattedString() {
        let byteCountString = "1 KB"
        let formattedString = byteCountString.formattedByteCountString()
        XCTAssertEqual(formattedString, "1 KB", "Formatted string should be '1 KB'")
    }
    
    func testFormattedByteCountString_zeroByteCountString_FormattedString() {
        let byteCountString = "Zero bytes"
        let formattedString = byteCountString.formattedByteCountString()
        XCTAssertEqual(formattedString, "0 B", "Formatted string should be '0 B'")
    }
    
    func testFormattedByteCountString_emptyString_FormattedString() {
        let byteCountString = ""
        let formattedString = byteCountString.formattedByteCountString()
        XCTAssertEqual(formattedString, "0", "Formatted string should be '0'")
        
        let byteCountString2 = "Zero"
        let formattedString2 = byteCountString2.formattedByteCountString()
        XCTAssertEqual(formattedString2, "0", "Formatted string should be '0'")
    }
    
    func testMemoryStyleString_andFormattedByteCountString_withUnit_shouldReturnFormattedString() {
        let byteCount: Int64 = 1024
        let expectedFormattedString = "1 KB"
        
        let memoryStyleString = String.memoryStyleString(fromByteCount: byteCount)
        let formattedString = memoryStyleString.formattedByteCountString()
        
        XCTAssertEqual(formattedString, expectedFormattedString, "Formatted string should be '\(expectedFormattedString)'")
    }
    
    func testMemoryStyleString_andFormattedByteCountString_withoutUnit_shouldReturnFormattedString() {
        let byteCount: Int64 = 1024
        let expectedFormattedString = "1"
        
        let memoryStyleString = String.memoryStyleString(fromByteCount: byteCount, includesUnit: false)
        let formattedString = memoryStyleString.formattedByteCountString()
        
        XCTAssertEqual(formattedString, expectedFormattedString, "Formatted string should be '\(expectedFormattedString)'")
    }
    
    func testMemoryStyleString_andFormattedByteCountString_zeroByteCount_shouldReturnFormattedString() {
        let byteCount: Int64 = 0
        let expectedFormattedString = "Zero bytes".formattedByteCountString() // "0 B"
        
        let memoryStyleString = String.memoryStyleString(fromByteCount: byteCount)
        let formattedString = memoryStyleString.formattedByteCountString()
        
        XCTAssertEqual(formattedString, expectedFormattedString, "Formatted string should be '\(expectedFormattedString)'")
    }
    
    func testMemoryStyleString_andFormattedByteCountString_largeByteCount_shouldReturnFormattedString() {
        let byteCount: Int64 = 1073741824 // 1 GB
        let expectedFormattedString = "1 GB"
        
        let memoryStyleString = String.memoryStyleString(fromByteCount: byteCount)
        let formattedString = memoryStyleString.formattedByteCountString()
        
        XCTAssertEqual(formattedString, expectedFormattedString, "Formatted string should be '\(expectedFormattedString)'")
    }
    
    func testMemoryStyleString_andFormattedByteCountString_withoutSpace_shouldReturnFormattedString() {
        let byteCount: Int64 = 1024
        let expectedFormattedString = "1 KB"
        
        let memoryStyleString = String.memoryStyleString(fromByteCount: byteCount)
        let formattedString = memoryStyleString.formattedByteCountString()
        
        XCTAssertEqual(formattedString, expectedFormattedString, "Formatted string should be '\(expectedFormattedString)'")
    }
}
