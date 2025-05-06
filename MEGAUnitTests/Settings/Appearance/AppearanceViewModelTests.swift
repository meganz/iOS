@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPreference
import XCTest

final class AppearanceViewModelTests: XCTestCase {
    @MainActor
    func testAutoMediaDiscoverySetting_noPreferenceSet_shouldDefaultToTrue() async {
        let sut = makeSUT()
        let result = await sut.fetchSettingValue(for: .autoMediaDiscoverySetting)
        XCTAssertTrue(result)
    }
    
    @MainActor
    func testAutoMediaDiscoverySetting_preferenceSet_shouldSetToValue() async {
        let preferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.shouldDisplayMediaDiscoveryWhenMediaOnly.rawValue: false])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        let result = await sut.fetchSettingValue(for: .autoMediaDiscoverySetting)
        XCTAssertFalse(result)
    }
    
    @MainActor
    func testFetchSettingValue_expectSetValue() async {
        let useCase = MockContentConsumptionUserAttributeUseCase(
            sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))
        let sut = makeSUT(contentConsumptionUserAttributeUseCase: useCase)
        let result = await sut.fetchSettingValue(for: .showHiddenItems)
        XCTAssertFalse(result)
    }
    
    @MainActor
    func testAutoMediaDiscoverySetting_onValueChange_shouldChangePreference() throws {
        let preferenceUseCase = MockPreferenceUseCase(dict: [:])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        sut.saveSetting(for: .autoMediaDiscoverySetting(false))
        
        let changedPreference = try XCTUnwrap(preferenceUseCase.dict[PreferenceKeyEntity.shouldDisplayMediaDiscoveryWhenMediaOnly.rawValue] as? Bool)
        XCTAssertFalse(changedPreference)
    }
    
    @MainActor
    func testMediaDiscoveryShouldIncludeSubfolderSetting_noPreferenceSet_shouldDefaultToTrue() async {
        let sut = makeSUT()
        let result = await sut.fetchSettingValue(for: .mediaDiscoveryShouldIncludeSubfolderSetting)
        XCTAssertTrue(result)
    }
    
    @MainActor
    func testMediaDiscoveryShouldIncludeSubfolderSetting_preferenceSet_shouldSetToValue() async {
        let preferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.mediaDiscoveryShouldIncludeSubfolderMedia.rawValue: false])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        let result = await sut.fetchSettingValue(for: .mediaDiscoveryShouldIncludeSubfolderSetting)

        XCTAssertFalse(result)
    }
    
    func testMediaDiscoveryShouldIncludeSubfolderSetting_onValueChange_shouldChangePreference() throws {
        let preferenceUseCase = MockPreferenceUseCase(dict: [:])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        
        sut.saveSetting(for: .mediaDiscoveryShouldIncludeSubfolderSetting(false))
        
        let changedPreference = try XCTUnwrap(preferenceUseCase.dict[PreferenceKeyEntity.mediaDiscoveryShouldIncludeSubfolderMedia.rawValue] as? Bool)
        XCTAssertFalse(changedPreference)
    }
    
    func testMediaDiscoveryHelpLink_shouldBeCorrect() {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.mediaDiscoveryHelpLink, URL(string: "https://help.mega.io/files-folders/view-move/media-discovery-view-gallery"))
    }
    
    func testIsAppearanceSectionVisible_ForInvalidAccountAndHiddenNodesFlagEnabled_shouldReturnCorrectResults() {
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]))
        
        let expectedResult: [(AppearanceSection, Bool)] = [
            (.launch, true),
            (.layout, true),
            (.hiddenItems, false),
            (.mediaDiscovery, true),
            (.mediaDiscoverySubfolder, true),
            (.recents, true),
            (.appIcon, true)
        ]
        
        expectedResult.forEach { section, result in
            let isAppearanceSectionVisible = sut.isAppearanceSectionVisible(section: section)
            XCTAssertEqual(isAppearanceSectionVisible, result, "AppearanceSection.\(section) should be \(result)")
        }
    }
    
    func testIsAppearanceSectionVisible_ForInvalidAccountAndHiddenNodesFlagDisabled_shouldReturnCorrectResults() {
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]))
        
        let expectedResult: [(AppearanceSection, Bool)] = [
            (.launch, true),
            (.layout, true),
            (.hiddenItems, false),
            (.mediaDiscovery, true),
            (.mediaDiscoverySubfolder, true),
            (.recents, true),
            (.appIcon, true)
        ]
        
        expectedResult.forEach { section, result in
            let isAppearanceSectionVisible = sut.isAppearanceSectionVisible(section: section)
            XCTAssertEqual(isAppearanceSectionVisible, result, "AppearanceSection.\(section) should be \(result)")
        }
    }
    
    func testIsAppearanceSectionVisible_ForValidAccountAndHiddenNodesFlagEnabled_shouldReturnCorrectResults() {
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]))
        
        let expectedResult: [(AppearanceSection, Bool)] = [
            (.launch, true),
            (.layout, true),
            (.hiddenItems, true),
            (.mediaDiscovery, true),
            (.mediaDiscoverySubfolder, true),
            (.recents, true),
            (.appIcon, true)
        ]
        
        expectedResult.forEach { section, result in
            let isAppearanceSectionVisible = sut.isAppearanceSectionVisible(section: section)
            XCTAssertEqual(isAppearanceSectionVisible, result, "AppearanceSection.\(section) should be \(result)")
        }
    }
    
    func testIsAppearanceSectionVisible_ForValidAccountAndHiddenNodesFlagDisabled_shouldReturnCorrectResults() {
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]))
        
        let expectedResult: [(AppearanceSection, Bool)] = [
            (.launch, true),
            (.layout, true),
            (.hiddenItems, false),
            (.mediaDiscovery, true),
            (.mediaDiscoverySubfolder, true),
            (.recents, true),
            (.appIcon, true)
        ]
        
        expectedResult.forEach { section, result in
            let isAppearanceSectionVisible = sut.isAppearanceSectionVisible(section: section)
            XCTAssertEqual(isAppearanceSectionVisible, result, "AppearanceSection.\(section) should be \(result)")
        }
    }
    
    func testSaveSetting_forAutoMediaDiscoverySetting_shouldSetSavedValue() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [:])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        sut.saveSetting(for: .autoMediaDiscoverySetting(true))
        XCTAssertTrue(preferenceUseCase[PreferenceKeyEntity.shouldDisplayMediaDiscoveryWhenMediaOnly.rawValue] ?? false)
    }
    
    func testSaveSetting_forMediaDiscoveryShouldIncludeSubfolderSetting_shouldSetSavedValue() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [:])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        sut.saveSetting(for: .mediaDiscoveryShouldIncludeSubfolderSetting(true))
        XCTAssertTrue(preferenceUseCase[PreferenceKeyEntity.mediaDiscoveryShouldIncludeSubfolderMedia.rawValue] ?? false)
    }
    
    func testSaveSetting_forShowHiddenNodes_shouldSetSavedValue() async {
        let useCase = MockContentConsumptionUserAttributeUseCase(
            sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))
        let sut = makeSUT(contentConsumptionUserAttributeUseCase: useCase)
        
        let exp = expectation(description: "Expect sensitiveAttributeChanged to be emitted")
        let subscription = useCase
            .$sensitiveAttributeChanged
            .first(where: \.showHiddenNodes)
            .sink { result in
                XCTAssertTrue(result.showHiddenNodes)
                exp.fulfill()
            }
        
        sut.saveSetting(for: .showHiddenItems(true))
        
        await fulfillment(of: [exp], timeout: 1)
        subscription.cancel()
    }
    
    private func makeSUT(
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [:]),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]),
        file: StaticString = #file,
        line: UInt = #line) -> AppearanceViewModel {
            let sut = AppearanceViewModel(
                preferenceUseCase: preferenceUseCase,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase
            )
            trackForMemoryLeaks(on: sut, file: file, line: line)
            return sut
        }
}
