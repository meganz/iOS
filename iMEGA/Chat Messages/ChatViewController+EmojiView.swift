import ISEmojiView

extension ChatViewController: EmojiViewDelegate {
    
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
