import Foundation
@testable import MEGA
import MEGADomain
import MEGAFoundation

final class MockSearchFileUseCase: SearchFileUseCaseProtocol {
    private let nodes: [NodeEntity]

    init(
        nodes: [NodeEntity] = []
    ) {
        self.nodes = nodes
    }

    func searchFiles(
        withName name: String,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    ) {
        completion(nodes.filter { $0.name.contains(name) })
    }

    func cancelCurrentSearch() {}
}
