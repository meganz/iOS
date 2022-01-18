import UIKit

class ReactionEmojiButton: UIButton {
    
    let count: Int
    let emoji: String
    let emojiSelected: Bool

    var buttonPressed:((String, UIView) -> Void)?
    var buttonLongPress:((String, UIView) -> Void)?
    
    init(count:Int, emoji:String, emojiSelected: Bool) {
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
                                                                                   NSAttributedString.Key.baselineOffset:3,
                                                                                  
        ])
        setTitleColor(.mnz_label(), for: .normal)
        let attributedString = NSMutableAttributedString()
        attributedString.append(attributedEmoji)
        attributedString.append(attributedCount)
        
        contentVerticalAlignment = .center
        setAttributedTitle(attributedString, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        layer.borderWidth = 1
        layer.cornerRadius = 12
        
        if emojiSelected {
            layer.borderColor = UIColor.mnz_green009476().cgColor
        } else {
            layer.borderColor = Colors.Chat.ReactionBubble.border.color.cgColor 
        }
        backgroundColor = UIColor.mnz_reactionBubbleBackgroundColor(self.traitCollection, selected: emojiSelected)

    }
    
    private func updateAppearance () {
        configure()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
    
    @objc func longPress(_ tapGesture: UITapGestureRecognizer) {

        buttonLongPress?(emoji, self)
    }

    @objc func buttonTapped(_ sender: UIButton) {
        buttonPressed?(emoji, self)
    }
}
