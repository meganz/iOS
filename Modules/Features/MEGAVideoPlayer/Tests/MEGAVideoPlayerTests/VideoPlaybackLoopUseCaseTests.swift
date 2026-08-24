import MEGAPreference
import MEGAPreferenceMocks
@testable import MEGAVideoPlayer
import Testing

@MainActor
struct VideoPlaybackLoopUseCaseTests {
    @Test
    func isLoopEnabled_whenNothingPersisted_isFalse() {
        let sut = makeSUT()

        #expect(sut.isLoopEnabled == false)
    }

    @Test(arguments: [true, false])
    func setLoopEnabled_persistsValue(_ enabled: Bool) {
        let preferenceUseCase = MockPreferenceUseCase()
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)

        sut.setLoopEnabled(enabled)

        #expect(sut.isLoopEnabled == enabled)
        #expect(makeSUT(preferenceUseCase: preferenceUseCase).isLoopEnabled == enabled)
    }

    // MARK: - Helper

    private func makeSUT(
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase()
    ) -> VideoPlaybackLoopUseCase {
        VideoPlaybackLoopUseCase(
            preferenceUseCase: preferenceUseCase
        )
    }
}
