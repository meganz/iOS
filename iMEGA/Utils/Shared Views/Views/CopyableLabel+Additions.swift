import MEGAL10n

extension CopyableLabel: UIEditMenuInteractionDelegate {
    @objc func showHideEditMenu() {
        if let menuInteraction {
            menuInteraction.dismissMenu()
        } else {
            let menuInteraction = UIEditMenuInteraction(delegate: self)
            addInteraction(menuInteraction)
            let config = UIEditMenuConfiguration(identifier: "CopyableLabel", sourcePoint: .zero)
            menuInteraction.presentEditMenu(with: config)
            self.menuInteraction = menuInteraction
        }
    }
    
    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        let copyAction = UIAction(title: Strings.Localizable.copy) { [weak self] _ in
            guard let text = self?.text else { return }
            UIPasteboard.general.string = text
        }
        
        return UIMenu(items: [copyAction])
    }
    
    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        CGRect(origin: CGPoint(x: bounds.midX, y: 0), size: .zero)
    }
    
    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, willDismissMenuFor configuration: UIEditMenuConfiguration, animator: any UIEditMenuInteractionAnimating) {
        animator.addCompletion { [weak self] in
            self?.menuInteraction = nil
        }
    }
}

