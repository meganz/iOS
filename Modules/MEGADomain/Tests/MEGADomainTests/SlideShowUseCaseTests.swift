import XCTest
import MEGADomain
import MEGADomainMock

final class SlideShowUseCaseTests: XCTestCase {
    func testSlideShowSaveConfiguration_whenSavingConfiguration_shouldReturnSavedConfig() async throws {
        let newConfig = SlideShowConfigurationEntity(playingOrder: .newest,
                                               timeIntervalForSlideInSeconds: .fast,
                                               isRepeat: true,
                                               includeSubfolders: false)
        
        let sut = SlideShowUseCase(slideShowRepository: MockSlideShowRepository.newRepo)
        sut.saveConfiguration(newConfig)
        XCTAssert(sut.loadConfiguration() == newConfig)
    }
    
    func testSlideShowLoadConfiguration_whenLoadingConfiguration_shouldReturnSavedConfig() async throws {
        let newConfig1 = SlideShowConfigurationEntity(playingOrder: .newest,
                                               timeIntervalForSlideInSeconds: .fast,
                                               isRepeat: true,
                                               includeSubfolders: false)
        
        let newConfig2 = SlideShowConfigurationEntity(playingOrder: .oldest,
                                               timeIntervalForSlideInSeconds: .slow,
                                               isRepeat: true,
                                               includeSubfolders: false)
        
        let sut = SlideShowUseCase(slideShowRepository: MockSlideShowRepository.newRepo)
        
        sut.saveConfiguration(newConfig1)
        XCTAssert(sut.loadConfiguration() == newConfig1)
        
        sut.saveConfiguration(newConfig2)
        XCTAssert(sut.loadConfiguration() == newConfig2)
    }

}
