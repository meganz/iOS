import MEGADomain

public final class MockSlideShowRepository: SlideShowRepositoryProtocol {
    private var config: SlideShowConfigurationEntity
    
    public static var newRepo: MockSlideShowRepository {
        MockSlideShowRepository(withConfig: .init(
                playingOrder: .shuffled,
                timeIntervalForSlideInSeconds: .normal,
                isRepeat: false,
                includeSubfolders: false
            )
        )
    }
    
    public init(withConfig config: SlideShowConfigurationEntity) {
        self.config = config
    }
    
    public func loadConfiguration() -> SlideShowConfigurationEntity {
        config
    }
    
    public func saveConfiguration(_ config: SlideShowConfigurationEntity) {
        self.config = config
    }
}
