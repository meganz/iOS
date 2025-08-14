import Accounts
import GoogleMobileAds
import UserMessagingPlatform

public enum AdMobError: Error {
    case genericError
}

public final class MockGoogleMobileAdsConsentManager: GoogleMobileAdsConsentManagerProtocol, @unchecked Sendable {
    public private(set) var isPrivacyOptionsRequired: Bool = false
    public private(set) var gatherConsentCalledCount = 0
    public private(set) var initializeGoogleMobileAdsSDKCalledCount = 0
    public private(set) var presentPrivacyOptionsFormCalledCount = 0

    public init(isPrivacyOptionsRequired: Bool = false) {
        self.isPrivacyOptionsRequired = isPrivacyOptionsRequired
    }
    
    public func gatherConsent() async throws {
        gatherConsentCalledCount += 1
    }
    
    public func initializeGoogleMobileAdsSDK() async {
        initializeGoogleMobileAdsSDKCalledCount += 1
    }
    
    public func presentPrivacyOptionsForm() async throws -> Bool {
        presentPrivacyOptionsFormCalledCount += 1
        return true
    }
}

public final class MockAdMobConsentInformation: ConsentInformation, @unchecked Sendable {
    private var _canRequestAds: Bool
    public private(set) var didRequestConsentInfoUpdate = false
    private var _privacyOptionsRequirementStatus: PrivacyOptionsRequirementStatus
    private let shouldThrowError: Bool

    public override var canRequestAds: Bool {
        get {
            _canRequestAds
        }
        
        set {
            _canRequestAds = newValue
        }
    }
    
    public override var privacyOptionsRequirementStatus: PrivacyOptionsRequirementStatus {
        get {
            _privacyOptionsRequirementStatus
        }
        
        set {
            _privacyOptionsRequirementStatus = newValue
        }
    }
    
    public init(
        privacyOptionsRequirementStatus: PrivacyOptionsRequirementStatus = .unknown,
        canRequestAds: Bool = true,
        shouldThrowError: Bool = false
    ) {
        self._canRequestAds = canRequestAds
        self.shouldThrowError = shouldThrowError
        self._privacyOptionsRequirementStatus = privacyOptionsRequirementStatus
    }
    
    public override func requestConsentInfoUpdate(with parameters: RequestParameters?, completionHandler: @escaping UMPConsentInformationUpdateCompletionHandler) {
        didRequestConsentInfoUpdate = true
        if shouldThrowError {
            completionHandler(AdMobError.genericError)
        } else {
            completionHandler(nil)
        }
    }
}

public final class MockAdMobConsentForm: ConsentForm, @unchecked Sendable {
    nonisolated(unsafe) public static private(set) var didLoadAndPresent = false
    
    public override static func loadAndPresentIfRequired(from viewController: UIViewController?) async throws {
        didLoadAndPresent = true
    }
    
    public override static func presentPrivacyOptionsForm(from viewController: UIViewController?) async throws {}
}

public final class MockMobileAds: MobileAds, @unchecked Sendable {
    public private(set) var startAdsCalledCount = 0

    public override init() {}
    
    public override func start(completionHandler: GADInitializationCompletionHandler?) {
        startAdsCalledCount += 1
        completionHandler?(.init())
    }
}
