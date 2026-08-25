import Accounts
import GoogleMobileAds
import UserMessagingPlatform

public enum AdMobError: Error {
    case genericError
}

public final class MockGoogleMobileAdsConsentManager: GoogleMobileAdsConsentManagerProtocol, @unchecked Sendable {
    public private(set) var isPrivacyOptionsRequired: Bool = false
    public private(set) var isMobileAdsInitialized: Bool
    public private(set) var gatherConsentCalledCount = 0
    public private(set) var initializeGoogleMobileAdsSDKCalledCount = 0
    public private(set) var presentPrivacyOptionsFormCalledCount = 0

    public init(
        isPrivacyOptionsRequired: Bool = false,
        isMobileAdsInitialized: Bool = false
    ) {
        self.isPrivacyOptionsRequired = isPrivacyOptionsRequired
        self.isMobileAdsInitialized = isMobileAdsInitialized
    }
    
    public func gatherConsent() async throws {
        gatherConsentCalledCount += 1
    }
    
    public func initializeGoogleMobileAdsSDK() async {
        initializeGoogleMobileAdsSDKCalledCount += 1
        isMobileAdsInitialized = true
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
    /// Asked while starting is still under way, so a test can look at the manager from inside that window.
    public var readIsMobileAdsInitialized: (@Sendable () -> Bool)?
    public private(set) var wasMobileAdsInitializedWhileStarting: Bool?

    public override init() {}
    
    public override func start(completionHandler: GADInitializationCompletionHandler?) {
        startAdsCalledCount += 1
        wasMobileAdsInitializedWhileStarting = readIsMobileAdsInitialized?()
        completionHandler?(.init())
    }
}
