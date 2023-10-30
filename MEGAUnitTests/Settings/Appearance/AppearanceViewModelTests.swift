@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class AppearanceViewModelTests: XCTestCase {
    func testAutoMediaDiscoverySetting_noPreferenceSet_shouldDefaultToTrue() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.autoMediaDiscoverySetting)
    }
    
    func testAutoMediaDiscoverySetting_preferenceSet_shouldSetToValue() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: false])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        XCTAssertFalse(sut.autoMediaDiscoverySetting)
    }
    
    func testAutoMediaDiscoverySetting_onValueChange_shouldChangePreference() throws {
        let preferenceUseCase = MockPreferenceUseCase(dict: [:])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        sut.autoMediaDiscoverySetting = false
        
        let changedPreference = try XCTUnwrap(preferenceUseCase.dict[.shouldDisplayMediaDiscoveryWhenMediaOnly] as? Bool)
        XCTAssertFalse(changedPreference)
    }
    
    func testMediaDiscoveryShouldIncludeSubfolderSetting_noPreferenceSet_shouldDefaultToTrue() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.mediaDiscoveryShouldIncludeSubfolderSetting)
    }
    
    func testMediaDiscoveryShouldIncludeSubfolderSetting_preferenceSet_shouldSetToValue() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.mediaDiscoveryShouldIncludeSubfolderMedia: false])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        XCTAssertFalse(sut.mediaDiscoveryShouldIncludeSubfolderSetting)
    }
    
    func testMediaDiscoveryShouldIncludeSubfolderSetting_onValueChange_shouldChangePreference() throws {
        let preferenceUseCase = MockPreferenceUseCase(dict: [:])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        sut.mediaDiscoveryShouldIncludeSubfolderSetting = false
        
        let changedPreference = try XCTUnwrap(preferenceUseCase.dict[.mediaDiscoveryShouldIncludeSubfolderMedia] as? Bool)
        XCTAssertFalse(changedPreference)
    }
    
    func testMediaDiscoveryHelpLink_shouldBeCorrect() {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.mediaDiscoveryHelpLink, URL(string: "https://help.mega.io/files-folders/view-move/media-discovery-view-gallery"))
    }
    
    private func makeSUT(
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [:]),
        file: StaticString = #file,
        line: UInt = #line) -> AppearanceViewModel {
            let sut = AppearanceViewModel(preferenceUseCase: preferenceUseCase)
            trackForMemoryLeaks(on: sut, file: file, line: line)
            return sut
        }
}
