import Foundation
import MEGAUI

enum StepType {
    case text(String)
    case linkText(String)
}

struct Step {
    let text: String
    
    var attributedText: AttributedString {
        AttributedString(text)
            .convertURLsToClickableLinks() // Apply link formatting
            .applyBoldFormattingFromHTMLTags() // Apply bold formatting
    }
    
    init(text: String) {
        self.text = text
    }
}
