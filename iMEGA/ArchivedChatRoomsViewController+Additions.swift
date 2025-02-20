import MEGAL10n
import MEGAPermissions

extension ArchivedChatRoomsViewController {
    @objc func askNotificationPermissionsIfNeeded() {
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        permissionHandler.shouldAskForNotificationsPermissions { shouldAsk in
            guard shouldAsk else { return }
            PermissionAlertRouter
                .makeRouter(deviceHandler: permissionHandler)
                .presentModalNotificationsPermissionPrompt()
        }
    }
    
    @objc func customNavigationBarLabel() {
        let title = Strings.Localizable.archivedChats
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
}

extension ArchivedChatRoomsViewController: AudioPlayerPresenterProtocol {
    func updateContentView(_ height: CGFloat) {
        Task { @MainActor in
            additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
        }
    }
}
