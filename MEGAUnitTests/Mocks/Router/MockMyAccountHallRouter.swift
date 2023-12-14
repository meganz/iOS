import DeviceCenter
@testable import MEGA
import MEGADomain

final class MockMyAccountHallRouter: MyAccountHallRouting {
    var navigateToDeviceCenter_calledTimes = 0
    var didTapCameraUploadsAction_calledTimes = 0
    var didTapRenameAction_calledTimes = 0
    var didTapNodeAction_calledTimes = 0
    
    func navigateToDeviceCenter(deviceCenterBridge: DeviceCenterBridge, deviceCenterAssets: DeviceCenterAssets) {
        navigateToDeviceCenter_calledTimes += 1
    }
    
    func didTapCameraUploadsAction(statusChanged: @escaping () -> Void) {
        didTapCameraUploadsAction_calledTimes += 1
    }
    
    func didTapRenameAction(_ renameEntity: RenameActionEntity) {
        didTapRenameAction_calledTimes += 1
    }
    
    func didTapNodeAction(type: DeviceCenterActionType, node: NodeEntity) {
        didTapNodeAction_calledTimes += 1
    }
    
    func showError(_ error: Error) {}
}
