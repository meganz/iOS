import MEGADomain

public struct MockSlideShowUseCase: SlideShowUseCaseProtocol {
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
