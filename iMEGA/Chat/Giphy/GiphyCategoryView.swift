import FlexLayout
import PinLayout
import UIKit

@objc enum GiphyCatogory: Int {
    case gifs
    case stickers
    case text
    case emoji
}

class GiphyCategoryView: UIView {
    
    private let contentView = UIView()
    private let gifButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.setTitleColor(.mnz_label(), for: .selected)
        button.setTitleColor(.systemGray, for: .normal)
        button.setTitle("GIFs", for: .normal)
        button.isSelected = true
        button.tag = GiphyCatogory.gifs.rawValue
        return button
    }()
    
    private let stickersButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.setTitleColor(.mnz_label(), for: .selected)
        button.setTitleColor(.systemGray, for: .normal)
        button.setTitle("Stickers", for: .normal)
        button.isSelected = false
        button.tag = GiphyCatogory.stickers.rawValue
        return button
    }()
    
    private let textButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.setTitleColor(.mnz_label(), for: .selected)
        button.setTitleColor(.systemGray, for: .normal)
        button.setTitle("Text", for: .normal)
        button.isSelected = false
        button.tag = GiphyCatogory.text.rawValue
        return button
    }()
    
    private let emojiButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.setTitleColor(.mnz_label(), for: .selected)
        button.setTitleColor(.systemGray, for: .normal)
        button.setTitle("Emoji", for: .normal)
        button.isSelected = false
        button.tag = GiphyCatogory.emoji.rawValue
        return button
    }()
    
    var onSelected: (_ cateogry: GiphyCatogory) -> Void = {_ in } // closure must be held in this class.
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 48))
        
        backgroundColor = .mnz_background()
        
        gifButton.addTarget(self, action: #selector(GiphyCategoryView.didTapButton), for: .touchUpInside)
        stickersButton.addTarget(self, action: #selector(GiphyCategoryView.didTapButton), for: .touchUpInside)
        textButton.addTarget(self, action: #selector(GiphyCategoryView.didTapButton), for: .touchUpInside)
        emojiButton.addTarget(self, action: #selector(GiphyCategoryView.didTapButton), for: .touchUpInside)

        contentView.flex.height(48).direction(.row).define { (flex) in
            flex.addItem(gifButton).grow(1).shrink(1)
            flex.addItem(stickersButton).grow(1).shrink(1)
//            flex.addItem(textButton).grow(1).shrink(1)
//            flex.addItem(emojiButton).grow(1).shrink(1)
        }
        
        addSubview(contentView)
    }
    
    // MARK: - Button Actions

    @objc func didTapButton(button: UIButton) {
        gifButton.isSelected = button.tag == gifButton.tag
        stickersButton.isSelected = button.tag == stickersButton.tag
        textButton.isSelected = button.tag == textButton.tag
        emojiButton.isSelected = button.tag == emojiButton.tag
        
        if let category = GiphyCatogory(rawValue: button.tag) {
            onSelected(category)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.pin.all()
        contentView.flex.layout()
    }
}
