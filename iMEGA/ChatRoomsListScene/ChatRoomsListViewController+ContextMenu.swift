import MEGADomain
import MEGAPresentation

extension ChatRoomsListViewController {
    private func setAddBarButtonWithMeetingsOptions() {
        addBarButtonItem.menu = viewModel.contextMenuManager.contextMenu(
            with: CMConfigEntity(
                menuType: .menu(type: .meeting),
                shouldScheduleMeeting: true
            )
        )
        addBarButtonItem.target = nil
        addBarButtonItem.action = nil
    }
    
    private func setAddBarButtonWithChatOptions() {
        addBarButtonItem.target = self
        addBarButtonItem.action = #selector(addBarButtonItemTapped)
    }
    
    func refreshContextMenuBarButton() {
        moreBarButtonItem.menu = viewModel.contextMenuManager.contextMenu(with: viewModel.contextMenuConfiguration())
    }
    
    func configureNavigationBarButtons(chatViewMode: ChatViewMode) {
        switch chatViewMode {
        case .chats:
            setAddBarButtonWithChatOptions()
        case .meetings:
            setAddBarButtonWithMeetingsOptions()
        }
        
        refreshContextMenuBarButton()
    }
}
