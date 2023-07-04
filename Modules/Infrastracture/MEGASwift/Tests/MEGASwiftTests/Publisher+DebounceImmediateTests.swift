import Combine
@testable import MEGASwift
import XCTest

final class PublisherDebounceImmediateTests: XCTestCase {
    
    func testDebounceImmediate_emitsFirstValueOnlyBeforeTimerEnds() {
        
        // Arrange
        let expectation = XCTestExpectation(description: "Emits test elements to completiom")
        let events = [0, 1, 2, 3, 4, 5, 7]
            .map { value in Just(value).delay(for: .milliseconds(value * 200), scheduler: DispatchQueue.main) }
        
        // Act
        var results: [Int] = []
        
        let subscription = Publishers
            .MergeMany(events)
            .timeout(.seconds(0.05), scheduler: DispatchQueue.main)
            .debounceImmediate(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { results.append($0) })
        
        wait(for: [expectation], timeout: 1)
        subscription.cancel()

        // Assert
        let expected = [0]
        XCTAssertEqual(expected, results)
    }
    
    func testDebounceImmediate_emitsFirstValueThenDebouncesAnotherValueBeforeTimer() {
        
        // Arrange
        let expectation = XCTestExpectation(description: "Emits test elements to completiom")
        let events = [0, 1, 4, 5, 6]
            .map { value in Just(value).delay(for: .milliseconds(value * 200), scheduler: DispatchQueue.main) }
        
        // Act
        var results: [Int] = []
        
        let subscription = Publishers
            .MergeMany(events)
            .timeout(.seconds(0.2), scheduler: DispatchQueue.main)
            .debounceImmediate(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { results.append($0) })
        
        wait(for: [expectation], timeout: 1)
        
        subscription.cancel()
        // Assert
        let expected = [0, 1]
        XCTAssertEqual(expected, results)
    }
    
    func testDebounceImmediate_emitsFirstValueThenDebouncesOverMultipleValues() {
        
        // Arrange
        let expectation = XCTestExpectation(description: "Emits test elements to completiom")
        let events = [0, 1, 2, 3, 10]
            .map { value in Just(value).delay(for: .milliseconds(value * 200), scheduler: DispatchQueue.main) }
        
        // Act
        var results: [Int] = []
        
        let subscription = Publishers
            .MergeMany(events)
            .timeout(.seconds(0.3), scheduler: DispatchQueue.main)
            .debounceImmediate(for: .milliseconds(220), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { results.append($0) })
        
        wait(for: [expectation], timeout: 1.5)
        
        subscription.cancel()
        
        // Assert
        let expected = [0, 3]
        XCTAssertEqual(expected, results)
    }
}
