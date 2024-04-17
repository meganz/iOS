@testable import MEGASwift
import XCTest

final class ArrayTasksTests: XCTestCase {
    
    func testAppendTask() async {
        var tasks: [Task<Void, Error>] = []
        
        tasks.appendTask {
            // Perform some async action
        }
        
        XCTAssertEqual(tasks.count, 1)
    }
    
    func testCancelTasks() {
        var tasks: [Task<Void, Error>] = []
        
        tasks.append(Task { /* Some async action */ })
        tasks.append(Task { /* Some async action */ })
        tasks.append(Task { /* Some async action */ })
        
        tasks.cancelTasks()
        
        XCTAssertEqual(tasks.count, 0)
    }
}
