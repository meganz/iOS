
public enum ChatRoomErrorEntity: Error {
    case generic
    case emptyTextResponse
    case noChatRoomFound
    case meetingLinkCreateError
    case meetingLinkQueryError
    case meetingLinkRemoveError
}
