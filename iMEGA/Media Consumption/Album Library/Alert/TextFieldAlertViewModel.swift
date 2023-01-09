import Foundation

typealias TextFieldAlertError = String?

public struct TextFieldAlertViewModel {
    let textString: String = ""
    let title: String
    let placeholderText: String
    let affirmativeButtonTitle: String
    let message: String?
    var action: ((String?) -> Void)?
    var validator: ((String?) -> TextFieldAlertError)?
}
