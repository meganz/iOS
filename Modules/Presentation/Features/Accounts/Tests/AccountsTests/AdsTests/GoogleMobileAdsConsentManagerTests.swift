import Accounts
import AccountsMock
import Testing
import UserMessagingPlatform

@Suite("GoogleMobileAdsConsentManagerTests")
struct GoogleMobileAdsConsentManagerTests {
    
    @Suite("Ads initialization")
    struct AdInitializationTests {
        @Test func testIsMobileAdsInitialized_canRequestAdsTrue_shouldBeTrue() async {
            let sut = makeSUT(canRequestAds: true)
            
            await sut.initializeGoogleMobileAdsSDK()
            
            #expect(sut.isMobileAdsInitialized)
        }
        
        @Test func testIsMobileAdsInitialized_canRequestAdsFalse_shouldBeFalse() async {
            let sut = makeSUT(canRequestAds: false)
            
            await sut.initializeGoogleMobileAdsSDK()
            
            #expect(!sut.isMobileAdsInitialized)
        }
        
        @Test func testInitializeGoogleMobileAdsSDK_shouldStartAdsOnce() async {
            let mockMobileAds = MockMobileAds()
            let sut = makeSUT(mobileAds: mockMobileAds)
            
            // First initialization
            await sut.initializeGoogleMobileAdsSDK()
            #expect(mockMobileAds.startAdsCalledCount == 1)
            
            // Second initialization
            await sut.initializeGoogleMobileAdsSDK()
            #expect(mockMobileAds.startAdsCalledCount == 1, "Should not call startAds again.")
        }
    }
    
    @Suite("Ads consent")
    struct AdConsentTests {
        @Test func testGatherConsent_shouldCallRequestConsentInfoUpdateAndLoadConsentDialogMethods() async throws {
            let mockConsentInformation = MockAdMobConsentInformation(shouldThrowError: false)
            let mockConsentForm = MockAdMobConsentForm.self
            let sut = makeSUT(consentInformation: mockConsentInformation, consentFormType: mockConsentForm)
            
            try await sut.gatherConsent()
            
            #expect(mockConsentInformation.didRequestConsentInfoUpdate)
            #expect(mockConsentForm.didLoadAndPresent)
        }
        
        @Test func testGatherConsent_receivedAFailedRequest_shouldReceiveThrownError() async {
            let sut = makeSUT(consentInformation: MockAdMobConsentInformation(shouldThrowError: true))
            
            await #expect(throws: AdMobError.genericError, performing: {
                try await sut.gatherConsent()
            })
        }
    }
    
    @Suite("Ads privacy options")
    struct AdPrivacyOptionsTests {
        static let privacyOptionsRequiredStatusArguments = [
            (status: UMPPrivacyOptionsRequirementStatus.required, expectedResult: true),
            (status: .notRequired, expectedResult: false),
            (status: .unknown, expectedResult: false)
        ]
        
        @Test(
            "IsPrivacyOptionsRequired should only be true if UMPPrivacyOptionsRequirementStatus is required",
            arguments: privacyOptionsRequiredStatusArguments
        )
        func isPrivacyOptionsRequired(
            status: UMPPrivacyOptionsRequirementStatus,
            expectedResult: Bool
        ) {
            let sut = makeSUT(
                consentInformation: MockAdMobConsentInformation(privacyOptionsRequirementStatus: status)
            )
            #expect(sut.isPrivacyOptionsRequired == expectedResult)
        }
        
        @Test(
            "Present privacy options form only when UMPPrivacyOptionsRequirementStatus is required",
            arguments: privacyOptionsRequiredStatusArguments
        )
        func presentPrivacyOptionsForm(
            status: UMPPrivacyOptionsRequirementStatus,
            expectedResult: Bool
        ) async throws {
            let sut = makeSUT(
                consentInformation: MockAdMobConsentInformation(privacyOptionsRequirementStatus: status)
            )
            
            let isPresented = try await sut.presentPrivacyOptionsForm()
            
            #expect(isPresented == expectedResult)
        }
    }
    
    // MARK: - Helper
    private static func makeSUT(
        canRequestAds: Bool = true,
        consentInformation: MockAdMobConsentInformation? = nil,
        consentFormType: any AdMobConsentFormProtocol.Type = MockAdMobConsentForm.self,
        mobileAds: MockMobileAds = MockMobileAds()
    ) -> GoogleMobileAdsConsentManager {
        GoogleMobileAdsConsentManager(
            consentInformation: consentInformation ?? MockAdMobConsentInformation(canRequestAds: canRequestAds),
            consentFormType: consentFormType,
            mobileAds: mobileAds
        )
    }
}
