

@objc final class CallCompatibilityWarningView: UIView {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dividerHeightConstraint: NSLayoutConstraint!

    var buttonTapHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = 16.0
        label.text = NSLocalizedString("calls.incompatibility.warningMessage", comment: "")
        button.setTitle(NSLocalizedString("ok", comment: ""), for: .normal)
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        buttonTapHandler?()
    }
    
    func hideButton() {
        button.isHidden = true
        buttonHeightConstraint.constant = 0.0
        dividerView.isHidden = true
        dividerHeightConstraint.constant = 0.0
    }
}
