import MEGADomain

public final class MockFirebaseAnalyticsConsentUseCase: FirebaseAnalyticsConsentUseCaseProtocol, @unchecked Sendable {
    public private(set) var disableCollectionCallCount = 0
    public private(set) var updateCollectionConsents: [Bool] = []

    private let isCollectionEnabled: Bool

    public init(isCollectionEnabled: Bool = false) {
        self.isCollectionEnabled = isCollectionEnabled
    }

    public func disableCollection() {
        disableCollectionCallCount += 1
    }

    @discardableResult
    public func updateCollection(performanceAndAnalyticsConsent consent: Bool) async -> Bool {
        updateCollectionConsents.append(consent)
        return isCollectionEnabled
    }
}
