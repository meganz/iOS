public enum DeviceCenterActionType {
    case cameraUploads
    case info
    case rename
    case showInCD
    case showInBackups
    case sort
    case sortAscending
    case sortDescending
}

public struct DeviceCenterAction {
    let type: DeviceCenterActionType
    let title: String
    let subtitle: String?
    let icon: String
    let subActions: [DeviceCenterAction]?

    public init(type: DeviceCenterActionType, title: String, subtitle: String? = nil, icon: String, subActions: [DeviceCenterAction]? = nil) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.subActions = subActions
    }
}
