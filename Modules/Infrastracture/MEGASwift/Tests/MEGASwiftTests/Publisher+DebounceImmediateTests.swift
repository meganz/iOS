import Combine
@testable import MEGASwift
import XCTest

final class PublisherDebounceImmediateTests: XCTestCase {
    
    func testDebounceImmediate_emitsFirstValueOnlyBeforeTimerEnds() async {
        
        // Arrange
        let events = [0, 1, 2, 3, 4, 5]
            .map { value in Just(value).delay(for: .milliseconds(value * 90), scheduler: DispatchQueue.main) }
        
        // Act
        let results = await Publishers
            .MergeMany(events)
            .debounceImmediate(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .collect()
            .values
            .first { _ in true }
        
        // Assert
        let expected = [0]
        XCTAssertEqual(expected, results)
    }
    
    func testDebounceImmediate_emitsFirstValueThenDebouncesAnotherValueBeforeTimer() async {
        
        // Arrange
        let events = [0, 0.1, 0.3, 0.4, 0.6]
            .map { value in Just(value).delay(for: .init(floatLiteral: value), scheduler: DispatchQueue.main) }
        
        // Act
        let results = await Publishers
            .MergeMany(events)
            .debounceImmediate(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .collect()
            .values
            .first { _ in true }

        // Assert
        let expected: [Double] = [0, 0.1, 0.4]
        XCTAssertEqual(expected, results)
    }
    
    func testDebounceImmediate_emitsFirstValueThenDebouncesOverMultipleValues() async {
        
        // Arrange
        let events = [0, 1, 2, 3, 10]
            .map { value in Just(value).delay(for: .milliseconds(value * 200), scheduler: DispatchQueue.main) }
        
        // Act
        let results = await Publishers
            .MergeMany(events)
            .debounceImmediate(for: .milliseconds(220), scheduler: DispatchQueue.main)
            .collect()
            .values
            .first { _ in true }
        
        // Assert
        let expected = [0, 3]
        XCTAssertEqual(expected, results)
    }
}
