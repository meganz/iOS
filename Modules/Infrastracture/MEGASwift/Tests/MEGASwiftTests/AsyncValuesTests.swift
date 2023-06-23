@testable import MEGASwift
import XCTest

final class AsyncValuesTests: XCTestCase {
    func testWithAsyncThrowingValue_onExecuted_shouldSucceed() async throws {
        try await withAsyncThrowingValue { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(.success)
            }
        }
    }

    func testWithAsyncValue_onExecuted_shouldSucceed() async {
        await withAsyncValue { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                completion(.success)
            }
        }
    }
}
