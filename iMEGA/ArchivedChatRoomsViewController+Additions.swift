import MEGAAppPresentation
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

    @objc func configureLiquidGlass() {
        // `Chat.storyboard` prevents this VC from extending under `.bottom`
        // edge (`Extend Edges > Under Bottom Bar` is unticked).
        // - On iOS 18 and below, this has the effect of preventing the tab bar
        // from overlapping the last few chats in a long list.
        // - However, the same config on iOS 26 dark mode will reveal the black
        // background of the `navigationController.view` behind the Liquid Glass
        // tab bar.
        if #available(iOS 26.0, *) {
            edgesForExtendedLayout = [.top, .bottom]
        }
    }
}

extension ArchivedChatRoomsViewController: AudioPlayerPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
