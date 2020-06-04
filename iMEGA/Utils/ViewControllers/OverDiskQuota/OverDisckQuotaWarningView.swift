import UIKit

@IBDesignable
final class OverDisckQuotaWarningView: UIView, NibLoadable {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var detailLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup View
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .yellow
        layer.borderWidth = 1
        layer.borderColor = UIColor.yellow.cgColor
    }
}
