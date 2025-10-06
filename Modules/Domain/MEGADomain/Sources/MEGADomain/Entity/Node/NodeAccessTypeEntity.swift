public enum NodeAccessTypeEntity: Int, Sendable, CaseIterable {
    case unknown = -1
    case read = 0
    case readWrite
    case full
    case owner
}
