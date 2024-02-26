import MEGASwift
import XCTest

final class MulticastAsyncSequenceTests: XCTestCase {
    
    func testYield_shouldYieldExpectedValueToSingleContinuation() async {
        let sut = MulticastAsyncSequence<Int>()
        let expectedResult = 43
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        let updatedExp = expectation(description: "update was emitted")

        _ = Task {
            expectedTasksStarted.fulfill()
            for await result in await sut.make() {
                XCTAssertEqual(result, expectedResult)
                updatedExp.fulfill()
                return
            }
        }
        
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        
        await sut.yield(element: expectedResult)
        
        await fulfillment(of: [updatedExp], timeout: 1)
    }
    
    func testYield_whenThereAreMultipleContinuations_shouldYieldExpectedValueToAllContinuation() async {
        let sut = MulticastAsyncSequence<Int>()
        let expectedResult = 45
        let numberOfSequences = 20
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false

        let updatedExp = expectation(description: "update was emitted")
        updatedExp.expectedFulfillmentCount = numberOfSequences
        updatedExp.assertForOverFulfill = false

        _ = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await result in await sut.make() {
                        XCTAssertEqual(result, expectedResult)
                        updatedExp.fulfill()
                        return
                    }
                }
            }
        
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        
        await sut.yield(element: expectedResult)
        
        await fulfillment(of: [updatedExp], timeout: 1)
    }
    
    func testYield_whenThereAreMultipleContinuationsAndMultipleYield_shouldYieldExpectedValuesToAllContinuation() async {
        let sut = MulticastAsyncSequence<Int>()
        let expectedResults = [45, 60]
        let numberOfSequences = 20
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false

        let updatedExp = expectation(description: "update was emitted")
        updatedExp.expectedFulfillmentCount = numberOfSequences
        updatedExp.assertForOverFulfill = false

        _ = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    let results = await sut.make()
                        .prefix(expectedResults.count)
                        .reduce(into: [Int]()) { $0.append($1) }
                    
                    XCTAssertEqual(results, expectedResults)
                    
                    updatedExp.fulfill()
                }
            }
        
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        
        await sut.yield(element: expectedResults[0])
        await sut.yield(element: expectedResults[1])
        
        await fulfillment(of: [updatedExp], timeout: 1)
    }
    
    func testTerminateContinuations_whenThereAreMultipleContinuations_shouldTerminateAllContinuation() async {
        let sut = MulticastAsyncSequence<Int>()
        let numberOfSequences = 20
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false

        let  sequenceCancelledExp = expectation(description: "sequence should cancel and exit loop")
        sequenceCancelledExp.expectedFulfillmentCount = numberOfSequences
        sequenceCancelledExp.assertForOverFulfill = false
        
        _ = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await _ in await sut.make() { }
                    sequenceCancelledExp.fulfill()
                }
            }
        
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        
        await sut.terminateContinuations()
        
        await fulfillment(of: [sequenceCancelledExp], timeout: 1)
    }
}
