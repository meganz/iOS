@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGASDKRepoMock
import XCTest

final class AdsSlotViewModelTests: XCTestCase {
    
    // MARK: Feature flag
    func testIsFeatureFlagForInAppAdsEnabled_inAppAdsEnabled_shouldBeEnabled() {
        let sut = makeSUT(featureFlags: [.inAppAds: true])
        XCTAssertTrue(sut.isFeatureFlagForInAppAdsEnabled)
    }
    
    func testIsFeatureFlagForInAppAdsEnabled_inAppAdsDisabled_shouldBeEnabled() {
        let sut = makeSUT(featureFlags: [.inAppAds: false])
        XCTAssertFalse(sut.isFeatureFlagForInAppAdsEnabled)
    }
    
    // MARK: Setup ad slot
    func testSetUpAdSlot_featureFlagEnabled_withFreeAccount_shouldShowAdsTrue() async {
        let sut = makeSUT(featureFlags: [.inAppAds: true],
                          currentAccountDetails: AccountDetailsEntity(proLevel: .free))
        
        await sut.setUpAdSlot()
        XCTAssertTrue(sut.shouldShowAds)
    }
    
    func testSetUpAdSlot_featureFlagDisabled_withFreeAccount_shouldShowAdsFalse() async {
        let sut = makeSUT(featureFlags: [.inAppAds: false],
                          currentAccountDetails: AccountDetailsEntity(proLevel: .free))
        
        await sut.setUpAdSlot()
        XCTAssertFalse(sut.shouldShowAds)
    }
    
    func testSetUpAdSlot_featureFlagEnabled_withSubscriptionAccount_shouldShowAdsFalse() async {
        let sut = makeSUT(featureFlags: [.inAppAds: false],
                          currentAccountDetails: accountDetailWithRandomPlan)
        
        await sut.setUpAdSlot()
        XCTAssertFalse(sut.shouldShowAds)
    }
    
    func testLoadAds_featureFlagEnabled_withFreeAccount_shouldHaveAds() async {
        let adsSlot = AdsSlotEntity.files
        let expectedAdsURL = "https://testAd/newLink"
        let sut = makeSUT(adsSlot: adsSlot,
                          adsList: [adsSlot.rawValue: expectedAdsURL],
                          featureFlags: [.inAppAds: true],
                          currentAccountDetails: AccountDetailsEntity(proLevel: .free))
        
        await sut.setUpAdSlot()
        await sut.loadAds()
        
        XCTAssertTrue(sut.displayAds)
        XCTAssertNotNil(sut.adsUrl)
        XCTAssertEqual(sut.adsUrl?.absoluteString, expectedAdsURL)
    }
    
    // MARK: Load ads
    func testLoadAds_featureFlagDisabled_withFreeAccount_shouldNotHaveAds() async {
        let adsSlot = AdsSlotEntity.files
        let expectedAdsURL = "https://testAd/newLink"
        let sut = makeSUT(adsSlot: adsSlot,
                          adsList: [adsSlot.rawValue: expectedAdsURL],
                          featureFlags: [.inAppAds: false],
                          currentAccountDetails: AccountDetailsEntity(proLevel: .free))
        
        await sut.setUpAdSlot()
        await sut.loadAds()
        
        XCTAssertFalse(sut.displayAds)
        XCTAssertNil(sut.adsUrl)
    }
    
    func testLoadAds_featureFlagEnabled_withSubscriptionAccount_shouldNotHaveAds() async {
        let adsSlot = AdsSlotEntity.files
        let expectedAdsURL = "https://testAd/newLink"
        let sut = makeSUT(adsSlot: adsSlot,
                          adsList: [adsSlot.rawValue: expectedAdsURL],
                          featureFlags: [.inAppAds: false],
                          currentAccountDetails: accountDetailWithRandomPlan)
        
        await sut.setUpAdSlot()
        await sut.loadAds()
        
        XCTAssertFalse(sut.displayAds)
        XCTAssertNil(sut.adsUrl)
    }
    
    // MARK: Fetch new ads
    func testFetchAccountDetails_withCurrentAccountDetails_shouldReturnAccountDetails() async {
        let expectedAccountDetail = AccountDetailsEntity.random
        
        let sut = makeSUT(currentAccountDetails: expectedAccountDetail)
        let accountDetails = await sut.fetchAccountDetails()
        
        XCTAssertEqual(accountDetails, expectedAccountDetail)
    }
    
