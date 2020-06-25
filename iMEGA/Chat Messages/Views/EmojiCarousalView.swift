
import UIKit

class EmojiCarousalView: UIView {
    @IBOutlet weak var handlebarView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var descriptionLabel: UILabel!

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
        // TODO: Replace with the model
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionCell.reuseIdentifier, for: indexPath) as? EmojiCollectionCell else {
            fatalError("could not dequeue `EmojiCollectionCell`")
        }
        
        //TODO: Replace with the model
        cell.label.text = "♻️"
        
        return cell
    }
    
    
}

extension EmojiCarousalView: UICollectionViewDelegate {
    
}
