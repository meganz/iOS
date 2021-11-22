

final class MeetingCompatibilityWarningView: UIView {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var buttonTappedHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = 16.0
        label.text = Strings.Localizable.Meetings.Incompatibility.warningMessage
        button.setTitle(NSLocalizedString("ok", comment: ""), for: .normal)
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        buttonTappedHandler?()
    }
}
