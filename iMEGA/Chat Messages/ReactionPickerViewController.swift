import ISEmojiView
import MEGADesignToken
import UIKit

extension UISheetPresentationController.Detent {
    static func reactionPickerShortForm() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: .reactionPickerShortForm) { _ in
            300
        }
    }
}

extension UISheetPresentationController.Detent.Identifier {
    static let reactionPickerShortForm = UISheetPresentationController.Detent.Identifier("reactionPickerShortForm")
}

class ReactionPickerViewController: UIViewController {
    
    var message: ChatMessage?

    private var emojiInputView: EmojiView {
        let keyboardSettings = KeyboardSettings(bottomType: .categories)
        keyboardSettings.countOfRecentsEmojis = 20
        keyboardSettings.updateRecentEmojiImmediately = true
        let emojiView = EmojiView(keyboardSettings: keyboardSettings)
        emojiView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 300)
        emojiView.delegate = self
        emojiView.backgroundColor = TokenColors.Background.page
        
        view.backgroundColor = .systemBackground
        return emojiView
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wrap(emojiInputView)
        preferredContentSize = CGSize(width: 400, height: 300)

        view.backgroundColor = .systemBackground
    }
    
}

extension ReactionPickerViewController: EmojiViewDelegate {
    
      // MARK: - EmojiViewDelegate
      
      func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        let megaMessage = message?.message
          MEGAChatSdk.shared.addReaction(forChat: message?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji)
        dismiss(animated: true, completion: nil)
      }
      
      func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {
      
      }
      
      func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
        dismiss(animated: true, completion: nil)
      }
      
      func emojiViewDidPressDismissKeyboardButton(_ emojiView: EmojiView) {
        dismiss(animated: true, completion: nil)
      }
}

extension ReactionPickerViewController {
    func configureForPopoverSheetPresentation(sourceView: UIView) {
        modalPresentationStyle = .popover
        if let popover = popoverPresentationController {
            popover.sourceView = sourceView
            let sheet = popover.adaptiveSheetPresentationController
            sheet.detents = [
                .reactionPickerShortForm(),
                .large()
            ]
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
    }
}
