public enum WaitingRoomErrorEntity: Error {
    case generic
    case chatRoomDoesNoExists
    case oneToOneChatRoom
    case access
    case alreadyExists
}
