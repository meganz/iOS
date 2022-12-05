import Foundation

public protocol SlideShowUseCaseProtocol {
    func loadConfiguration() -> SlideShowConfigurationEntity
    func saveConfiguration(_ config: SlideShowConfigurationEntity)
}

public struct SlideShowUseCase: SlideShowUseCaseProtocol {
    private let slideShowRepository: SlideShowRepositoryProtocol
    
    public init(slideShowRepository: SlideShowRepositoryProtocol) {
        self.slideShowRepository = slideShowRepository
    }
    
    public func loadConfiguration() -> SlideShowConfigurationEntity {
        slideShowRepository.loadConfiguration()
    }
    
    public func saveConfiguration(_ config: SlideShowConfigurationEntity) {
        slideShowRepository.saveConfiguration(config)
    }
}
