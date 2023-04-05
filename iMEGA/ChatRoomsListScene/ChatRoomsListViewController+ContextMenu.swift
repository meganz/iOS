import MEGADomain

extension ChatRoomsListViewController {
    private func setEmptyViewButtonWithMeetingsOptions(button: UIButton) {
        button.menu = viewModel.contextMenuManager.contextMenu(with: CMConfigEntity(menuType: .menu(type: .meeting)))
            button.showsMenuAsPrimaryAction = true
    }
    
    private func setEmptyViewButtonWithChatOptions(button: UIButton) {
        button.addTarget(self, action: #selector(addBarButtonItemTapped), for: .touchUpInside)
    }
    
    private func setAddBarButtonWithMeetingsOptions() {
        addBarButtonItem.menu = viewModel.contextMenuManager.contextMenu(
            with: CMConfigEntity(
                menuType: .menu(type: .meeting),
                shouldScheduleMeeting: FeatureFlagProvider().isFeatureFlagEnabled(for: .scheduleMeeting)
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
