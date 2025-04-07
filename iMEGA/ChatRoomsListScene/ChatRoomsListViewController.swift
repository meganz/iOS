import Combine
import MEGAAppPresentation
import MEGAChatSdk
import MEGAL10n
import MEGAUIKit
import SwiftUI

final class ChatRoomsListViewController: UIHostingController<ChatRoomsListView> {

    private(set) var viewModel: ChatRoomsListViewModel
    
    init(
        rootView: ChatRoomsListView,
        viewModel: ChatRoomsListViewModel
    ) {
        self.viewModel = viewModel
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assignBackButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureAdsVisibility()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configureAdsVisibility()
    }
    
    // this function should be called in only 2 places :
    // 1. when view is created to have a default value
    // 2. whenever unread count changes (this is triggered by MainTabBarController
    // this should guarantee valid number shown in the back button and simplify the logic
    func assignBackButton() {
        let unreadChats = MEGAChatSdk.shared.unreadChats
        updateBackBarButtonItem(withUnreadMessages: unreadChats)
    }
    
    private func updateBackBarButtonItem(withUnreadMessages count: Int) {
        guard count > 0 else {
            clearBackBarButtonItem()
            return
        }
        
        let title = String(format: "%td", count)
        assignBackButtonWith(title: title)
    }
    
    private func assignBackButtonWith(title: String?) {
        navigationItem.backBarButtonItem = BackBarButtonItem(
            title: title,
            menuTitle: Strings.Localizable.chat
        )
    }
    
    private func clearBackBarButtonItem() {
        assignBackButtonWith(title: nil)
    }
}

extension ChatRoomsListViewController: AudioPlayerPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}

// MARK: - Ads
extension ChatRoomsListViewController: AdsSlotDisplayable {}
