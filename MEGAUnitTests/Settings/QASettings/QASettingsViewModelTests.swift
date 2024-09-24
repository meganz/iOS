@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class QASettingsViewModelTests: XCTestCase {
    
    @MainActor func testCheckForUpdate_whenAppDistributionError_showErrorAlert() async {
        let (sut, router, _) = makeSUT(appDistributionResult: .failure(NSError()))
        
        let task = sut.checkForUpdate()
        await task?.value
        
        XCTAssertEqual(router.showErrorAlertCallCount, 1)
    }
    
    @MainActor func testCheckForUpdate_whenNoNewRelease_doesNotShowAlert() async {
        let (sut, router, _) = makeSUT(appDistributionResult: .success(nil))
        
        let task = sut.checkForUpdate()
        await task?.value
        
        XCTAssertEqual(router.showAlertCallCount, 0)
        XCTAssertEqual(router.showErrorAlertCallCount, 0)
    }
    
    // MARK: - Helpers
    
    @MainActor private func makeSUT(
        appDistributionResult: Result<AppDistributionReleaseEntity?, any Error> = .failure(NSError()),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: QASettingsViewModel, router: MockRouter, appDistributionUseCase: MockAppDistributionUseCase) {
        let appDistributionUseCase = MockAppDistributionUseCase(result: appDistributionResult)
        let router = MockRouter()
        let sut = QASettingsViewModel(
            router: router,
            appDistributionUseCase: appDistributionUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, router, appDistributionUseCase)
    }
    
    private final class MockRouter: QASettingsRouting {
        private(set) var showAlertCallCount = 0
        private(set) var showErrorAlertCallCount = 0
        
        func showAlert(withTitle title: String, message: String, actions: [UIAlertAction]) {
            showAlertCallCount += 1
        }
        
        func showAlert(withError error: any Error) {
            showErrorAlertCallCount += 1
        }
    }

}
