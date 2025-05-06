import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPreference
@testable import Settings
import Testing

@Suite("MediaQualityViewModelTestSuit")
@MainActor struct MediaQualityViewModelTestSuite {
    private static func makeSUT(
        defaultPreferenceUseCase: any PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [PreferenceKeyEntity.chatImageQuality.rawValue: 0]),
        groupPreferenceUseCase: any PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [PreferenceKeyEntity.chatVideoQuality.rawValue: 2])
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
            let imagePreferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.chatImageQuality.rawValue: 0])
            let sut = makeSUT(
                defaultPreferenceUseCase: imagePreferenceUseCase
            )
            
            sut.imageQualityOptionTapped(option)
            
            #expect(imagePreferenceUseCase.dict[PreferenceKeyEntity.chatImageQuality.rawValue] as? Int == sut.chatImageQuality(from: option))
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
            let videoQualityPreferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.chatVideoQuality.rawValue: 2])
            let sut = makeSUT(
                groupPreferenceUseCase: videoQualityPreferenceUseCase
            )
            
            sut.videoQualityOptionTapped(option)
            
            #expect(videoQualityPreferenceUseCase.dict[PreferenceKeyEntity.chatVideoQuality.rawValue] as? Int == sut.chatVideoQuality(from: option))
            #expect(sut.videoMediaQuality == option)
        }
    }
}
