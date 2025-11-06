import MEGADomain

public typealias RenamingFinished = @Sendable () -> Void

public struct RenameActionEntity: Sendable {
    public let oldName: String
    public let otherNamesInContext: [String]
    public let actionType: RenameActionType
    public let alertTitles: [RenameErrorType: String]
    public let alertMessage: [RenameErrorType: String]
    public let alertPlaceholder: String
    public let renamingFinished: RenamingFinished
    
    public enum RenameErrorType: Sendable {
        case invalidCharacters
        case duplicatedName
        case nameTooLong
        case none
    }

    public enum RenameActionType: Sendable {
        case device(deviceId: String, maxCharacters: Int)
    }

    public init(
        oldName: String,
        otherNamesInContext: [String],
        actionType: RenameActionType,
        alertTitles: [RenameErrorType: String],
        alertMessage: [RenameErrorType: String],
        alertPlaceholder: String,
        renamingFinished: @escaping RenamingFinished
    ) {
        self.oldName = oldName
        self.otherNamesInContext = otherNamesInContext
        self.actionType = actionType
        self.alertTitles = alertTitles
        self.alertMessage = alertMessage
        self.alertPlaceholder = alertPlaceholder
        self.renamingFinished = renamingFinished
    }
}
