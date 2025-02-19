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
