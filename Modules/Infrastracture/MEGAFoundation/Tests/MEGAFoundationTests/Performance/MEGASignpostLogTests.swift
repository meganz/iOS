@testable import MEGAFoundation
import XCTest

// These are simple tests, and it's hard to test the actual functionality of os_signpost
// because it doesn't return anything and its results are external to the app.
// So, we just call the methods to make sure they don't crash.

final class MEGASignpostLogTests: XCTestCase {
    var sut: MEGASignpostLog!
    
    override func setUp() {
        super.setUp()
        sut = MEGASignpostLog(subsystem: "com.mega.test", category: "Testing")
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testEvent() {
        sut.event(name: "TestEvent", key: "TestKey", value: "TestValue", concept: .debug)
    }
    
    func testBegin() {
        let id = sut.begin(name: "TestBegin", key: "TestKey", value: "TestValue", concept: .debug)
        XCTAssertNotNil(id, "Signpost ID should not be nil")
    }
    
    func testEnd() {
        let id = sut.begin(name: "TestBegin", key: "TestKey", value: "TestValue", concept: .debug)
        sut.end(name: "TestEnd", key: "TestKey", value: "TestValue", concept: .debug, id: id)
    }
    
    func testInterval() {
        let result: Int? = sut.interval(name: "TestInterval", key: "TestKey", value: "TestValue", concept: .debug) {
            return 42
        }
        
        XCTAssertEqual(result, 42, "The result of the interval method should be the return value of the completion block")
    }
    
    func testBeginWithoutArgument() {
        let name: StaticString = "Load Single Thumbnail"
        
        let id = sut.begin(name: name, format: "Name:%{public}@,Begin:%{public}@", arguments: [])
        
        sut.end(name: name, id: id, format: "Name:%{public}@,End:%{public}@,Concept:%{public}@", arguments: [])
    }
    
    func testBeginWithOneArgument() {
        let name: StaticString = "Load Single Thumbnail"
        
        let id = sut.begin(name: name, format: "Name:%{public}@", arguments: ["1"])
        
        sut.end(name: name, id: id, format: "Name:%{public}@", arguments: ["1"])
    }
    
    func testBeginWithMultipleArguments() {
        let name: StaticString = "Load Single Thumbnail"
        
        let id = sut.begin(name: name,
                           format: "Name:%{public}@,Begin:%{public}@",
                           arguments: ["1", "Begin"])
        
        sut.end(name: name, id: id, format: "Name:%{public}@,End:%{public}@,Concept:%{public}@", arguments: ["1", "Completed", "Green"])
    }
}
