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
        setTitleColor(.black, for: .normal)
        setTitle("\(emoji) \(count)", for: .normal)
        addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
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
