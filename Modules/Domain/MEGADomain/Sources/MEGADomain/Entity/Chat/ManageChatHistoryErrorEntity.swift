
public enum ManageChatHistoryErrorEntity: Error {
    case generic
    case chatIdInvalid
    case chatIdDoesNotExist
    case notEnoughPrivileges
}
