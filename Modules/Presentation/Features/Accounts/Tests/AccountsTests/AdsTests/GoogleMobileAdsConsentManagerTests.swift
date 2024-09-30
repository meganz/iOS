import Accounts
import AccountsMock
import Testing

struct GoogleMobileAdsConsentManagerTests {
    
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
    
    // MARK: - Helper
    func makeSUT(
        canRequestAds: Bool = true,
        consentInformation: MockAdMobConsentInformation? = nil,
        consentFormType: AdMobConsentFormProtocol.Type = MockAdMobConsentForm.self,
        mobileAds: MockMobileAds = MockMobileAds()
    ) -> GoogleMobileAdsConsentManager {
        GoogleMobileAdsConsentManager(
            consentInformation: consentInformation ?? MockAdMobConsentInformation(canRequestAds: canRequestAds),
            consentFormType: consentFormType,
            mobileAds: mobileAds
        )
    }
}
