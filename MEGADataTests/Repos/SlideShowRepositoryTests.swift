import MEGADomain
import XCTest
@testable import MEGA

final class SlideShowRepositoryTests: XCTestCase {
    let defaultConfig = SlideShowConfigurationEntity(
        playingOrder: .shuffled,
        timeIntervalForSlideInSeconds: .normal,
        isRepeat: false,
        includeSubfolders: false
    )
    
    private func removePreferenceSettings() {
        UserDefaults.standard.removeObject(forKey: PreferenceKeyEntity.slideShowConfigPlayingOrder.rawValue)
        UserDefaults.standard.removeObject(forKey: PreferenceKeyEntity.slideShowConfigTimeInterval.rawValue)
        UserDefaults.standard.removeObject(forKey: PreferenceKeyEntity.slideShowConfigIsRepeat.rawValue)
        UserDefaults.standard.removeObject(forKey: PreferenceKeyEntity.slideShowConfigIncludeSubfolder.rawValue)
    }
    
    override func tearDownWithError() throws {
        removePreferenceSettings()
    }
    
    func testSlideShowSaveConfiguration_whenSavingConfiguration_shouldReturnSavedConfig() throws {
        let newConfig = SlideShowConfigurationEntity(
            playingOrder: .newest,
            timeIntervalForSlideInSeconds: .slow,
            isRepeat: true,
            includeSubfolders: false
        )
        
        removePreferenceSettings()
        let sut = SlideShowRepository.newRepo
        sut.saveConfiguration(newConfig)
        XCTAssert(sut.loadConfiguration() == newConfig)
    }
    
    func testSlideShowLoadConfiguration_whenLoadingConfiguration_shouldReturnDefaultConfig() throws {
        removePreferenceSettings()
        let sut = SlideShowRepository.newRepo
        XCTAssert(sut.loadConfiguration() == defaultConfig)
    }
    
    func testSlideShowLoadConfiguration_whenLoadingConfiguration_shouldReturnSavedConfig() throws {
        removePreferenceSettings()
        
        let newConfig1 = SlideShowConfigurationEntity(
            playingOrder: .newest,
            timeIntervalForSlideInSeconds: .slow,
            isRepeat: true,
            includeSubfolders: false
        )
        
        let newConfig2 = SlideShowConfigurationEntity(
            playingOrder: .oldest,
            timeIntervalForSlideInSeconds: .slow,
            isRepeat: false,
            includeSubfolders: true
        )
        
        let sut = SlideShowRepository.newRepo
        
        sut.saveConfiguration(newConfig1)
        XCTAssert(sut.loadConfiguration() == newConfig1)
        
        sut.saveConfiguration(newConfig2)
        XCTAssert(sut.loadConfiguration() == newConfig2)
    }
}
