import FileLink

final class MockFileLinkTrackingUseCase: FileLinkTrackingUseCaseProtocol, @unchecked Sendable {
    private(set) var trackScreenViewCalled = false
    private(set) var trackFileLinkOpenedCallCount = 0
    private(set) var trackedActions: [(option: FileLinkMoreOption, source: FileLinkActionSource)] = []

    func trackScreenView() {
        trackScreenViewCalled = true
    }

    func trackFileLinkOpened() {
        trackFileLinkOpenedCallCount += 1
    }

    func trackAction(_ option: FileLinkMoreOption, from source: FileLinkActionSource) {
        trackedActions.append((option, source))
    }
}
