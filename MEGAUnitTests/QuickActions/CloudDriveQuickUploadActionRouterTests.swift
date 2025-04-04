@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

final class CloudDriveQuickUploadActionRouterTests: XCTestCase {
    func testBuild_cannotCreateContextMenuConfig_shouldNotReturnActionSheet() {
        // given
        let createContextMenuUseCase = MockCreateContextMenuUseCase(contextMenuEntity: nil)
        
        let sut = makeSUT(createContextMenuUseCase: createContextMenuUseCase)
        
        // when
        let vc = sut.build()
        
        // then
        XCTAssertNil(vc)
    }
    
    func testBuild_canCreateContextMenuConfig_shouldReturnActionSheet() {
        // given
        let action1 = CMActionEntity(type: .uploadAdd(actionType: .newFolder), isEnabled: true, state: .on)
        let action2 = CMActionEntity(type: .uploadAdd(actionType: .newTextFile), isEnabled: true, state: .on)
        
        let cmEntity = CMEntity(children: [action1, action2])
        let createContextMenuUseCase = MockCreateContextMenuUseCase(contextMenuEntity: cmEntity)
        
        let sut = makeSUT(createContextMenuUseCase: createContextMenuUseCase)
        
        // when
        let vc = sut.build() as? ActionSheetViewController
        
        // then
        XCTAssertNotNil(vc)
        let outputActions = vc?.actions.compactMap { $0 as? ContextActionSheetAction }
            
        XCTAssertEqual(outputActions?.map(\.title), ["New folder", "New text file"])
    }
    
    func testStart() {
        // given
        let navigationVC = MockNavigationController()
        let sut = makeSUT(navigationController: navigationVC)
        
        // when
        sut.start()
        
        // then
        switch navigationVC.messages.first {
        case .present(let vc):
            XCTAssertTrue(vc is ActionSheetViewController)
        case .none:
            XCTFail("ActionSheetViewController should have been presented")
        }
    }
    
    func makeSUT(
        navigationController: UINavigationController = MockNavigationController(),
        uploadAddMenuDelegateHandler: MockUploadAddMenuDelegate = .init(),
        createContextMenuUseCase: MockCreateContextMenuUseCase = .init(),
        viewModeProvider: @escaping () -> ViewModePreferenceEntity? = { .list }
    ) -> CloudDriveQuickUploadActionRouter {
        let contextMenuManager = ContextMenuManager(
            uploadAddMenuDelegate: uploadAddMenuDelegateHandler,
            createContextMenuUseCase: createContextMenuUseCase)
        return .init(
            navigationController: navigationController,
            uploadAddMenuDelegateHandler: uploadAddMenuDelegateHandler,
            contextMenuManager: contextMenuManager,
            viewModeProvider: viewModeProvider
        )
    }
}

final class MockUploadAddMenuDelegate: UploadAddMenuDelegate {
    func uploadAddMenu(didSelect action: MEGADomain.UploadAddActionEntity) {
        
    }
}
