import MEGAPresentation

struct NavigationBarConfigurationFactory {
    static func configuration(on displayMode: PhotosBrowserDisplayMode) -> NavigationBarConfigurationStrategy {
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
