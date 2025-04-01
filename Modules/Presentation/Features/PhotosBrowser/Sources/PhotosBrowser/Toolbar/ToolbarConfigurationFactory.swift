import MEGAAppPresentation

struct ToolbarConfigurationFactory {
    static func configuration(on displayMode: PhotosBrowserDisplayMode) -> ToolbarConfigurationStrategy {
        switch displayMode {
        case .cloudDrive:
            CloudDriveToolbarConfigurationStrategy()
        case .chatAttachment:
            ChatAttachmenToolbarConfigurationStrategy()
        default:
            CloudDriveToolbarConfigurationStrategy()
        }
    }
}
