import MEGADomain
import MEGAPresentation

extension ChatRoomsListViewController {
    private func setAddBarButtonWithMeetingsOptions() {
        let menu = viewModel.contextMenuManager.contextMenu(
            with: CMConfigEntity(
                menuType: .menu(type: .meeting),
                shouldScheduleMeeting: true
            )
        )
        
        guard let menu else { return }
        
        let newMeetingMenu = UIDeferredMenuElement.uncached {[weak self] completion in
            self?.viewModel.trackNewMeetingsAddMenu()
            completion(menu.children)
        }
        addBarButtonItem.menu = UIMenu(children: [newMeetingMenu])
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
