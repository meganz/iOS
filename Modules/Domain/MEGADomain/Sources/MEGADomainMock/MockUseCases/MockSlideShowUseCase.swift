import MEGADomain

public final class MockSlideShowUseCase: SlideShowUseCaseProtocol {
    public var defaultConfig = SlideShowConfigurationEntity(
        playingOrder: .shuffled,
        timeIntervalForSlideInSeconds: .normal,
        isRepeat: false,
        includeSubfolders: false)
    
    private var config: SlideShowConfigurationEntity
    private var userId: HandleEntity
    
    public init(
        config: SlideShowConfigurationEntity = .init(playingOrder: .shuffled, timeIntervalForSlideInSeconds: .slow, isRepeat: false, includeSubfolders: false),
        forUser userId: HandleEntity = .invalid) {
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
