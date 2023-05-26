import MEGADomain

public final class MockSlideShowUseCase: SlideShowUseCaseProtocol {
    public var defaultConfig = SlideShowConfigurationEntity(
        playingOrder: .shuffled,
        timeIntervalForSlideInSeconds: .normal,
        isRepeat: false,
        includeSubfolders: false)
    
    private var config: SlideShowConfigurationEntity
    private var userId: HandleEntity
    
    public init(config: SlideShowConfigurationEntity, forUser userId: HandleEntity) {
        self.config = config
        self.userId = userId
    }
    
    public func loadConfiguration(forUser userId: HandleEntity) -> SlideShowConfigurationEntity {
        config
    }
    
    public func saveConfiguration(config: SlideShowConfigurationEntity, forUser userId: HandleEntity) throws {
        self.config = config
        self.userId = userId
    }
}
