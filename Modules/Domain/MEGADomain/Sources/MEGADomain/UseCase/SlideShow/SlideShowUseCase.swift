import Foundation

public protocol SlideShowUseCaseProtocol {
    var defaultConfig: SlideShowConfigurationEntity { get }
    func loadConfiguration(forUser userId: HandleEntity) -> SlideShowConfigurationEntity
    func saveConfiguration(config: SlideShowConfigurationEntity, forUser userId: HandleEntity) throws
}

public final class SlideShowUseCase: SlideShowUseCaseProtocol {
    private var preferenceRepo: any PreferenceRepositoryProtocol
    
    public let defaultConfig = SlideShowConfigurationEntity(
        playingOrder: .shuffled,
        timeIntervalForSlideInSeconds: .normal,
        isRepeat: false,
        includeSubfolders: false
    )

    public init(preferenceRepo: any PreferenceRepositoryProtocol) {
        self.preferenceRepo = preferenceRepo
    }
    
    private func preferenceKey(_ userId: HandleEntity) -> String {
        "slideshowConfig_\(userId)"
    }
    
    public func loadConfiguration(forUser userId: HandleEntity) -> SlideShowConfigurationEntity {
        let jsonData: Data? = preferenceRepo.value(forKey: preferenceKey(userId))
        guard let jsonData = jsonData,
              let config = try? JSONDecoder().decode(SlideShowConfigurationEntity.self, from: jsonData)
        else {
            return defaultConfig
        }
        return config
    }
    
    public func saveConfiguration(config: SlideShowConfigurationEntity, forUser userId: HandleEntity) throws {
        let jsonConfig = try JSONEncoder().encode(config)
        preferenceRepo.setValue(value: jsonConfig, forKey: preferenceKey(userId))
    }
}
