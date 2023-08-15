import Foundation

struct TextFieldAlertViewModel {
    var textString: String
    let title: String
    var placeholderText: String?
    let affirmativeButtonTitle: String
    let affirmativeButtonInitiallyEnabled: Bool?
    let highlightInitialText: Bool?
    let message: String?
    var action: ((String?) -> Void)?
    var validator: ((String?) -> TextFieldAlertError?)?
    
    init(
        textString: String = "",
        title: String,
        placeholderText: String? = nil,
        affirmativeButtonTitle: String,
        affirmativeButtonInitiallyEnabled: Bool? = nil,
        highlightInitialText: Bool? = nil,
        message: String? = nil,
        action: ((String?) -> Void)? = nil,
        validator: ((String?) -> TextFieldAlertError?)? = nil
    ) {
        self.textString = textString
        self.title = title
        self.placeholderText = placeholderText
        self.affirmativeButtonTitle = affirmativeButtonTitle
        self.affirmativeButtonInitiallyEnabled = affirmativeButtonInitiallyEnabled
        self.highlightInitialText = highlightInitialText
        self.message = message
        self.action = action
        self.validator = validator
    }
}

extension TextFieldAlertViewModel: Equatable {
    static func == (lhs: TextFieldAlertViewModel, rhs: TextFieldAlertViewModel) -> Bool {
        lhs.textString == rhs.textString &&
        lhs.title == rhs.title &&
        lhs.placeholderText == rhs.placeholderText &&
        lhs.affirmativeButtonTitle == rhs.affirmativeButtonTitle &&
        lhs.affirmativeButtonInitiallyEnabled == rhs.affirmativeButtonInitiallyEnabled &&
        lhs.highlightInitialText == rhs.highlightInitialText
    }
}

struct TextFieldAlertError: Equatable {
    let title: String
    let description: String
}
