import GoogleMobileAds
import MEGASwift
import UserMessagingPlatform

public protocol GoogleMobileAdsConsentManagerProtocol {
    func gatherConsent() async throws
    func initializeGoogleMobileAdsSDK() async
}

public protocol AdMobConsentInformationProtocol {
    var canRequestAds: Bool { get }
    func requestConsentInfoUpdate(with parameters: UMPRequestParameters?) async throws
}

public protocol AdMobConsentFormProtocol {
    static func loadAndPresentIfRequired(from viewController: UIViewController?) async throws
}

public protocol MobileAdsProtocol {
    func startAds() async
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
            try await consentInformation.requestConsentInfoUpdate(with: nil)
            try await consentFormType.loadAndPresentIfRequired(from: nil)
        } catch {
            throw error
        }
    }
    
    /// Initializes the Google Mobile Ads SDK. The SDK should only be initialized once.
    @MainActor
    public func initializeGoogleMobileAdsSDK() async {
        guard canRequestAds, !isMobileAdsInitialized else { return }
        
        $isMobileAdsInitialized.mutate { $0 = true }
        
        await mobileAds.startAds()
    }
}

extension UMPConsentInformation: AdMobConsentInformationProtocol {}

extension UMPConsentForm: AdMobConsentFormProtocol {}

extension GADMobileAds: MobileAdsProtocol {
    public func startAds() async {
        await start()
    }
}
