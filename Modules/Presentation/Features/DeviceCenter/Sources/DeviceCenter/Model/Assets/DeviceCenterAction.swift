public enum DeviceCenterActionType {
    case cameraUploads
    case info
    case rename
    case showInCD
    case showInBackups
}

public struct DeviceCenterAction {
    let type: DeviceCenterActionType
    let title: String
    let subtitle: String?
    let icon: String
    let action: () -> Void

    public init(type: DeviceCenterActionType, title: String, subtitle: String? = nil, icon: String, action: @escaping () -> Void) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
    }
}
