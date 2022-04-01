import XCTest
@testable import MEGA

final class WarningViewModelTests: XCTestCase {

    func test_noInternetConnection() {
        let viewModel = WarningViewModel(warningType: .noInternetConnection)
        XCTAssertEqual(viewModel.warningType.description, Strings.Localizable.General.noIntenerConnection)
    }
    
    func test_limitedPhotoAccess() {
        let viewModel = WarningViewModel(warningType: .limitedPhotoAccess)
        XCTAssertEqual(viewModel.warningType.description, Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage)
    }
    
    
    func test_limitedPhotoAccess_tapAction() {
        let mockRouter = MockWarningViewRouter()
        let viewModel = WarningViewModel(warningType: .limitedPhotoAccess, router: mockRouter)
        viewModel.tapAction()
        XCTAssertEqual(mockRouter.goToSettings_calledTimes, 1)
    }
}

final class MockWarningViewRouter: WarningViewRouting {
    var goToSettings_calledTimes = 0
    
    func goToSettings() {
        goToSettings_calledTimes += 1
    }
}
