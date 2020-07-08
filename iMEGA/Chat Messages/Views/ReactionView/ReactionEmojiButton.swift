import UIKit

class ReactionEmojiButton: UIButton {
    
    let count: Int
    let emoji: String
    var buttonPressed:((String, UIView) -> Void)?
    var buttonLongPress:((String, UIView) -> Void)?
    
    init(count:Int, emoji:String) {
        self.count = count
        self.emoji = emoji
        super.init(frame: .zero)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPressGesture)
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
        layer.borderColor = UIColor(hexString: "009476")?.cgColor
        layer.cornerRadius = 12
        
        backgroundColor = #colorLiteral(red: 0, green: 0.5803921569, blue: 0.462745098, alpha: 0.1)
        addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        sizeToFit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func longPress(_ tapGesture: UITapGestureRecognizer) {

        buttonLongPress?(emoji, self)
    }

    @objc func buttonTapped(_ sender: UIButton) {
        buttonPressed?(emoji, self)
    }
}
