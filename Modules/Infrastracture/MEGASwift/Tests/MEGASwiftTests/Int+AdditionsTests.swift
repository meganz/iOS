import XCTest

final class IntAdditionsTests: XCTestCase {
    
    func testStringConversion() {
        let intValue = 3600 // 1 hour
        
        let result = intValue.string(allowedUnits: [.hour, .minute, .second])
        
        XCTAssertEqual(result, "1 hour")
    }
    
    func testRandomNumberGeneration_shouldReturnNotNil() {
        let randomNumber = Int.random()
        
        XCTAssertNotNil(randomNumber)
    }
    
    func testCardinalConversion() {
        let intValue = 1234567890
        
        let result = intValue.cardinal
        
        XCTAssertEqual(result, "1234567890")
    }
    
    func testTimeIntervalConversion() {
        let intValue = 2
        
        let seconds = intValue.seconds
        let minutes = intValue.minutes
        let hours = intValue.hours
        let days = intValue.days
        
        XCTAssertEqual(seconds, 2.0)
        XCTAssertEqual(minutes, 120.0)
        XCTAssertEqual(hours, 7200.0)
        XCTAssertEqual(days, 172800.0)
    }
}
