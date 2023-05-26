import XCTest
import MEGADomain
import MEGADomainMock

final class FeatureFlagUseCaseTests: XCTestCase {
    
    func testSavedFeatureFlagList() throws {
        let testData = [FeatureFlagEntity(name: "Feature1", isEnabled: false),
                        FeatureFlagEntity(name: "Feature2", isEnabled: false)]
        
        let repo = MockFeatureFlagRepository(featureList: testData)
        let sut = FeatureFlagUseCase(repository: repo)
        
        let expectedResult = ["Feature1", "Feature2"]
        let savedFeatureFlags = sut.savedFeatureFlags().map { $0.name }
        
        XCTAssertEqual(Set(expectedResult), Set(savedFeatureFlags))
    }
    
    func testIsFeatureFlagEnabled_true() {
        let repo = MockFeatureFlagRepository(isFeatureFlagEnabled: true)
        let sut = FeatureFlagUseCase(repository: repo)
        
        XCTAssertTrue(sut.isFeatureFlagEnabled(for: "Feature1"))
    }
    
    func testIsFeatureFlagEnabled_false() {
        let repo = MockFeatureFlagRepository(isFeatureFlagEnabled: false)
        let sut = FeatureFlagUseCase(repository: repo)
        
        XCTAssertFalse(sut.isFeatureFlagEnabled(for: "Feature1"))
    }
}
