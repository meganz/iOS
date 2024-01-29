import MEGADomain
import MEGAL10n

extension DeviceCenterAction {
    static func infoAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .info,
            title: Strings.Localizable.info,
            icon: "info"
        )
    }
    
    static func renameAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .rename,
            title: Strings.Localizable.rename,
            icon: "rename"
        )
    }
    
    static func cameraUploadsAction(isEnabled: Bool) -> DeviceCenterAction {
        DeviceCenterAction(
            type: .cameraUploads,
            title: Strings.Localizable.cameraUploadsLabel,
            subtitle: isEnabled ?
            Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.enabled :
            Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.disabled,
            icon: "cameraUploadsSettings"
        )
    }
}
