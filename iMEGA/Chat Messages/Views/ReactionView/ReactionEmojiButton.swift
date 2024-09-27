import MEGADesignToken
import UIKit

class ReactionEmojiButton: UIButton {
    
    let count: Int
    let emoji: String
    let emojiSelected: Bool

    var buttonPressed: ((String, UIView) -> Void)?
    var buttonLongPress: ((String, UIView) -> Void)?
    
    init(count: Int, emoji: String, emojiSelected: Bool) {
        self.count = count
        self.emoji = emoji
        self.emojiSelected = emojiSelected
        super.init(frame: .zero)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPressGesture)
        addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        configure()
        sizeToFit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        
        let attributedEmoji = NSAttributedString(string: emoji, attributes: [NSAttributedString.Key.font: UIFont(name: "Apple color emoji", size: 22) as Any])
        let attributedCount = NSAttributedString(string: " \(count)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .medium),
                                                                                   NSAttributedString.Key.baselineOffset: 3])
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(attributedEmoji)
        attributedString.append(attributedCount)

        var attributed = AttributedString(attributedString)
        attributed.foregroundColor = UIColor.label
        
        var config = UIButton.Configuration.plain()
        config.attributedTitle = attributed
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        configuration = config
        
        contentVerticalAlignment = .center
        
        layer.borderWidth = 1
        layer.cornerRadius = 12
        
        layer.borderColor = emojiSelected ? TokenColors.Border.strongSelected.cgColor : TokenColors.Border.strong.cgColor
        backgroundColor = TokenColors.Button.secondary
    }
    
    @objc func longPress(_ tapGesture: UITapGestureRecognizer) {

        buttonLongPress?(emoji, self)
    }

    @objc func buttonTapped(_ sender: UIButton) {
        buttonPressed?(emoji, self)
    }
}
