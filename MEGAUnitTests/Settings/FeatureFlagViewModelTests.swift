
import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

class FeatureFlagViewModelTests: XCTestCase {

    //MARK: Save New Feature Flags
    func testSaveNewFeatureFlags_oneNew() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false): false]
        let featureListWithNewFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature2", isEnabled: false)]
        
        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.savedFeatureList = savedFeatureFlagList
        
        sut.featureFlagList = featureListWithNewFeature
        sut.saveNewFeatureFlags()
        
        XCTAssertEqual(mockUseCase.savedFeatureList.count, featureListWithNewFeature.count)
    }
    
    func testSaveNewFeatureFlags_multipleNew() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false): false]
        let featureListWithNewFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature2", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature3", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature4", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.savedFeatureList = savedFeatureFlagList

        sut.featureFlagList = featureListWithNewFeature
        sut.saveNewFeatureFlags()

        XCTAssertEqual(mockUseCase.savedFeatureList.count, featureListWithNewFeature.count)
    }
    
    func testSaveNewFeatureFlags_multipleNew_withNewValue() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false): false]
        let featureListWithNewFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: true),
                                         FeatureFlagEntity(name: "Feature2", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature3", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.savedFeatureList = savedFeatureFlagList

        sut.featureFlagList = featureListWithNewFeature
        sut.saveNewFeatureFlags()

        XCTAssertEqual(mockUseCase.savedFeatureList.count, featureListWithNewFeature.count)
    }
    
    func testSaveFeatureFlag_addNewFeatureFlag() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false): false]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.savedFeatureList = savedFeatureFlagList

        sut.saveFeatureFlag(featureFlag: FeatureFlagEntity(name: "Feature2", isEnabled: true))

        XCTAssertEqual(mockUseCase.savedFeatureList.count, 2)
    }
    
    func testSaveFeatureFlag_existingFeatureFlag_updateIsEnabled() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false): false]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.savedFeatureList = savedFeatureFlagList

        sut.saveFeatureFlag(featureFlag: FeatureFlagEntity(name: "Feature1", isEnabled: true))

        XCTAssertEqual(mockUseCase.savedFeatureList.count, 1)
    }
    
    //MARK: Remove Old Feature Flags
    func testCleanSavedFeatureFlags_oneOld() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false): false,
                                    FeatureFlagEntity(name: "Feature2", isEnabled: false): false]
        let featureListWithRemovedFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.savedFeatureList = savedFeatureFlagList

        sut.featureFlagList = featureListWithRemovedFeature
        sut.cleanSavedFeatureFlags()
        
        XCTAssertEqual(mockUseCase.savedFeatureList.count, featureListWithRemovedFeature.count)
    }

    func testCleanSavedFeatureFlags_multipleOld() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false): false,
                                    FeatureFlagEntity(name: "Feature2", isEnabled: false): false,
                                    FeatureFlagEntity(name: "Feature3", isEnabled: false): false,
                                    FeatureFlagEntity(name: "Feature4", isEnabled: false): false]
        let featureListWithRemovedFeatures = [FeatureFlagEntity(name: "Feature1", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.savedFeatureList = savedFeatureFlagList

        sut.featureFlagList = featureListWithRemovedFeatures
        sut.cleanSavedFeatureFlags()
        
        XCTAssertEqual(mockUseCase.savedFeatureList.count, featureListWithRemovedFeatures.count)
    }
}
