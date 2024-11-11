@testable import MEGASwift
import XCTest

final class AtomicPropertyWrapperTests: XCTestCase {
    
    func testAtomicAccess_concurrentWrite_shouldSucceed() async throws {
        @Atomic var counter: Int = 0
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<1000 {
                group.addTask { @Sendable in
                    $counter.mutate { $0 += 1 }
                }
            }
            
            try await group.waitForAll()
            
            XCTAssertEqual(counter, 1000)
        }
    }
}
