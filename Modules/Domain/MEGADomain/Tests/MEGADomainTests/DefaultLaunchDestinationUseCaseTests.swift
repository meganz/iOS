import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import Testing

@Suite("DefaultLaunchDestinationUseCaseTests")
struct DefaultLaunchDestinationUseCaseTests {

    // MARK: - selectedDestination

    @Test("Returns home when no value is stored")
    func selectedDestination_whenNoStoredValue_returnsHome() {
        let sut = makeSUT()
        #expect(sut.selectedDestination == .home)
    }

    @Test("Returns the stored destination when the stored value maps")
    func selectedDestination_whenStoredValueMapsToDestination_returnsThatDestination() {
        let preferenceUseCase = MockPreferenceUseCase(dict: ["defaultLaunchDestination": "stored-offline"])
        let sut = makeSUT(
            preferenceUseCase: preferenceUseCase,
            repository: MockDefaultLaunchDestinationRepository(storedValues: [.offline: "stored-offline"]))
        #expect(sut.selectedDestination == .offline)
    }

    @Test("Returns home when the stored value maps to no destination")
    func selectedDestination_whenStoredValueMapsToNoDestination_returnsHome() {
        let preferenceUseCase = MockPreferenceUseCase(dict: ["defaultLaunchDestination": "not-a-real-tab"])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        #expect(sut.selectedDestination == .home)
    }

    // MARK: - hasSelectedDestination

    @Test("hasSelectedDestination is false when no value is stored")
    func hasSelectedDestination_whenNoStoredValue_isFalse() {
        let sut = makeSUT()
        #expect(sut.hasSelectedDestination == false)
    }

    @Test("hasSelectedDestination is true when a value is stored")
    func hasSelectedDestination_whenStoredValue_isTrue() {
        let preferenceUseCase = MockPreferenceUseCase(dict: ["defaultLaunchDestination": "stored-offline"])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        #expect(sut.hasSelectedDestination)
    }

    @Test("hasSelectedDestination is true after a destination is set")
    func hasSelectedDestination_afterSetDestination_isTrue() {
        let repository = MockDefaultLaunchDestinationRepository(storedValues: [.offline: "stored-offline"])
        let sut = makeSUT(repository: repository)

        sut.setDestination(.offline)

        #expect(sut.hasSelectedDestination)
    }

    // MARK: - setDestination

    @Test("Persists the repository raw value under the launch destination key")
    func setDestination_persistsRepositoryValue() {
        let repository = MockDefaultLaunchDestinationRepository(storedValues: [.offline: "stored-offline"])
        let preferenceUseCase = MockPreferenceUseCase()
        let sut = makeSUT(preferenceUseCase: preferenceUseCase, repository: repository)

        sut.setDestination(.offline)

        #expect(preferenceUseCase.dict["defaultLaunchDestination"] as? String == "stored-offline")
    }

    @Test("Persisted value is readable by a fresh use case sharing storage")
    func setDestination_valueIsReadableByAFreshUseCaseSharingStorage() {
        let preferenceUseCase = MockPreferenceUseCase()
        let repository = MockDefaultLaunchDestinationRepository(storedValues: [.offline: "stored-offline"])
        let writer = makeSUT(preferenceUseCase: preferenceUseCase, repository: repository)

        writer.setDestination(.offline)

        let reader = makeSUT(preferenceUseCase: preferenceUseCase, repository: repository)
        #expect(reader.selectedDestination == .offline)
    }

    // MARK: - Helpers

    private func makeSUT(
        preferenceUseCase: MockPreferenceUseCase = MockPreferenceUseCase(),
        repository: MockDefaultLaunchDestinationRepository = MockDefaultLaunchDestinationRepository()
    ) -> DefaultLaunchDestinationUseCase {
        DefaultLaunchDestinationUseCase(preferenceUseCase: preferenceUseCase, repository: repository)
    }
}
