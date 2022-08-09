
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
        button.applyFontSizes()
    }
    
    private func setSelectedTab(forTabButton button: UIButton, lineView: UIView)  {
        lineView.backgroundColor = Colors.SharedItems.Tabs.sharedItemsTabSelectedBackground.color
        button.tintColor = Colors.SharedItems.Tabs.sharedItemsTabSelectedIconTint.color
        button.setTitleColor(Colors.SharedItems.Tabs.sharedItemsTabSelectedText.color, for: .selected)
    }
    
    private func setNormalTab(forTabButton button: UIButton, lineView: UIView)  {
        lineView.backgroundColor = Colors.SharedItems.Tabs.sharedItemsTabNormalBackground.color
        button.tintColor = Colors.SharedItems.Tabs.sharedItemsTabNormalIconTint.color
        button.setTitleColor(Colors.SharedItems.Tabs.sharedItemsTabNormalText.color, for: .normal)
    }
}
