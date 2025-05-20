public protocol SharedRepositoryProtocol: Sendable {
    static var sharedRepo: Self { get }
}
