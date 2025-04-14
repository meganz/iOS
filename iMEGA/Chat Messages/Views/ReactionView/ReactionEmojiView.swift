import MEGADesignToken
import UIKit

class ReactionEmojiView: UIView {
    
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped(_:)))
        addGestureRecognizer(tapGesture)
        
        configure()
        sizeToFit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        let emojiLabel = UILabel()
        emojiLabel.font = UIFont.init(name: "Apple color emoji", size: 22)
        emojiLabel.text = emoji
        
        let countLabel = UILabel()
        countLabel.textColor = UIColor.label
        countLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        countLabel.text = "\(count)"
        
        let stackView = UIStackView(arrangedSubviews: [emojiLabel, countLabel])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        layer.borderWidth = 1
        layer.cornerRadius = 12
        layer.borderColor = emojiSelected ? TokenColors.Border.strongSelected.cgColor : TokenColors.Border.strong.cgColor
        backgroundColor = TokenColors.Button.secondary
    }
    
    @objc func longPress(_ tapGesture: UITapGestureRecognizer) {
        buttonLongPress?(emoji, self)
    }

    @objc func buttonTapped(_ sender: UIView) {
        buttonPressed?(emoji, self)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
