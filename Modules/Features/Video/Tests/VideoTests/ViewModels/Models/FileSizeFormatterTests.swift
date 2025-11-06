@testable import Video
import XCTest

final class FileSizeFormatterTests: XCTestCase {
    
    func testMemoryStyleString_Bytes_deliversCorrectFormat() {
        let memoryStyleString = FileSizeFormatter.memoryStyleString(fromByteCount: 500)
        
        XCTAssertEqual(memoryStyleString, "500 bytes")
    }
    
    func testMemoryStyleString_Kilobytes_deliversCorrectFormat() {
        let memoryStyleString = FileSizeFormatter.memoryStyleString(fromByteCount: 2048) // 2 KB
        
        XCTAssertEqual(memoryStyleString, "2 KB")
    }
    
    func testMemoryStyleString_Megabytes_deliversCorrectFormat() {
        let memoryStyleString = FileSizeFormatter.memoryStyleString(fromByteCount: 2097152) // 2 MB
        
        XCTAssertEqual(memoryStyleString, "2 MB")
    }
    
    func testMemoryStyleString_Gigabytes_deliversCorrectFormat() {
        let memoryStyleString = FileSizeFormatter.memoryStyleString(fromByteCount: 2147483648) // 2 GB
        
        XCTAssertEqual(memoryStyleString, "2 GB")
    }
    
//    func testMemoryStyleString_BytesBoundary_deliversCorrectFormat() {
//        let memoryStyleString = FileSizeFormatter.memoryStyleString(fromByteCount: 1023) // Just below 1 KB
//        
//        XCTAssertEqual(memoryStyleString, "1,023 bytes")
//    }

    func testMemoryStyleString_KilobytesBoundary_deliversCorrectFormat() {
        let memoryStyleString = FileSizeFormatter.memoryStyleString(fromByteCount: 1024) // Exactly 1 KB
        
        XCTAssertEqual(memoryStyleString, "1 KB")
    }
}
