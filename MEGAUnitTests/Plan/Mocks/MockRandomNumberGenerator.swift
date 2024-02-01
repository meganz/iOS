@testable import MEGA
final class MockRandomNumberGenerator: RandomNumberGenerating {
    let generateRecorder = FuncCallRecorder<(Int, Int), Int>()
    func generate(lowerBound: Int, upperBound: Int) -> Int {
        generateRecorder.call((lowerBound, upperBound))
    }
}
