import MEGADesignToken

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
        configureColors()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        index = -1
    }
    
    private func configureColors() {
        seperatorView.backgroundColor = TokenColors.Border.strong
        contentView.backgroundColor = TokenColors.Background.surface1
    }
    
}
