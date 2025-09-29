@testable import Accounts
import MEGADomain
import MEGAL10n
import Testing

@Suite("Feature List Helper Tests Suite - Verifies the feature list generation for various account types.")
struct FeatureListHelperTestSuite {
    
    struct FeatureTestCase: Sendable {
        let type: FeatureType
        let title: String
        let freeText: String?
        let proText: String?
        let freeIconName: String?
        let proIconName: String?
    }
    
    static func featureTestCases() -> [FeatureTestCase] {
        let sut = makeSUT()
        return [
            FeatureTestCase(
                type: .storage,
                title: Strings.Localizable.storage,
                freeText: Strings.Localizable.Storage.Limit.capacity(20),
                proText: sut.currentPlan.storage,
                freeIconName: nil,
                proIconName: nil
            ),
            FeatureTestCase(
                type: .transfer,
                title: Strings.Localizable.transfer,
                freeText: Strings.Localizable.Account.TransferQuota.FreePlan.limited,
                proText: sut.currentPlan.transfer,
                freeIconName: nil,
                proIconName: nil
            ),
            FeatureTestCase(
                type: .passwordProtectedLinks,
                title: Strings.Localizable.Password.Protected.Links.title,
                freeText: nil,
                proText: nil,
                freeIconName: sut.assets.unavailableImageName,
                proIconName: sut.assets.availableImageName
            ),
            FeatureTestCase(
                type: .linksWithExpiryDate,
                title: Strings.Localizable.Links.With.Expiry.Dates.title,
                freeText: nil,
                proText: nil,
                freeIconName: sut.assets.unavailableImageName,
                proIconName: sut.assets.availableImageName
            ),
            FeatureTestCase(
                type: .callsAndMeetingsDuration,
                title: Strings.Localizable.CallAndMeeting.Duration.title,
                freeText: Strings.Localizable.CallAndMeeting.Duration.For.Free.users,
                proText: Strings.Localizable.CallAndMeeting.Duration.Unlimited.For.Pro.users,
                freeIconName: nil,
                proIconName: nil
            ),
            FeatureTestCase(
                type: .callsAndMeetingsParticipants,
                title: Strings.Localizable.CallAndMeeting.Participants.title,
                freeText: Strings.Localizable.CallAndMeeting.Participants.For.Free.users,
                proText: Strings.Localizable.CallAndMeeting.Participants.Unlimited.For.Pro.users,
                freeIconName: nil,
                proIconName: nil
            ),
            FeatureTestCase(
                type: .vpn,
                title: Strings.Localizable.Mega.Vpn.title,
                freeText: nil,
                proText: nil,
                freeIconName: sut.assets.unavailableImageName,
                proIconName: sut.assets.availableImageName
            )
        ]
    }

    // MARK: - Helpers
    private static func randomAccountType() -> AccountTypeEntity {
        AccountTypeEntity.allCases.randomElement() ?? .free
    }
    
    private static func makeSUT(
        accountType: AccountTypeEntity = .proI,
        unavailableImageName: String = "unavailable",
        availableImageName: String = "available"
    ) -> FeatureListHelper {
        let assets = CancelAccountPlanAssets(
            availableImageName: availableImageName,
            unavailableImageName: unavailableImageName
        )
        return FeatureListHelper(
            currentPlan: PlanEntity(type: accountType),
            assets: assets
        )
    }
    
    private static func createSutAndFeatures(
        accountType: AccountTypeEntity = .proI,
        baseStorage: Int = 20
    ) -> (FeatureListHelper, [FeatureDetails]) {
        let sut = makeSUT(accountType: accountType)
        let features = sut.createCurrentFeatures(baseStorage: baseStorage)
        return (sut, features)
    }
    
    private static func verifyRewindFeature(
        for accountType: AccountTypeEntity,
        expectedLimit: Int
    ) {
        let (_, features) = createSutAndFeatures(accountType: accountType)
        let rewindFeature = features.first { $0.type == .rewind }

        #expect(rewindFeature != nil, "Rewind feature should not be nil")
        #expect(rewindFeature?.title == Strings.Localizable.Rewind.Feature.title, "Rewind feature title mismatch")
        #expect(rewindFeature?.freeText == Strings.Localizable.Rewind.For.Free.users, "Rewind feature free text mismatch")
        #expect(rewindFeature?.proText == Strings.Localizable.Rewind.For.Pro.users(expectedLimit), "Rewind feature pro text mismatch for \(accountType)")
    }
    
    private static func verifyFeature(
        features: [FeatureDetails],
        featureType: FeatureType,
        title: String,
        freeText: String? = nil,
        proText: String? = nil,
        freeIconName: String? = nil,
        proIconName: String? = nil
    ) {
        let feature = features.first { $0.type == featureType }
        #expect(feature != nil, "\(featureType) feature should not be nil")
        #expect(feature?.title == title, "\(featureType) feature title mismatch")
        
        if let freeText = freeText {
            #expect(feature?.freeText == freeText, "\(featureType) free text mismatch")
        }
        
        if let proText = proText {
            #expect(feature?.proText == proText, "\(featureType) pro text mismatch")
        }
        
        if let freeIconName = freeIconName {
            #expect(feature?.freeIconName == freeIconName, "\(featureType) free icon name mismatch")
        }
        
        if let proIconName = proIconName {
            #expect(feature?.proIconName == proIconName, "\(featureType) pro icon name mismatch")
        }
    }
    
    // MARK: - Test Methods
    
    @Suite("Feature List Tests")
    struct FeatureListTests {
        
        @Test("Should return correct feature count")
        func featureCountIsCorrect() {
            let (_, features) = createSutAndFeatures()
            #expect(features.count == 9, "Expected 9 features but got \(features.count)")
        }
        
        @Test("Should have correct feature details for each feature", arguments: featureTestCases())
        func featureDetailsAreCorrect(for feature: FeatureTestCase) {
            let (_, features) = createSutAndFeatures()
            verifyFeature(
                features: features,
                featureType: feature.type,
                title: feature.title,
                freeText: feature.freeText,
                proText: feature.proText,
                freeIconName: feature.freeIconName,
                proIconName: feature.proIconName
            )
        }
        
        @Test("Should have correct rewind feature details for each plan", arguments: [(AccountTypeEntity.lite, 60), (AccountTypeEntity.proI, 60)])
        func rewindFeatureIsCorrect(for accountType: AccountTypeEntity, expectedLimit: Int) {
            verifyRewindFeature(
                for: accountType,
                expectedLimit: expectedLimit
            )
        }
    }
}
