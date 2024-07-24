import Foundation
import XCTest

public extension XCTestCase {
    
    /// Will track the task to the end of the testing function. Once the test is about to tearDown, this will cancel the action. And await for the expectation that the action did successfully cancel
    /// - Parameters:
    ///   - nanoseconds: timeout duration in nanoseconds
    ///   - action: Task to run
    func trackTaskCancellation(timeout nanoseconds: UInt64 = 1_000_000_000, 
                               description: String = "Expected task to cancel during test case tearDown",
                               action: @escaping () async throws -> Void,
                               file: StaticString = #filePath, 
                               line: UInt = #line) {
        
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))
        
        let task = Task {
            try await action()
            continuation.yield(true)
            continuation.finish()
        }
        
        addTeardownBlock {
            task.cancel()

            // Timeout task
            Task {
                try await Task.sleep(nanoseconds: nanoseconds)
                continuation.finish()
            }
                        
            let isCancelled = await stream.first(where: { $0 }) ?? false
            XCTAssertTrue(isCancelled, description, file: file, line: line)
        }
    }
}
