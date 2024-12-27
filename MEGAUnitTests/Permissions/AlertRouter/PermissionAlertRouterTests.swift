@testable import MEGA
import MEGAPermissions
import MEGAPermissionsMock
import XCTest

final class PermissionAlertRouterTests: XCTestCase {
    class Harness {
        let sut: PermissionAlertRouter
        let presenter: (PermissionsModalModel) -> Void
        // plug in to know when the presenter is called
        var presenterCallback: (() -> Void)?
        let settingsOpener: () -> Void
        let notificationRegisterer: () -> Void
        let deviceHandler: MockDevicePermissionHandler
        
        var presentedModals: [PermissionsModalModel] = []
        var settingsOpenedCount = 0
        var registerNotificationCallCount = 0
        weak var testcase: XCTestCase?
        
        init(_ testcase: XCTestCase) {
            self.testcase = testcase
            
            var presenterBlock: (PermissionsModalModel) -> Void = { _ in }
            
            presenter = { presenterBlock($0) }
            
            var settingsBlock: () -> Void = {}
            
            settingsOpener = { settingsBlock() }
            
            var notificationBlock = {}
            
            notificationRegisterer = {
                notificationBlock()
            }
            
            deviceHandler = MockDevicePermissionHandler()
            
            sut = .init(
                modalPresenter: presenter,
                settingsOpener: settingsOpener,
                notificationRegisterer: notificationRegisterer,
                deviceHandler: deviceHandler
            )
            presenterBlock = { [unowned self] in
                self.presenterCallback?()
                self.presentedModals.append($0)
            }
            
            settingsBlock = { [unowned self] in
                self.settingsOpenedCount += 1
            }
            
            notificationBlock = { [unowned self] in
                registerNotificationCallCount += 1
            }
        }
        
        var lastPresentedCustomModalModel: CustomModalModel? {
            
            guard
                let alert = presentedModals.last,
                case .custom(let customModalModel) = alert
            else {
                return nil
            }
            return customModalModel
        }
        
        var lastPresentedModalAlert: AlertModel? {
            
            guard
                let alert = presentedModals.last,
                case .alert(let alertModel) = alert
            else {
                return nil
            }
            return alertModel
        }
        
        @MainActor
        func callAudioPermissions(modal: Bool, incomingCall: Bool) {
            let exp = testcase!.expectation(description: "testExpectation_callAudioPermissions")
            sut.audioPermission(modal: modal, incomingCall: incomingCall, completion: { _ in
                exp.fulfill()
            })
            testcase!.wait(for: [exp])
        }
    }
    
    @MainActor
    func testAlertVideoPermission_onCall_asksPresenterToShowAlert() throws {
        let harness = Harness(self)
        harness.sut.alertVideoPermission()
        XCTAssert(harness.presentedModals.count == 1)
        XCTAssertNotNil(harness.lastPresentedModalAlert)
    }
    
    @MainActor
    func testAlertVideoPermission_tappingSecondAlertButton_opensSettings() throws {
        let harness = Harness(self)
        harness.sut.alertVideoPermission()
        let alertModel = try XCTUnwrap(harness.lastPresentedModalAlert)
        alertModel.actions[1].handler()
        XCTAssertEqual(harness.settingsOpenedCount, 1)
    }
    
    @MainActor
    func testAlertVideoPermission_tappingFirstAlertButton_doesNotOpenSettings() throws {
        let harness = Harness(self)
        harness.sut.alertVideoPermission()
        let alertModel = try XCTUnwrap(harness.lastPresentedModalAlert)
        alertModel.actions[0].handler()
        XCTAssertEqual(harness.settingsOpenedCount, 0)
    }
    
    @MainActor
    func testAlertPhotosPermission_onCall_asksPresenterToShowCorrectAlert() throws {
        let harness = Harness(self)
        harness.sut.alertPhotosPermission()
        XCTAssert(harness.presentedModals.count == 1)
        let alert = try XCTUnwrap(harness.lastPresentedModalAlert)
        XCTAssertEqual(alert, .photo(completion: {}))
    }
    
