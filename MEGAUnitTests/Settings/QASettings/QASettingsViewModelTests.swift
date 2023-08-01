@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class QASettingsViewModelTests: XCTestCase {
    
    func testFingerprintVerificationFlagStatus_doesNotAlterStatus() {
        let (sut, _, _, _) = makeSUT()
        
        let status = sut.fingerprintVerificationFlagStatus()
        
        XCTAssertEqual(status, "enabled")
    }
    
    func testCheckForUpdate_whenAppDistributionError_showErrorAlert() async {
        let (sut, router, _, _) = makeSUT(appDistributionResult: .failure(NSError()))
        
        let task = sut.checkForUpdate()
        await task?.value
        
        XCTAssertEqual(router.showErrorAlertCallCount, 1)
    }
    
    func testCheckForUpdate_whenNoNewRelease_doesNotShowAlert() async {
        let (sut, router, _, _) = makeSUT(appDistributionResult: .success(nil))
        
        let task = sut.checkForUpdate()
        await task?.value
        
        XCTAssertEqual(router.showAlertCallCount, 0)
        XCTAssertEqual(router.showErrorAlertCallCount, 0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        appDistributionResult: Result<AppDistributionReleaseEntity?, Error> = .failure(NSError()),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: QASettingsViewModel, router: MockRouter, fingerprintUseCase: MockFingerprintUseCase, appDistributionUseCase: MockAppDistributionUseCase) {
        let appDistributionUseCase = MockAppDistributionUseCase(result: appDistributionResult)
        let router = MockRouter()
        let fingerprintUseCase = MockFingerprintUseCase()
        let sut = QASettingsViewModel(
            router: router,
            fingerprintUseCase: fingerprintUseCase,
            appDistributionUseCase: appDistributionUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, router, fingerprintUseCase, appDistributionUseCase)
    }
    
    private final class MockRouter: QASettingsRouting {
        private(set) var showAlertCallCount = 0
        private(set) var showErrorAlertCallCount = 0
        
        func showAlert(withTitle title: String, message: String, actions: [UIAlertAction]) {
            showAlertCallCount += 1
        }
        
        func showAlert(withError error: Error) {
            showErrorAlertCallCount += 1
        }
        
    }

}
