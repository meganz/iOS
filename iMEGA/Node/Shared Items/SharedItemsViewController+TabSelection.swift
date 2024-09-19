import MEGADesignToken

extension SharedItemsViewController {
    @objc func updateTabSelection() {
        self.selectorView?.backgroundColor = .surface1Background()
        
        updateTab(withButton: incomingButton, lineView: incomingLineView)
        updateTab(withButton: outgoingButton, lineView: outgoingLineView)
        updateTab(withButton: linksButton, lineView: linksLineView)
    }
    
    private func updateTab(withButton button: MEGAVerticalButton?, lineView: UIView?) {
        guard let button = button, let lineView = lineView else { return }
        let selector = button.isSelected ? setSelectedTab : setNormalTab
        selector(button, lineView)
    }
    
    private func setSelectedTab(forTabButton button: UIButton, lineView: UIView) {
        lineView.backgroundColor = TokenColors.Button.brand
        button.tintColor = TokenColors.Button.brand
        button.setTitleColor(TokenColors.Button.brand, for: .selected)
    }
    
    private func setNormalTab(forTabButton button: UIButton, lineView: UIView) {
        lineView.backgroundColor = TokenColors.Border.strong
        button.tintColor = TokenColors.Icon.secondary
        button.setTitleColor(TokenColors.Icon.secondary, for: .normal)
    }
}
