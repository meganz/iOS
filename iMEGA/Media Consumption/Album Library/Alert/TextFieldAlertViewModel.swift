import Foundation

struct TextFieldAlertViewModel {
    let textString: String = ""
    let title: String
    var placeholderText: String
    let affirmativeButtonTitle: String
    let message: String?
    var action: ((String?) -> Void)?
    var validator: ((String?) -> TextFieldAlertError?)?
}

struct TextFieldAlertError {
    let title: String
    let description: String
}
