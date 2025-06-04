import Foundation

public protocol AppGroupContainerRepositoryProtocol: RepositoryProtocol, Sendable {
    func cleanContainer() async
}
