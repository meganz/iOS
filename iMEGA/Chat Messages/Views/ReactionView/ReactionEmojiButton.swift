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
        
        let attributedEmoji = NSAttributedString(string: emoji, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)])
        let attributedCount = NSAttributedString(string: " \(count)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .medium),
                                                                                   NSAttributedString.Key.baselineOffset:3,
                                                                                
        ])
        let attributedString = NSMutableAttributedString()
        attributedString.append(attributedEmoji)
        attributedString.append(attributedCount)
        
        contentVerticalAlignment = .center
        setAttributedTitle(attributedString, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        layer.borderWidth = 1
        layer.cornerRadius = 12
        
        if emojiSelected {
            backgroundColor = #colorLiteral(red: 0, green: 0.5803921569, blue: 0.462745098, alpha: 0.1)
            layer.borderColor = UIColor(hexString: "009476")?.cgColor
        } else {
            backgroundColor = UIColor(hexString: "f9f9f9")
            layer.borderColor = UIColor(red: 3/255, green: 3/255, blue: 3/255, alpha: 0.1).cgColor
        }
        
    }
    
    @objc func longPress(_ tapGesture: UITapGestureRecognizer) {

        buttonLongPress?(emoji, self)
    }

    @objc func buttonTapped(_ sender: UIButton) {
        buttonPressed?(emoji, self)
    }
}
