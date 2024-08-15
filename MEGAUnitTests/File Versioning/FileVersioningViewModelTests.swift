@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class FileVersioningViewModelTests: XCTestCase {
    let mockRouter = MockFileVersioningViewRouter()
    
    @MainActor func testAction_onViewLoaded() {
        let fileVersionsUseCase = MockFileVersionsUseCase(versions: 4,
                                                          versionsSize: 360000,
                                                          isFileVersionsEnabled: .success(true))
        let sut = FileVersioningViewModel(router: mockRouter,
                                          fileVersionsUseCase: fileVersionsUseCase,
                                          accountUseCase: MockAccountUseCase())
        
        test(viewModel: sut,
             action: .onViewLoaded,
             expectedCommands: [.updateSwitch(true), .updateFileVersions(4), .updateFileVersionsSize(360000)])
    }
    
    @MainActor func testAction_enableFileVersions() {
        let fileVersionsUseCase = MockFileVersionsUseCase(isFileVersionsEnabled: .success(false), enableFileVersions: .success(true))
        let sut = FileVersioningViewModel(router: mockRouter,
                                          fileVersionsUseCase: fileVersionsUseCase,
                                          accountUseCase: MockAccountUseCase())
        
        test(viewModel: sut,
             action: .enableFileVersions,
             expectedCommands: [.updateSwitch(true)])
    }
    
    @MainActor func testAction_disableFileVersions_user_taps_yes_in_the_alert() {
        let fileVersionsUseCase = MockFileVersionsUseCase(isFileVersionsEnabled: .success(true),
                                                          enableFileVersions: .success(false))
        let sut = FileVersioningViewModel(router: mockRouter,
                                          fileVersionsUseCase: fileVersionsUseCase,
                                          accountUseCase: MockAccountUseCase())
        
        test(viewModel: sut,
             action: .disableFileVersions,
             expectedCommands: [.updateSwitch(false)])
        XCTAssertEqual(mockRouter.showDisableAlert_calledTimes, 1)
    }
    
    @MainActor func testAction_disableFileVersions_user_taps_no_in_the_alert() {
        let fileVersionsUseCase = MockFileVersionsUseCase(isFileVersionsEnabled: .success(true))
        mockRouter.tapYesDisableAlert = false
        let sut = FileVersioningViewModel(router: mockRouter,
                                          fileVersionsUseCase: fileVersionsUseCase,
                                          accountUseCase: MockAccountUseCase())
        
        test(viewModel: sut,
             action: .disableFileVersions,
             expectedCommands: [.updateSwitch(true)])
        XCTAssertEqual(mockRouter.showDisableAlert_calledTimes, 1)
    }
    
    @MainActor func testAction_deletePreviousVersions_user_taps_yes_in_the_alert() {
        let fileVersionsUseCase = MockFileVersionsUseCase(isFileVersionsEnabled: .success(true),
                                                          deletePreviousFileVersions: .success(true))
        let sut = FileVersioningViewModel(router: mockRouter,
                                          fileVersionsUseCase: fileVersionsUseCase,
                                          accountUseCase: MockAccountUseCase(accountDetailsResult: .success(AccountDetailsEntity.build())))
        
        test(viewModel: sut,
             action: .deletePreviousVersions,
             expectedCommands: [.updateFileVersions(0), .updateFileVersionsSize(0)])
        XCTAssertEqual(mockRouter.showDeletePreviousVersionsAlert_calledTimes, 1)
    }
    
    @MainActor func testAction_deletePreviousVersions_user_taps_no_in_the_alert() {
        mockRouter.tapYesDeletePreviousVersionsAlert = false
        let fileVersionsUseCase = MockFileVersionsUseCase(isFileVersionsEnabled: .success(true))
        let sut = FileVersioningViewModel(router: mockRouter,
                                          fileVersionsUseCase: fileVersionsUseCase,
                                          accountUseCase: MockAccountUseCase())
        
        test(viewModel: sut,
             action: .deletePreviousVersions,
             expectedCommands: [])
        XCTAssertEqual(mockRouter.showDeletePreviousVersionsAlert_calledTimes, 1)
    }
}

final class MockFileVersioningViewRouter: FileVersioningViewRouting {
    var showDisableAlert_calledTimes = 0
    var showDeletePreviousVersionsAlert_calledTimes = 0
    var tapYesDisableAlert = true
    var tapYesDeletePreviousVersionsAlert = true
    
    func showDisableAlert(completion: @escaping (Bool) -> Void) {
        completion(tapYesDisableAlert)
        showDisableAlert_calledTimes += 1
    }
    
    func showDeletePreviousVersionsAlert(completion: @escaping (Bool) -> Void) {
        completion(tapYesDeletePreviousVersionsAlert)
        showDeletePreviousVersionsAlert_calledTimes += 1
    }
}
