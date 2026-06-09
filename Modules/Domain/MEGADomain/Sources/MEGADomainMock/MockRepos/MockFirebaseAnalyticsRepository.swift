import MEGADomain

public final class MockFirebaseAnalyticsRepository: FirebaseAnalyticsRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockFirebaseAnalyticsRepository {
        MockFirebaseAnalyticsRepository()
    }

    public private(set) var setAnalyticsEnabledValues: [Bool] = []

    private let onSetAnalyticsEnabled: (@Sendable (Bool) -> Void)?

    public init(onSetAnalyticsEnabled: (@Sendable (Bool) -> Void)? = nil) {
        self.onSetAnalyticsEnabled = onSetAnalyticsEnabled
    }

    public func setAnalyticsEnabled(_ enabled: Bool) {
        setAnalyticsEnabledValues.append(enabled)
        onSetAnalyticsEnabled?(enabled)
    }
}
