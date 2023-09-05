import MEGAL10n

struct PermissionAlertModel {
    let title: String
    let message: String
    let primaryAction: ActionModel
    let secondaryAction: ActionModel?
    
    struct ActionModel {
        let title: String
        let style: ActionStyle
        let handler: (() -> Void)?
    }
    
    enum ActionStyle {
        case `default`, cancel, destructive
    }
}

extension PermissionAlertModel {
    
    static func photo(completion: @escaping () -> Void) -> PermissionAlertModel {
        model(message: Strings.Localizable.photoLibraryPermissions, completion: completion)
    }
    
    static func video(completion: @escaping () -> Void) -> PermissionAlertModel {
        model(
            message: Strings.Localizable.cameraPermissions,
            completion: completion
        )
    }
    
    private static func model(
        with title: String = Strings.Localizable.attention,
        message: String,
        completion: @escaping () -> Void
    ) -> PermissionAlertModel {
        .init(
            title: title,
            message: message,
            primaryAction: .init(title: Strings.Localizable.notNow, style: .cancel, handler: nil),
            secondaryAction: .init(title: Strings.Localizable.settingsTitle, style: .default, handler: completion))
    }
}
