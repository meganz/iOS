import UIKit
import PanModal
import ISEmojiView

class ReactionPickerViewController: UIViewController {
    
    var message: ChatMessage?

    private var emojiInputView: EmojiView {
        
        let keyboardSettings = KeyboardSettings(bottomType: .categories)
        keyboardSettings.countOfRecentsEmojis = 20
        keyboardSettings.updateRecentEmojiImmediately = true
        let emojiView = EmojiView(keyboardSettings: keyboardSettings)
        emojiView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 300)
        emojiView.delegate = self
        return emojiView
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(emojiInputView)
        // Do any additional setup after loading the view.
    }

    
}

// MARK: - Pan Modal Presentable

extension ReactionPickerViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }

    var longFormHeight: PanModalHeight {
           return .contentHeight(300)
       }
    
    var anchorModalToLongForm: Bool {
        return true
    }
}

extension ReactionPickerViewController: EmojiViewDelegate {
    
      // MARK: - EmojiViewDelegate
      
      func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        
        print(emoji)
      }
      
      func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {
      
      }
      
      func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
      }
      
      func emojiViewDidPressDismissKeyboardButton(_ emojiView: EmojiView) {
      }
}
