
public struct APIEnvironmentChangingAlert {
    public var title: String
    public var message: String
    public var cancelActionTitle: String
    public var actions: [APIEnvironment]
    
    public init(title: String, message: String, cancelActionTitle: String, actions: [APIEnvironment]) {
        self.title = title
        self.message = message
        self.cancelActionTitle = cancelActionTitle
        self.actions = actions
    }
}
