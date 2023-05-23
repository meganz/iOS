import XCTest
@testable import MEGASwift

final class AsyncValuesTests: XCTestCase {
    func testWithAsyncThrowingValue_onExecuted_shouldSucceed() async throws {
        try await withAsyncThrowingValue { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(.success)
            }
        }
    }

    func testWithAsyncThrowingValue_onCancelleed_shouldFail() async {
        do {
            let task = Task {
                try await withAsyncThrowingValue { completion in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                        completion(.success)
                    }
                }
            }
            task.cancel()
            try await task.value
            XCTFail()
        } catch let error as CancellationError {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
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
