import Foundation

public struct TextFieldAlertViewModel {
    let textString: String = ""
    let title: String
    let invalidTextTitle: String
    let placeholderText: String
    let affirmativeButtonTitle: String
    let message: String?
    var action: (String?) -> ()
}
