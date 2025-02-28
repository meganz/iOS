import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@testable import Settings

@Suite("MediaQualityViewModelTestSuit")
@MainActor struct MediaQualityViewModelTestSuite {
    private static func makeSUT(
        defaultPreferenceUseCase: any PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [.chatImageQuality: 0]),
        groupPreferenceUseCase: any PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [.chatVideoQuality: 2])
    ) -> ChatMediaQualityViewModel {
        ChatMediaQualityViewModel(
            defaultPreferenceUseCase: defaultPreferenceUseCase,
            groupPreferenceUseCase: groupPreferenceUseCase
        )
    }
    
    @Suite("ImageMediaQualityTests")
    @MainActor struct ImageMediaQualityTests {
        @Test(
            "Image quality option tapped",
            arguments: ChatMediaQuality.imageQualityOptions()
        )
        func imageQualityOptionTapped(_ option: ChatMediaQuality) {
            let imagePreferenceUseCase = MockPreferenceUseCase(dict: [.chatImageQuality: 0])
            let sut = makeSUT(
                defaultPreferenceUseCase: imagePreferenceUseCase
            )
            
            sut.imageQualityOptionTapped(option)
            
            #expect(imagePreferenceUseCase.dict[.chatImageQuality] as? Int == sut.chatImageQuality(from: option))
            #expect(sut.imageMediaQuality == option)
        }
    }
    
    @Suite("VideoMediaQualityTests")
    @MainActor struct VideoMediaQualityTests {
        @Test(
            "Video quality option tapped",
            arguments: ChatMediaQuality.videoQualityOptions()
        )
        func videoQualityOptionTapped(_ option: ChatMediaQuality) {
            let videoQualityPreferenceUseCase = MockPreferenceUseCase(dict: [.chatVideoQuality: 2])
            let sut = makeSUT(
                groupPreferenceUseCase: videoQualityPreferenceUseCase
            )
            
            sut.videoQualityOptionTapped(option)
            
            #expect(videoQualityPreferenceUseCase.dict[.chatVideoQuality] as? Int == sut.chatVideoQuality(from: option))
            #expect(sut.videoMediaQuality == option)
        }
    }
}
