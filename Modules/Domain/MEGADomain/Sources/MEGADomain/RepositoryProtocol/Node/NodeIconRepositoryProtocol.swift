import Foundation

public protocol NodeIconRepositoryProtocol {
    func iconData(for node: NodeEntity) -> Data
}
