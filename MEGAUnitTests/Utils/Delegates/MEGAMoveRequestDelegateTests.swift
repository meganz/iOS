@testable import MEGA
import MEGAAppSDKRepoMock
import MEGASdk
import Testing

@MainActor
struct MEGAMoveRequestDelegateTests {
    @Test
    func moveSucceeded_callsCompletion() {
        let counter = CompletionCounter()
        let sut = makeSUT(counter: counter)

        sut.onRequestFinish(MockSdk(), request: MEGARequest(), error: MockError(errorType: .apiOk))

        #expect(counter.count == 1)
    }

    @Test
    func moveFailedWithOverQuota_doesNotCallCompletion() {
        let counter = CompletionCounter()
        let sut = makeSUT(counter: counter)

        sut.onRequestFinish(MockSdk(), request: MEGARequest(), error: MockError(errorType: .apiEOverQuota))

        #expect(counter.count == 0)
    }

    @Test
    func moveFailedWithBusinessPastDue_doesNotCallCompletion() {
        let counter = CompletionCounter()
        let sut = makeSUT(counter: counter)

        sut.onRequestFinish(MockSdk(), request: MEGARequest(), error: MockError(errorType: .apiEBusinessPastDue))

        #expect(counter.count == 0)
    }

    // MARK: - Helpers

    private func makeSUT(counter: CompletionCounter) -> MEGAMoveRequestDelegate {
        MEGAMoveRequestDelegate(toMoveToTheRubbishBinWithFiles: 1, folders: 0) {
            counter.count += 1
        }
    }
}

private final class CompletionCounter {
    var count = 0
}
