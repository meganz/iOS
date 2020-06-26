
import UIKit

protocol EmojiCarousalViewDelegate: class {
    func didSelect(emoji: String)
}

class EmojiCarousalView: UIView {
    @IBOutlet weak var handlebarView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    weak var delegate: EmojiCarousalViewDelegate?
    
    var emojiList: [String]? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var selectedIndex = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(EmojiCollectionCell.nib,
                                forCellWithReuseIdentifier: EmojiCollectionCell.reuseIdentifier)
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
        }
    }
    
    private func updateAppearance() {
        descriptionLabel.textColor = UIColor.mnz_separator(for: traitCollection)
    }
}

extension EmojiCarousalView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiList?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionCell.reuseIdentifier, for: indexPath) as? EmojiCollectionCell else {
            fatalError("could not dequeue `EmojiCollectionCell`")
        }
        
        if let emoji = emojiList?[indexPath.item] {
            cell.label.text = emoji
        }
        
        return cell
    }
}

extension EmojiCarousalView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let emoji = emojiList?[indexPath.item] else {
            return
        }
        
        delegate?.didSelect(emoji: emoji)
    }
}
