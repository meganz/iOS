import UIKit

protocol ReactionCollectionViewCellDelegate: class {
    func emojiTapped(_ emoji: String)
    func emojiLongPressed(_ emoji: String, sender: UIView)
}

class ReactionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var reactionButton: UIButton!
    var count: Int?
    var emoji: String?
    weak var delegate: ReactionCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    @objc func longPress(_ tapGesture: UITapGestureRecognizer) {
        guard let delegate = delegate, let emoji = emoji else {
            return
        }
        
        delegate.emojiLongPressed(emoji, sender: self)
    }

    func configureCell(_ emoji: String,_ count: Int) {
        self.emoji = emoji
        self.count = count
        
        reactionButton.setTitle("\(emoji) \(count)", for: .normal)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        let size = self.contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var cellFrame = layoutAttributes.frame
        cellFrame.size = size
        layoutAttributes.frame = cellFrame
        return layoutAttributes
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        guard let delegate = delegate, let emoji = emoji else {
            return
        }
        
        delegate.emojiTapped(emoji)
    }
}