    func testFetchAccountDetails_noCurrentAccountDetails_successRequestResult_shouldReturnAccountDetails() async {
        let expectedAccountDetail = AccountDetailsEntity.random
        
        let sut = makeSUT(currentAccountDetails: nil,
                          accountDetailsResult: .success(expectedAccountDetail))
        let accountDetails = await sut.fetchAccountDetails()
        
        XCTAssertEqual(accountDetails, expectedAccountDetail)
    }
    
    func testFetchAccountDetails_noCurrentAccountDetails_failedRequestResult_shouldReturnNil() async {
        let sut = makeSUT(currentAccountDetails: nil,
                          accountDetailsResult: .failure(.generic))
        
        let accountDetails = await sut.fetchAccountDetails()
        
        XCTAssertNil(accountDetails)
    }
    
    func testFetchNewAds_featureFlagEnabled_withFreeAccount_shouldHaveNewUrlAndDisplayAds() async {
        let adsSlot = AdsSlotEntity.files
        let expectedAdsURL = "https://testAd/newLink"
        
        let sut = makeSUT(adsSlot: adsSlot,
                          adsList: [adsSlot.rawValue: expectedAdsURL],
                          featureFlags: [.inAppAds: true],
                          currentAccountDetails: AccountDetailsEntity(proLevel: .free)
        )
        sut.adsUrl = URL(string: "https://testAd/oldLink")
        
        await sut.setUpAdSlot()
        sut.fetchNewAds()
        await sut.fetchNewAdsTask?.value
        
        XCTAssertNotNil(sut.adsUrl)
        XCTAssertEqual(sut.adsUrl?.absoluteString, expectedAdsURL)
        XCTAssertTrue(sut.displayAds)
    }
    
    func testFetchNewAds_featureFlagEnabled_withSubscriptionAccount_shouldHaveNilUrlAndDontDisplayAds() async {
        let adsSlot = AdsSlotEntity.files
        let sut = makeSUT(adsSlot: adsSlot,
                          adsList: [adsSlot.rawValue: "https://testAd/newLink"],
                          featureFlags: [.inAppAds: true],
                          currentAccountDetails: accountDetailWithRandomPlan)
        
        await sut.setUpAdSlot()
        sut.fetchNewAds()
        await sut.fetchNewAdsTask?.value
        
        XCTAssertNil(sut.adsUrl)
        XCTAssertFalse(sut.displayAds)
    }
    
    func testFetchNewAds_featureFlagDisabled_withFreeAccount_shouldHaveNilUrlAndDontDisplayAds() async {
        let adsSlot = AdsSlotEntity.files
        let sut = makeSUT(adsSlot: adsSlot,
                          adsList: [adsSlot.rawValue: "https://testAd/newLink"],
                          featureFlags: [.inAppAds: false],
                          currentAccountDetails: AccountDetailsEntity(proLevel: .free)
        )
        
        await sut.setUpAdSlot()
        sut.fetchNewAds()
        await sut.fetchNewAdsTask?.value
        
        XCTAssertNil(sut.adsUrl)
        XCTAssertFalse(sut.displayAds)
    }

    // MARK: Helper
    private func makeSUT(
        adsSlot: AdsSlotEntity? = nil,
        adsList: [String: String] = [:],
        featureFlags: [FeatureFlagKey: Bool] = [FeatureFlagKey.inAppAds: true],
        currentAccountDetails: AccountDetailsEntity? = nil,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .success(.random),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AdsSlotViewModel {
        
        let accountUseCase = MockAccountUseCase(currentAccountDetails: currentAccountDetails, accountDetailsResult: accountDetailsResult)
        let adsUseCase = MockAdsUseCase(adsList: adsList)
        let featureFlagProvider = MockFeatureFlagProvider(list: featureFlags)
        
        let sut = AdsSlotViewModel(adsUseCase: adsUseCase,
                                   accountUseCase: accountUseCase,
                                   adsSlot: adsSlot,
                                   featureFlagProvider: featureFlagProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private var accountDetailWithRandomPlan: AccountDetailsEntity {
        let plans: [AccountTypeEntity] = [.lite, .proI, .proII, .proIII, .proFlexi, .business]
        return AccountDetailsEntity(proLevel: plans.randomElement() ?? .proI)
    }
}
