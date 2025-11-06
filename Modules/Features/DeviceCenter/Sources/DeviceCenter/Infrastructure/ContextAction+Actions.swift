import MEGADomain
import MEGAL10n

extension ContextAction {
    static func infoAction() -> ContextAction {
        ContextAction(
            type: .info,
            title: Strings.Localizable.info,
            icon: "info"
        )
    }
    
    static func renameAction() -> ContextAction {
        ContextAction(
            type: .rename,
            title: Strings.Localizable.rename,
            icon: "rename"
        )
    }
    
    static func cameraUploadsAction(isEnabled: Bool) -> ContextAction {
        ContextAction(
            type: .cameraUploads,
            title: Strings.Localizable.General.cameraUploads,
            subtitle: isEnabled ?
            Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.enabled :
            Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.disabled,
            icon: "cameraUploadsSettings"
        )
    }
}
