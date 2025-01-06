import GoogleMobileAds
import MEGASwift
import UserMessagingPlatform

public protocol GoogleMobileAdsConsentManagerProtocol: Sendable {
    func gatherConsent() async throws
    func initializeGoogleMobileAdsSDK() async
}

public protocol AdMobConsentInformationProtocol: Sendable {
    var canRequestAds: Bool { get }
    func requestConsentInfoUpdate(
        with parameters: UMPRequestParameters?,
        completionHandler: @escaping UMPConsentInformationUpdateCompletionHandler
    )
}

public protocol AdMobConsentFormProtocol {
    static func loadAndPresentIfRequired(
        from viewController: UIViewController?
    ) async throws
}

public protocol MobileAdsProtocol: Sendable {
    func start(completionHandler: GADInitializationCompletionHandler?)
}

/// AdMob contains all the unit ids for AdMob.
/// `test` should be used on QA, Dev and Testflight builds
/// `live` should only be used on production or live build
public enum AdMob {
    case test
    case live
    
    var unitID: String {
        switch self {
        case .test: "ca-app-pub-3940256099942544/2435281174"
        case .live: "ca-app-pub-2135147798858967/6621585063"
        }
    }
}

/// The Google Mobile Ads SDK provides the User Messaging Platform (Google's
/// IAB Certified consent management platform) as one solution to capture
/// consent for users in GDPR impacted countries.
public struct GoogleMobileAdsConsentManager: GoogleMobileAdsConsentManagerProtocol {
    public static let shared = GoogleMobileAdsConsentManager()
    
    private let consentInformation: AdMobConsentInformationProtocol
    private let consentFormType: AdMobConsentFormProtocol.Type
    private let mobileAds: MobileAdsProtocol

    @Atomic public var isMobileAdsInitialized = false
    
    var canRequestAds: Bool {
        consentInformation.canRequestAds
    }
    
    public init(
        consentInformation: AdMobConsentInformationProtocol = UMPConsentInformation.sharedInstance,
        consentFormType: AdMobConsentFormProtocol.Type = UMPConsentForm.self,
        mobileAds: MobileAdsProtocol = GADMobileAds.sharedInstance()
    ) {
        self.consentInformation = consentInformation
        self.consentFormType = consentFormType
        self.mobileAds = mobileAds
    }
    
    /// Calls the UMP SDK methods to request consent information and load/present a
    /// consent form if necessary.
    @MainActor
    public func gatherConsent() async throws {
        do {
            // Requesting an update to consent information should be called on every app launch.
            try await requestConsentInfoUpdate()
            try await consentFormType.loadAndPresentIfRequired(from: nil)
        } catch {
            throw error
        }
    }
    
    /// Initializes the Google Mobile Ads SDK. The SDK should only be initialized once.
    @MainActor
    public func initializeGoogleMobileAdsSDK() {
        guard canRequestAds, !isMobileAdsInitialized else { return }
        
        $isMobileAdsInitialized.mutate { $0 = true }
        
        mobileAds.start(completionHandler: nil)
    }
    
    // MARK: - Private
    @discardableResult
    private func requestConsentInfoUpdate() async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            let parameters = UMPRequestParameters()
            parameters.tagForUnderAgeOfConsent = false
            
            consentInformation.requestConsentInfoUpdate(with: parameters) { requestConsentError in
                if let requestConsentError {
                    completion(.failure(requestConsentError))
                    return
                }
                completion(.success(true))
            }
        }
    }
}

extension UMPConsentInformation: @retroactive @unchecked Sendable {}
extension UMPConsentInformation: AdMobConsentInformationProtocol {}

extension UMPConsentForm: @retroactive @unchecked Sendable {}
extension UMPConsentForm: AdMobConsentFormProtocol {}

extension GADMobileAds: @retroactive @unchecked Sendable {}
extension GADMobileAds: MobileAdsProtocol {}
