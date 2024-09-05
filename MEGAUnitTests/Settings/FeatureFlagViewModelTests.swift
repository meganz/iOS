@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

class FeatureFlagViewModelTests: XCTestCase {

    // MARK: Save New Feature Flags
    func testSaveNewFeatureFlags_oneNew() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false)]
        let featureListWithNewFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature2", isEnabled: false)]
        
        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.$savedFeatureList.mutate { $0 = savedFeatureFlagList }
        
        sut.featureFlagList = featureListWithNewFeature
        sut.saveNewFeatureFlags()
        
        XCTAssertEqual(Set(mockUseCase.savedFeatureList), Set(featureListWithNewFeature))
    }
    
    func testSaveNewFeatureFlags_multipleNew() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false)]
        let featureListWithNewFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature2", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature3", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature4", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.$savedFeatureList.mutate { $0 = savedFeatureFlagList }

        sut.featureFlagList = featureListWithNewFeature
        sut.saveNewFeatureFlags()

        XCTAssertEqual(Set(mockUseCase.savedFeatureList), Set(featureListWithNewFeature))
    }
    
    func testSaveNewFeatureFlags_multipleNew_withNewValue() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false)]
        let featureListWithNewFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: true),
                                         FeatureFlagEntity(name: "Feature2", isEnabled: false),
                                         FeatureFlagEntity(name: "Feature3", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.$savedFeatureList.mutate { $0 = savedFeatureFlagList }

        sut.featureFlagList = featureListWithNewFeature
        sut.saveNewFeatureFlags()

        XCTAssertEqual(Set(mockUseCase.savedFeatureList.map(\.name)), Set(featureListWithNewFeature.map(\.name)))
    }
    
    func testSaveFeatureFlag_addNewFeatureFlag() {
        let savedFeature = FeatureFlagEntity(name: "Feature1", isEnabled: false)
        let newFeature = FeatureFlagEntity(name: "Feature2", isEnabled: true)
        
        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.$savedFeatureList.mutate { $0 = [savedFeature] }

        sut.saveFeatureFlag(featureFlag: newFeature)

        XCTAssertEqual(Set(mockUseCase.savedFeatureList), Set([savedFeature, newFeature]))
    }
    
    func testSaveFeatureFlag_existingFeatureFlag_updateIsEnabled() {
        let existingFeature = FeatureFlagEntity(name: "Feature1", isEnabled: false)
        let updatedExistingFeature = FeatureFlagEntity(name: "Feature1", isEnabled: true)
        
        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.$savedFeatureList.mutate { $0 = [existingFeature] }

        sut.saveFeatureFlag(featureFlag: FeatureFlagEntity(name: "Feature1", isEnabled: true))

        XCTAssertEqual(Set(mockUseCase.savedFeatureList), Set([updatedExistingFeature]))
    }
    
    // MARK: Remove Old Feature Flags
    func testCleanSavedFeatureFlags_oneOld() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false),
                                    FeatureFlagEntity(name: "Feature2", isEnabled: false)]
        let featureListWithRemovedFeature = [FeatureFlagEntity(name: "Feature1", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.$savedFeatureList.mutate { $0 = savedFeatureFlagList }

        sut.featureFlagList = featureListWithRemovedFeature
        sut.cleanSavedFeatureFlags()
        
        XCTAssertEqual(Set(mockUseCase.savedFeatureList), Set(featureListWithRemovedFeature))
    }

    func testCleanSavedFeatureFlags_multipleOld() {
        let savedFeatureFlagList = [FeatureFlagEntity(name: "Feature1", isEnabled: false),
                                    FeatureFlagEntity(name: "Feature2", isEnabled: false),
                                    FeatureFlagEntity(name: "Feature3", isEnabled: false),
                                    FeatureFlagEntity(name: "Feature4", isEnabled: false)]
        let featureListWithRemovedFeatures = [FeatureFlagEntity(name: "Feature1", isEnabled: false)]

        let mockUseCase = MockFeatureFlagUseCase()
        let sut = FeatureFlagViewModel(useCase: mockUseCase)
        mockUseCase.$savedFeatureList.mutate { $0 = savedFeatureFlagList }

        sut.featureFlagList = featureListWithRemovedFeatures
        sut.cleanSavedFeatureFlags()
        
        XCTAssertEqual(Set(mockUseCase.savedFeatureList), Set(featureListWithRemovedFeatures))
    }
}
