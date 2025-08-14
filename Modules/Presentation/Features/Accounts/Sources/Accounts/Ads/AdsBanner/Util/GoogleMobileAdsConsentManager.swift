@preconcurrency import GoogleMobileAds
import MEGADomain
import MEGARepo
import MEGASwift
@preconcurrency import UserMessagingPlatform

public protocol GoogleMobileAdsConsentManagerProtocol: Sendable {
    var isPrivacyOptionsRequired: Bool { get }
    func gatherConsent() async throws
    func initializeGoogleMobileAdsSDK() async
    func presentPrivacyOptionsForm() async throws -> Bool
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
    
    private let consentInformation: ConsentInformation
    private let consentFormType: ConsentForm.Type
    private let mobileAds: MobileAds

    @Atomic public var isMobileAdsInitialized = false
    
    var canRequestAds: Bool {
        consentInformation.canRequestAds
    }
    
    public var isPrivacyOptionsRequired: Bool {
        consentInformation.privacyOptionsRequirementStatus == .required
    }
    
    public init(
        consentInformation: ConsentInformation = ConsentInformation.shared,
        consentFormType: ConsentForm.Type = ConsentForm.self,
        mobileAds: MobileAds = MobileAds.shared
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
    public func initializeGoogleMobileAdsSDK() async {
        await withAsyncValue { completion in
            guard canRequestAds, !isMobileAdsInitialized else {
                completion(.success)
                return
            }
            
            $isMobileAdsInitialized.mutate { $0 = true }
            
            mobileAds.start { _ in
                completion(.success)
            }
        }
    }
    
    /// Presents the privacy options form if required.
    ///
    /// This function checks whether the privacy options form is needed (`isPrivacyOptionsRequired`),
    /// and if so, it asynchronously presents the form using `consentFormType`.
    @MainActor
    public func presentPrivacyOptionsForm() async throws -> Bool {
        guard isPrivacyOptionsRequired else { return false }
        try await consentFormType.presentPrivacyOptionsForm(from: nil)
        return true
    }
    
    // MARK: - Private
    @discardableResult
    private func requestConsentInfoUpdate() async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            let parameters = RequestParameters()
            parameters.isTaggedForUnderAgeOfConsent = false

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
