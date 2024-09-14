import MEGADesignToken

final class ActionSheetSwitchCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    func configureCell(action: ActionSheetSwitchAction) {
        titleLabel.text = action.title
        
        if let detail = action.detail {
            detailLabel.text = detail
            detailLabel.textColor = TokenColors.Text.secondary
            detailLabel.isHidden = false
            detailLabel.alpha = 1.0
        } else {
            performCellAnimation()
        }
        
        accessoryView = action.switchView
        
        action.switchView?.addTarget(self, action: #selector(switchValueChange(sender:)), for: .valueChanged)
    }
    
    @objc
    func switchValueChange(sender: Any) {
        guard let actionSwitch = sender as? UISwitch else { return }
        
        if !actionSwitch.isOn {
            DispatchQueue.main.async {
                self.performCellAnimation()
            }
        }
    }
    
    private func performCellAnimation() {
        detailLabel.alpha = 0.0
        
        UIView.animate(withDuration: 0.6,
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1,
                       options: [],
                       animations: { [weak self] in
                            self?.detailLabel.isHidden = true
                            self?.stackView.layoutIfNeeded()
                       },
                       completion: nil)
    }
}
