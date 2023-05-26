import UIKit

protocol ReactionCollectionViewCellDelegate: AnyObject {
    func emojiTapped(_ emoji: String)
    func emojiLongPressed(_ emoji: String, sender: UIView)
}

class ReactionCollectionViewCell: UILabel {

    @IBOutlet weak var reactionButton: UIButton!
    var count: Int?
    var emoji: String?
    weak var delegate: ReactionCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    @objc func longPress(_ tapGesture: UITapGestureRecognizer) {
        guard let delegate = delegate, let emoji = emoji else {
            return
        }
        
        delegate.emojiLongPressed(emoji, sender: self)
    }

    func configureCell(_ emoji: String, _ count: Int) {
        self.emoji = emoji
        self.count = count
        
        reactionButton.setTitle("\(emoji) \(count)", for: .normal)
    }
    

    
    @IBAction func buttonTapped(_ sender: UIButton) {
        guard let delegate = delegate, let emoji = emoji else {
            return
        }
        
        delegate.emojiTapped(emoji)
    }
}