    @MainActor
    func testAlertPhotosPermission_tappingSecondAlertButton_opensSettings() throws {
        let harness = Harness(self)
        harness.sut.alertPhotosPermission()
        let alertModel = try XCTUnwrap(harness.lastPresentedModalAlert)
        alertModel.actions[1].handler()
        XCTAssertEqual(harness.settingsOpenedCount, 1)
    }
    
    @MainActor
    func testAlertPhotosPermission_tappingFirstAlertButton_doesNotOpenSettings() throws {
        let harness = Harness(self)
        harness.sut.alertPhotosPermission()
        let alertModel = try XCTUnwrap(harness.lastPresentedModalAlert)
        alertModel.actions[0].handler()
        XCTAssertEqual(harness.settingsOpenedCount, 0)
    }
    
    @MainActor
    func testAlertAudioModalPermission_nonModal_shouldNotAskPermission_presentsDevicePermission() throws {
        let harness = Harness(self)
        harness.deviceHandler.shouldAskForAudioPermissions = false
        harness.deviceHandler.requestMediaPermissionValuesToReturn[.audio] = true
        harness.callAudioPermissions(modal: false, incomingCall: false)
        XCTAssertEqual(harness.deviceHandler.requestPermissionsMediaTypes, [.audio])
    }
    
    @MainActor
    func testAlertAudioModalPermission_modal_shouldAskPermission_presentsCustomModal() throws {
        let harness = Harness(self)
        harness.deviceHandler.shouldAskForAudioPermissions = true
        harness.deviceHandler.requestMediaPermissionValuesToReturn[.audio] = true
        harness.sut.audioPermission(modal: true, incomingCall: false)
        XCTAssertNotNil(harness.lastPresentedCustomModalModel)
    }
    
    @MainActor
    func testRequestPermissionsForAudioCall_whenDenied_showAlert_doesNotCallGranted() throws {
        let harness = Harness(self)
        var grantedCalled = false
        harness.deviceHandler.shouldAskForAudioPermissions = true
        harness.sut.requestPermissionsFor(
            videoCall: false,
            granted: { grantedCalled = true }
        )
        
        let customModal = try XCTUnwrap(harness.lastPresentedCustomModalModel)
        XCTAssertEqual(customModal, .audioCall(incomingCall: false, completion: {_ in }))
        harness.deviceHandler.requestMediaPermissionValuesToReturn[.audio] = false
        let exp = expectation(description: "presentedCalled")
        harness.presenterCallback = {
            exp.fulfill()
        }

        customModal.firstCompletion(Dismisser(closure: {}))
        // wait for next presenter callback
        wait(for: [exp])
        let alert = try XCTUnwrap(harness.lastPresentedModalAlert)
        XCTAssertEqual(alert, .audio(incomingCall: false, completion: {}))
        XCTAssertFalse(grantedCalled)
    }
    
    @MainActor
    func testRequestPermissionsForAudioCall_whenApproved_doesCallGranted() throws {
        let harness = Harness(self)
        harness.deviceHandler.shouldAskForAudioPermissions = true
        let exp = expectation(description: "presentedCalled")
        harness.sut.requestPermissionsFor(
            videoCall: false,
            granted: {
                exp.fulfill()
            }
        )
        
        let customModal = try XCTUnwrap(harness.lastPresentedCustomModalModel)
        XCTAssertEqual(customModal, .audioCall(incomingCall: false, completion: {_ in }))
        harness.deviceHandler.requestMediaPermissionValuesToReturn[.audio] = true
        
        harness.presenterCallback = {
            exp.fulfill()
        }
        
        customModal.firstCompletion(Dismisser(closure: {}))
        // wait for next presenter callback
        wait(for: [exp])
    }
}
