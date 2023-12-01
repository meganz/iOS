extension SharedItemsViewController {
    @objc func updateTabSelection() {
        self.selectorView?.backgroundColor = .mnz_mainBars(for: traitCollection)
        
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
        lineView.backgroundColor = UIColor.sharedItemsTabSelectedBackground
        button.tintColor = UIColor.sharedItemsTabSelectedIconTint
        button.setTitleColor(UIColor.sharedItemsTabSelectedText, for: .selected)
    }
    
    private func setNormalTab(forTabButton button: UIButton, lineView: UIView) {
        lineView.backgroundColor = UIColor.sharedItemsTabNormalBackground
        button.tintColor = UIColor.sharedItemsTabNormalIconTint
        button.setTitleColor(UIColor.sharedItemsTabNormalText, for: .normal)
    }
}
