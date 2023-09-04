public struct ChangeSfuServerAlert {
    public var title: String
    public var message: String
    public var placeholder: String
    public var cancelButton: String
    public var changeButton: String
    
    public init(title: String, message: String, placeholder: String, cancelButton: String, changeButton: String) {
        self.title = title
        self.message = message
        self.placeholder = placeholder
        self.cancelButton = cancelButton
        self.changeButton = changeButton
    }
}
