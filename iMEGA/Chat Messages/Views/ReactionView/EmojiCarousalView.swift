import UIKit

protocol EmojiCarousalViewDelegate: AnyObject {
    func numberOfEmojis() -> Int
    func emojiAtIndex(_ index: Int) -> String
    func numberOfUsersReacted(toEmoji emoji: String) -> Int
    func didSelect(emoji: String, atIndex index: Int)
}

class EmojiCarousalView: UIView {
    @IBOutlet weak var handlebarView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionLabelBackgroundView: UIView!
    
    weak var delegate: (any EmojiCarousalViewDelegate)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(EmojiReactionCollectionCell.nib,
                                forCellWithReuseIdentifier: EmojiReactionCollectionCell.reuseIdentifier)
        updateAppearance()
        handlebarView.isHidden = UIDevice.current.iPadDevice
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    func updateDescription(text: String?) {
        descriptionLabel.text = text
    }
    
    func selectEmojiAtIndex(_ index: Int, animated: Bool = true) {
        collectionView.selectItem(at: IndexPath(item: index, section: 0),
                                  animated: animated,
                                  scrollPosition: .centeredHorizontally)
    }
    
    private func updateAppearance() {
        descriptionLabel.textColor = UIColor.emojiDescriptionTextColor(traitCollection)
        descriptionLabelBackgroundView.backgroundColor = UIColor.surfaceBackground()
        handlebarView.backgroundColor = UIColor.mnz_handlebar(for: traitCollection)
        backgroundColor = UIColor.mnz_backgroundElevated()
    }
}

extension EmojiCarousalView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return delegate?.numberOfEmojis() ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiReactionCollectionCell.reuseIdentifier, for: indexPath) as? EmojiReactionCollectionCell else {
            fatalError("could not dequeue `EmojiCollectionCell`")
        }
                
        if let emoji = delegate?.emojiAtIndex(indexPath.row),
            let number = delegate?.numberOfUsersReacted(toEmoji: emoji) {
            cell.emojiLabel.text = emoji
            cell.numberOfUsersReactedLabel.text = "\(number)"
        }
        
        return cell
    }
}

extension EmojiCarousalView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let emoji = (collectionView.cellForItem(at: indexPath) as? EmojiReactionCollectionCell)?.emojiLabel.text else {
            return
        }
        
        delegate?.didSelect(emoji: emoji, atIndex: indexPath.item)
    }
}
