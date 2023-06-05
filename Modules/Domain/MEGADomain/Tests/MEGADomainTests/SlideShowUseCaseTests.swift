import XCTest
import MEGADomain
import MEGADomainMock

final class SlideShowUseCaseTests: XCTestCase {
    func testSlideShowSaveConfiguration_whenSavingConfiguration_shouldReturnSavedConfig() async throws {
        let newConfig = SlideShowConfigurationEntity(playingOrder: .newest,
                                               timeIntervalForSlideInSeconds: .fast,
                                               isRepeat: true,
                                               includeSubfolders: false)
        
        let sut = SlideShowUseCase(preferenceRepo: MockPreferenceRepository<Data>.newRepo)
        try XCTUnwrap(sut.saveConfiguration(config: newConfig, forUser: HandleEntity(1)))
        let loadNewConfig = try XCTUnwrap(sut.loadConfiguration(forUser: HandleEntity(1)))
        XCTAssert(loadNewConfig == newConfig)
    }
    
    func testSlideShowLoadConfiguration_ForTwoDifferentUsers_shouldReturnDifferentConfigForDifferentUsers() async throws {
        let newConfig1 = SlideShowConfigurationEntity(playingOrder: .newest,
                                               timeIntervalForSlideInSeconds: .fast,
                                               isRepeat: true,
                                               includeSubfolders: false)

        let newConfig2 = SlideShowConfigurationEntity(playingOrder: .oldest,
                                               timeIntervalForSlideInSeconds: .slow,
                                               isRepeat: true,
                                               includeSubfolders: false)

        let sut = SlideShowUseCase(preferenceRepo: MockPreferenceRepository<Data>.newRepo)
        
        try XCTUnwrap(sut.saveConfiguration(config: newConfig1, forUser: HandleEntity(1)))
        try XCTUnwrap(sut.saveConfiguration(config: newConfig2, forUser: HandleEntity(2)))
          
        let loadNewConfig1 = try XCTUnwrap(sut.loadConfiguration(forUser: HandleEntity(1)))
        let loadNewConfig2 = try XCTUnwrap(sut.loadConfiguration(forUser: HandleEntity(2)))
        
        XCTAssert(loadNewConfig1 == newConfig1)
        XCTAssert(loadNewConfig2 == newConfig2)
    }
    
    func testSlideShowLoadConfiguration_whenNoSavedConfig_shouldLoadDefaultConfig() async throws {
        let sut = SlideShowUseCase(preferenceRepo: MockPreferenceRepository<Data>.newRepo)
        let config = try XCTUnwrap(sut.loadConfiguration(forUser: HandleEntity(1)))
        XCTAssert(config == sut.defaultConfig)
    }

}
