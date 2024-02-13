import DeviceCenter
@testable import MEGA
import MEGADomain

final class MockMyAccountHallRouter: MyAccountHallRouting {
    var navigateToDeviceCenter_calledTimes = 0
    var didTapCameraUploadsAction_calledTimes = 0
    var didTapRenameAction_calledTimes = 0
    var didTapInfoAction_calledTimes = 0
    var didTapShowInAction_calledTimes = 0
    
    func navigateToDeviceCenter(deviceCenterBridge: DeviceCenterBridge, deviceCenterAssets: DeviceCenterAssets) {
        navigateToDeviceCenter_calledTimes += 1
    }
    
    func didTapCameraUploadsAction(statusChanged: @escaping () -> Void) {
        didTapCameraUploadsAction_calledTimes += 1
    }
    
    func didTapRenameAction(_ renameEntity: RenameActionEntity) {
        didTapRenameAction_calledTimes += 1
    }
    
    func didTapNavigateToContent(_ navigateToContentEntity: NavigateToContentActionEntity) {
        didTapShowInAction_calledTimes += 1
    }
    
    func didTapInfoAction(_ infoModel: ResourceInfoModel) {
        didTapInfoAction_calledTimes += 1
    }
}
