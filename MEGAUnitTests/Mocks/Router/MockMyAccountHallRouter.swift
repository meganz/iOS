import DeviceCenter
@testable import MEGA
import MEGADomain

final class MockMyAccountHallRouter: MyAccountHallRouting {
    var navigateToDeviceCenter_calledTimes = 0
    var didTapCameraUploadsAction_calledTimes = 0
    var didTapRenameAction_calledTimes = 0
    var didTapInfoAction_calledTimes = 0
    var didTapShowInAction_calledTimes = 0
    var navigateToProfile_calledTimes = 0
    var navigateToUsage_calledTimes = 0
    var navigateToSettings_calledTimes = 0
    var navigateToNotificationCentre_calledTimes = 0
    
    func navigateToDeviceCenter(deviceCenterBridge: DeviceCenterBridge, deviceCenterActions: [ContextAction]) {
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
    
    func navigateToProfile() {
        navigateToProfile_calledTimes += 1
    }

    func navigateToUsage() {
        navigateToUsage_calledTimes += 1
    }

    func navigateToSettings() {
        navigateToSettings_calledTimes += 1
    }

    func navigateToNotificationCentre() {
        navigateToNotificationCentre_calledTimes += 1
    }
}
