import MEGADomain
import MEGADomainMock
import Testing

@Suite("FirebaseAnalyticsConsentUseCase Tests")
struct FirebaseAnalyticsConsentUseCaseTests {

    // Box is needed because MockFirebaseAnalyticsRepository's handler is @Sendable,
    // which prevents mutating a captured local var across the concurrency boundary.
    private final class Box<T>: @unchecked Sendable {
        var value: T?
    }

    private func makeSUT(
        storefrontCode: String?,
        localeCode: String?,
        box: Box<Bool>
    ) -> FirebaseAnalyticsConsentUseCase {
        FirebaseAnalyticsConsentUseCase(
            analyticsRepository: MockFirebaseAnalyticsRepository(
                onSetAnalyticsEnabled: { box.value = $0 }
            ),
            regionRepository: MockAnalyticsRegionRepository(
                storefrontCode: storefrontCode,
                localeCode: localeCode
            )
        )
    }

    @Test("disableCollection always disables analytics")
    func disableCollection_disablesAnalytics() {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: "USA", localeCode: "US", box: box)

        sut.disableCollection()

        #expect(box.value == false)
    }

    @Test("updateCollection with no consent disables regardless of region")
    func updateCollection_noConsent_disablesRegardlessOfRegion() async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: "USA", localeCode: "US", box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: false)

        #expect(box.value == false)
    }

    @Test("updateCollection with consent enables when both signals are allowed alpha-2",
          arguments: [("US", "US"), ("CA", "CA"), ("JP", "JP"), ("KR", "KR")])
    func updateCollection_consentAndBothAllowedAlpha2_enables(codes: (String, String)) async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: codes.0, localeCode: codes.1, box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == true)
    }

    @Test("updateCollection with consent enables when both signals are allowed alpha-3 storefront and alpha-2 locale",
          arguments: [("USA", "US"), ("CAN", "CA"), ("JPN", "JP"), ("KOR", "KR")])
    func updateCollection_consentAndBothAllowedMixedForms_enables(codes: (String, String)) async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: codes.0, localeCode: codes.1, box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == true)
    }

    @Test("updateCollection with consent disables when storefront is disallowed even if locale is allowed")
    func updateCollection_consentAndDisallowedStorefront_disables() async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: "USA", localeCode: "DE", box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == false)
    }

    @Test("updateCollection with consent disables when locale is disallowed even if storefront is allowed")
    func updateCollection_consentAndDisallowedLocale_disables() async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: "DEU", localeCode: "US", box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == false)
    }

    @Test("updateCollection with consent disables when both signals are disallowed",
          arguments: [("DE", "DE"), ("DEU", "FR"), ("GB", "CN")])
    func updateCollection_consentAndBothDisallowed_disables(codes: (String, String)) async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: codes.0, localeCode: codes.1, box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == false)
    }

    @Test("updateCollection with consent disables when storefront is nil")
    func updateCollection_consentAndNilStorefront_disables() async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: nil, localeCode: "US", box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == false)
    }

    @Test("updateCollection with consent disables when locale is nil")
    func updateCollection_consentAndNilLocale_disables() async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: "USA", localeCode: nil, box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == false)
    }

    @Test("updateCollection with consent disables when both signals are nil")
    func updateCollection_consentAndBothNil_disables() async {
        let box = Box<Bool>()
        let sut = makeSUT(storefrontCode: nil, localeCode: nil, box: box)

        await sut.updateCollection(performanceAndAnalyticsConsent: true)

        #expect(box.value == false)
    }
}
