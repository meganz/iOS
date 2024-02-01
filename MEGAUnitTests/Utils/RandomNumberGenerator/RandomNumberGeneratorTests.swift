@testable import MEGA
import XCTest

final class RandomNumberGeneratorTests: XCTestCase {
    func testNumberWithinBounds() {
            let sut = RandomNumberGenerator()
            let lowerBound = 10
            let upperBound = 20

            for _ in 1...1000 {
                let number = sut.generate(lowerBound: lowerBound, upperBound: upperBound)
                XCTAssertTrue(number >= lowerBound, "Number is less than lower bound")
                XCTAssertTrue(number <= upperBound, "Number is greater than upper bound")
            }
        }

        func testBoundsAreInclusive() {
            let sut = RandomNumberGenerator()
            let lowerBound = 0
            let upperBound = 0

            // When the bounds are the same, the only valid output is the bound value itself
            let number = sut.generate(lowerBound: lowerBound, upperBound: upperBound)
            XCTAssertEqual(number, lowerBound, "Number should be equal to the bound value")
        }
}
