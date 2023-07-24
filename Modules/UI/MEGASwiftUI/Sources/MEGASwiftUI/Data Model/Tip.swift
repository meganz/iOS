import Foundation

public struct Tip {
    let title: String
    let message: String
    let boldMessage: String?
    let buttonTitle: String
    let buttonAction: (() -> Void)?
    
    public init(title: String,
                message: String,
                boldMessage: String? = nil,
                buttonTitle: String,
                buttonAction: (() -> Void)?) {
        self.title = title
        self.message = message
        self.boldMessage = boldMessage
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
}
