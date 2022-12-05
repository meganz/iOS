import MEGADomain
import Foundation

public struct SlideShowRepository: SlideShowRepositoryProtocol {
    @PreferenceWrapper(key: .slideShowConfigPlayingOrder, defaultValue: SlideShowPlayingOrderEntity.shuffled.value, useCase: PreferenceUseCase.default)
    private var playingOrder: Int
    
    @PreferenceWrapper(key: .slideShowConfigTimeInterval, defaultValue: SlideShowTimeIntervalOptionEntity.normal.value, useCase: PreferenceUseCase.default)
    private var timeInterval: Double
    
    @PreferenceWrapper(key: .slideShowConfigIsRepeat, defaultValue: false, useCase: PreferenceUseCase.default)
    private var isRepeat: Bool
    
    @PreferenceWrapper(key: .slideShowConfigIncludeSubfolder, defaultValue: false, useCase: PreferenceUseCase.default)
    private var includeSubfolder: Bool
    
    public static var newRepo: SlideShowRepository {
        SlideShowRepository()
    }
    
    public func loadConfiguration() -> SlideShowConfigurationEntity {
        SlideShowConfigurationEntity(
            playingOrder: SlideShowPlayingOrderEntity.type(for: playingOrder),
            timeIntervalForSlideInSeconds: SlideShowTimeIntervalOptionEntity.type(for: timeInterval),
            isRepeat: isRepeat,
            includeSubfolders: includeSubfolder
        )
    }
    
    public func saveConfiguration(_ config: SlideShowConfigurationEntity) {
        playingOrder = config.playingOrder.value
        timeInterval = config.timeIntervalForSlideInSeconds.value
        isRepeat = config.isRepeat
        includeSubfolder = config.includeSubfolders
    }
}
