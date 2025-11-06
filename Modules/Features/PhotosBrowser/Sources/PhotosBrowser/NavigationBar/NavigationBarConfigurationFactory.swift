import MEGAAppPresentation

struct NavigationBarConfigurationFactory {
    static func configuration(on displayMode: PhotosBrowserDisplayMode) -> any NavigationBarConfigurationStrategy {
        switch displayMode {
        case .cloudDrive:
            CloudDriveNavigationBarConfigurationStrategy()
        case .chatAttachment:
            ChatAttachmentNavigationBarConfigurationStrategy()
        default:
            CloudDriveNavigationBarConfigurationStrategy()
        }
    }
}
