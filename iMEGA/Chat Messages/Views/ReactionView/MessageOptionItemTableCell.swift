protocol MessageOptionItemTableCellDelegate: AnyObject {
    func setImageView(_ imageView: UIImageView, forIndex index: Int)
    func setLabel(_ label: UILabel, forIndex index: Int)
}

class MessageOptionItemTableCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var optionItemImageView: UIImageView!
    @IBOutlet weak var seperatorView: UIView!
    
    var index: Int = -1
    weak var delegate: (any MessageOptionItemTableCellDelegate)? {
        didSet {
            guard let delegate = delegate else {
                return
            }

            delegate.setLabel(titleLabel, forIndex: index)
            delegate.setImageView(optionItemImageView, forIndex: index)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        index = -1
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        seperatorView.backgroundColor = UIColor.mnz_separator()
        contentView.backgroundColor = UIColor.mnz_backgroundElevated()
    }
    
}
