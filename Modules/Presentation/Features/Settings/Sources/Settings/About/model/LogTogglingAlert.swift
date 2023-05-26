
public struct LogTogglingAlert {
    public var enableTitle: String
    public var enableMessage: String
    public var disableTitle: String
    public var disableMessage: String
    public var mainActionTitle: String
    public var cancelActionTitle: String
    
    public init(enableTitle: String, enableMessage: String, disableTitle: String, disableMessage: String, mainActionTitle: String, cancelActionTitle: String) {
        self.enableTitle = enableTitle
        self.enableMessage = enableMessage
        self.disableTitle = disableTitle
        self.disableMessage = disableMessage
        self.mainActionTitle = mainActionTitle
        self.cancelActionTitle = cancelActionTitle
    }
}
