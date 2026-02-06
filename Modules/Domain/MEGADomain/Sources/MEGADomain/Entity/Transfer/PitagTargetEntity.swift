/// Upload target tags representing the destination of an upload.
public enum PitagTargetEntity: Sendable {
    /// Not applicable or default target
    case notApplicable
    /// Target is Cloud Drive
    case cloudDrive
    /// Target is a 1-to-1 chat
    case chat1To1
    /// Target is a group chat
    case chatGroup
    /// Target is note to self
    case noteToSelf
    /// Target is an incoming share
    case incomingShare
    /// Target is multiple chats
    case multipleChats
}
