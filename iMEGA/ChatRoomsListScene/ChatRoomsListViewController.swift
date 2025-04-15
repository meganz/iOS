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
        navigationItem.backBarButtonItem = BackBarButtonItem(
            menuTitle: Strings.Localizable.chat
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureAdsVisibility()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configureAdsVisibility()
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
