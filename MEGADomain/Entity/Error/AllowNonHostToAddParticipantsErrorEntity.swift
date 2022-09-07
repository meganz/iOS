
enum AllowNonHostToAddParticipantsErrorEntity: Error {
    case generic
    case chatRoomDoesNoExists
    case oneToOneChatRoom
    case access
    case alreadyExists
}
