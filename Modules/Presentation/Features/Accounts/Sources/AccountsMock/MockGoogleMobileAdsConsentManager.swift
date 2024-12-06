import Accounts
import UserMessagingPlatform

public enum AdMobError: Error {
    case genericError
}

public final class MockGoogleMobileAdsConsentManager: GoogleMobileAdsConsentManagerProtocol, @unchecked Sendable {
    public private(set) var gatherConsentCalledCount = 0
    public private(set) var initializeGoogleMobileAdsSDKCalledCount = 0
    
    public init() { }
    
    public func gatherConsent() async throws {
        gatherConsentCalledCount += 1
    }
    
    public func initializeGoogleMobileAdsSDK() async {
        initializeGoogleMobileAdsSDKCalledCount += 1
    }
}

public final class MockAdMobConsentInformation: AdMobConsentInformationProtocol, @unchecked Sendable {
    public private(set) var canRequestAds: Bool
    public private(set) var didRequestConsentInfoUpdate = false
    private let shouldThrowError: Bool

    public init(
        canRequestAds: Bool = true,
        shouldThrowError: Bool = false
    ) {
        self.canRequestAds = canRequestAds
        self.shouldThrowError = shouldThrowError
    }
    
    public func requestConsentInfoUpdate(with parameters: UMPRequestParameters?) async throws {
        didRequestConsentInfoUpdate = true
        
        // Simulate async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        if shouldThrowError {
            throw AdMobError.genericError
        }
    }
}

public final class MockAdMobConsentForm: AdMobConsentFormProtocol, @unchecked Sendable {
    nonisolated(unsafe) public static private(set) var didLoadAndPresent = false
    
    public static func loadAndPresentIfRequired(from viewController: UIViewController?) async throws {
        didLoadAndPresent = true
        
        // Simulate async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}

public final class MockMobileAds: MobileAdsProtocol, @unchecked Sendable {
    public private(set) var startAdsCalledCount = 0

    public init() {}
    
    public func startAds() {
        startAdsCalledCount += 1
    }
}
