public enum SMSStateEntity: Int, CaseIterable, Sendable {
    case notAllowed = 0
    case onlyUnblock
    case optInAndUnblock
}
