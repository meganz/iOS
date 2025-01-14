import Foundation

@MainActor
public struct TextFieldAlertViewModel {
    public var textString: String
    let title: String
    public var placeholderText: String?
    let affirmativeButtonTitle: String
    let affirmativeButtonInitiallyEnabled: Bool?
    let destructiveButtonTitle: String
    let highlightInitialText: Bool?
    let message: String?
    public var action: (@MainActor (String?) -> Void)?
    public var validator: ((String?) -> TextFieldAlertError?)?
    
    public init(
        textString: String = "",
        title: String,
        placeholderText: String? = nil,
        affirmativeButtonTitle: String,
        affirmativeButtonInitiallyEnabled: Bool? = nil,
        destructiveButtonTitle: String,
        highlightInitialText: Bool? = nil,
        message: String? = nil,
        action: (@MainActor (String?) -> Void)? = nil,
        validator: ((String?) -> TextFieldAlertError?)? = nil
    ) {
        self.textString = textString
        self.title = title
        self.placeholderText = placeholderText
        self.affirmativeButtonTitle = affirmativeButtonTitle
        self.affirmativeButtonInitiallyEnabled = affirmativeButtonInitiallyEnabled
        self.destructiveButtonTitle = destructiveButtonTitle
        self.highlightInitialText = highlightInitialText
        self.message = message
        self.action = action
        self.validator = validator
    }
}

extension TextFieldAlertViewModel: Equatable {
    public nonisolated static func == (lhs: TextFieldAlertViewModel, rhs: TextFieldAlertViewModel) -> Bool {
        lhs.textString == rhs.textString &&
        lhs.title == rhs.title &&
        lhs.placeholderText == rhs.placeholderText &&
        lhs.affirmativeButtonTitle == rhs.affirmativeButtonTitle &&
        lhs.affirmativeButtonInitiallyEnabled == rhs.affirmativeButtonInitiallyEnabled &&
        lhs.highlightInitialText == rhs.highlightInitialText
    }
}

public struct TextFieldAlertError: Equatable, Sendable {
    let title: String
    let description: String
    
    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}
