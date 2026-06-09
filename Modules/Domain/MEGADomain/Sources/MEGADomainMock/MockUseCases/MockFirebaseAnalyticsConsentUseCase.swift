import MEGADomain

public final class MockFirebaseAnalyticsConsentUseCase: FirebaseAnalyticsConsentUseCaseProtocol, @unchecked Sendable {
    public private(set) var disableCollectionCallCount = 0
    public private(set) var updateCollectionConsents: [Bool] = []

    public init() {}

    public func disableCollection() {
        disableCollectionCallCount += 1
    }

    public func updateCollection(performanceAndAnalyticsConsent consent: Bool) async {
        updateCollectionConsents.append(consent)
    }
}
