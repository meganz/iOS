import AsyncAlgorithms
@testable import CloudDrive
@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellViewModel Tests")
struct NodeTagsCellViewModelTests {
    @MainActor
    @Test("Check for tags")
    func checkTags() {
        let tags = ["tag1", "tag2", "tag3"]
        let node = NodeEntity(tags: tags)
        let sut = makeSUT(node: node)
        #expect(sut.tags == tags)
    }

    @MainActor
    private func makeSUT(node: NodeEntity) -> NodeTagsCellViewModel {
        NodeTagsCellViewModel(node: node)
    }
}
