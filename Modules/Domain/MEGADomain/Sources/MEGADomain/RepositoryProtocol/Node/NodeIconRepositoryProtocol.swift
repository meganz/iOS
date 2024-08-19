import Foundation

public protocol NodeIconRepositoryProtocol: Sendable {
    func iconData(for node: NodeEntity) -> Data
}
