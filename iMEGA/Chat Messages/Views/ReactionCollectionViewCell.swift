import UIKit

class ReactionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var reactionButton: UIButton!
    var count: Int?
    var emoji: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        // Initialization code
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
}
