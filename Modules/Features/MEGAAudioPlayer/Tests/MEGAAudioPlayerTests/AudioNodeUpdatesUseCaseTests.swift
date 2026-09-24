import Foundation
import MEGAAppSDKRepo
@testable import MEGAAudioPlayer
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

/// Which SDK node updates count as "this file is gone" (IOS-11540).
///
/// The distinction the whole handler rests on: a permanent delete is reported as
/// `.removed`, but the delete a user actually performs — moving a file to the
/// Rubbish Bin — is a *move*, reported as `.parent`. An ordinary move between
/// Cloud Drive folders is reported the same way and must not drop the track.
struct AudioNodeUpdatesUseCaseTests {

    @Test("A permanently removed node counts as deleted")
    func removedNode_isDeleted() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .removed, handle: 1)]],
            isInRubbishBin: false
        )

        let batches = await collect(sut)

        #expect(batches == [[1]])
    }

    @Test("A node moved into the Rubbish Bin counts as deleted")
    func nodeMovedToRubbishBin_isDeleted() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, handle: 1)]],
            isInRubbishBin: true
        )

        let batches = await collect(sut)

        #expect(batches == [[1]], "a Rubbish Bin move is the common case and reports only .parent")
    }

    /// The "file moved" scenario: the same change type as a Rubbish Bin move, but
    /// the track is still perfectly playable and has to stay in the queue.
    @Test("A node moved between folders does not count as deleted")
    func nodeMovedBetweenFolders_isNotDeleted() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, handle: 1)]],
            isInRubbishBin: false
        )

        let batches = await collect(sut)

        #expect(batches.isEmpty)
    }

    @Test("A renamed node does not count as deleted")
    func renamedNode_isNotDeleted() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .name, handle: 1)]],
            isInRubbishBin: false
        )

        let batches = await collect(sut)

        #expect(batches.isEmpty)
    }

    /// Deleting a multi-selection arrives as one update carrying every node.
    @Test("One update reports every deleted node in it, and ignores the rest")
    func batch_reportsEveryDeletedNode() async {
        let sut = makeSUT(
            batches: [[
                NodeEntity(changeTypes: .removed, handle: 1),
                NodeEntity(changeTypes: .name, handle: 2),
                NodeEntity(changeTypes: .removed, handle: 3)
            ]],
            isInRubbishBin: false
        )

        let batches = await collect(sut)

        #expect(batches == [[1, 3]])
    }

    @Test("An update with nothing deleted in it is not emitted at all")
    func updateWithNoDeletions_emitsNothing() async {
        let sut = makeSUT(
            batches: [
                [NodeEntity(changeTypes: .name, handle: 1)],
                [NodeEntity(changeTypes: .removed, handle: 2)]
            ],
            isInRubbishBin: false
        )

        let batches = await collect(sut)

        #expect(batches == [[2]], "the first update is dropped rather than emitted empty")
    }

    // MARK: - Rename

    @Test("A renamed node is reported with its new name, and other changes are ignored")
    func renamedNode_isReported() async {
        let sut = makeSUT(batches: [[
            NodeEntity(changeTypes: .name, name: "new.mp3", handle: 1),
            NodeEntity(changeTypes: .removed, handle: 2),
            NodeEntity(changeTypes: .favourite, handle: 3)
        ]])

        let batches = await collectRenamed(sut)

        #expect(batches.map { $0.map(\.handle) } == [[1]])
        #expect(batches.first?.first?.name == "new.mp3")
    }

    @Test("An update with nothing renamed in it is not emitted at all")
    func updateWithNoRename_emitsNothing() async {
        let sut = makeSUT(batches: [
            [NodeEntity(changeTypes: .removed, handle: 1)],
            [NodeEntity(changeTypes: .name, handle: 2)]
        ])

        let batches = await collectRenamed(sut)

        #expect(batches.map { $0.map(\.handle) } == [[2]])
    }

    // MARK: - Folder link

    @Test("A node removed from the folder-link tree counts as deleted")
    func folderLink_removedNode_isDeleted() async {
        let sut = makeSUT(folderLinkBatches: [[NodeEntity(changeTypes: .removed, handle: 1)]])

        let batches = await collectFolderLink(sut)

        #expect(batches == [[1]])
    }

    /// A folder link only ever shows the tree under the shared folder, so anything the
    /// owner moves out of it — the Rubbish Bin included — leaves that tree and arrives
    /// as `.removed`. A bare `.parent` is a move *within* the link, which keeps playing.
    @Test("A node moved inside the folder link does not count as deleted, whatever the account SDK says about the Rubbish Bin")
    func folderLink_movedNode_isNotDeleted() async {
        let sut = makeSUT(
            folderLinkBatches: [[NodeEntity(changeTypes: .parent, handle: 1)]],
            isInRubbishBin: true
        )

        let batches = await collectFolderLink(sut)

        #expect(batches.isEmpty, "the account SDK cannot resolve a folder-link handle, so its Rubbish Bin answer is meaningless here")
    }

    /// The folder-link update only says which node changed; the node that replaces the
    /// queued one is looked up afresh, authorized, so it still streams and has actions.
    @Test("A renamed folder-link node is reported as the authorized node now in the folder-link tree")
    func folderLink_renamedNode_isReportedAsTheAuthorizedNode() async {
        let sut = makeSUT(
            folderLinkBatches: [[
                NodeEntity(changeTypes: .name, handle: 1),
                NodeEntity(changeTypes: .removed, handle: 2)
            ]],
            folderLinkNodes: [1: StubPlayableNode(handle: 1, name: "new.mp3")]
        )

        let batches = await collectRenamedFolderLink(sut)

        #expect(batches.map { $0.map(\.handle) } == [[1]])
        #expect(batches.first?.first?.name == "new.mp3")
    }

    @Test("A renamed folder-link node that can no longer be found is left out")
    func folderLink_renamedNodeThatIsGone_isLeftOut() async {
        let sut = makeSUT(
            folderLinkBatches: [
                [NodeEntity(changeTypes: .name, handle: 1)],
                [NodeEntity(changeTypes: .name, handle: 2)]
            ],
            folderLinkNodes: [2: StubPlayableNode(handle: 2, name: "new.mp3")]
        )

        let batches = await collectRenamedFolderLink(sut)

        #expect(batches.map { $0.map(\.handle) } == [[2]], "the first update is dropped rather than emitted empty")
    }

    // MARK: - Helpers

    private func makeSUT(
        batches: [[NodeEntity]] = [],
        folderLinkBatches: [[NodeEntity]] = [],
        isInRubbishBin: Bool = false,
        folderLinkNodes: [HandleEntity: StubPlayableNode] = [:]
    ) -> AudioNodeUpdatesUseCase {
        AudioNodeUpdatesUseCase(
            nodeRepository: MockNodeRepository(
                nodeUpdates: finiteSequence(of: batches),
                folderLinkNodeUpdates: finiteSequence(of: folderLinkBatches)
            ),
            nodeAttributeRepository: MockNodeAttributeRepository(isInRubbishBin: isInRubbishBin),
            folderLinkNodeRepository: StubFolderLinkNodeRepository(nodes: folderLinkNodes)
        )
    }

    /// Finishes once the batches are out, so the `collect` helpers can return.
    private func finiteSequence(of batches: [[NodeEntity]]) -> AnyAsyncSequence<[NodeEntity]> {
        AsyncStream<[NodeEntity]> { continuation in
            batches.forEach { continuation.yield($0) }
            continuation.finish()
        }
        .eraseToAnyAsyncSequence()
    }

    private func collect(_ sut: AudioNodeUpdatesUseCase) async -> [Set<HandleEntity>] {
        var batches: [Set<HandleEntity>] = []
        for await batch in sut.deletedNodeHandles {
            batches.append(batch)
        }
        return batches
    }

    private func collectRenamed(_ sut: AudioNodeUpdatesUseCase) async -> [[NodeEntity]] {
        var batches: [[NodeEntity]] = []
        for await batch in sut.renamedNodes {
            batches.append(batch)
        }
        return batches
    }

    private func collectRenamedFolderLink(_ sut: AudioNodeUpdatesUseCase) async -> [[any PlayableNode]] {
        var batches: [[any PlayableNode]] = []
        for await batch in sut.renamedFolderLinkNodes {
            batches.append(batch)
        }
        return batches
    }

    private func collectFolderLink(_ sut: AudioNodeUpdatesUseCase) async -> [Set<HandleEntity>] {
        var batches: [Set<HandleEntity>] = []
        for await batch in sut.deletedFolderLinkNodeHandles {
            batches.append(batch)
        }
        return batches
    }
}

private struct StubFolderLinkNodeRepository: AudioFolderLinkNodeRepositoryProtocol {
    static var newRepo: StubFolderLinkNodeRepository { StubFolderLinkNodeRepository(nodes: [:]) }

    let nodes: [HandleEntity: StubPlayableNode]

    func authorizedNode(forHandle handle: HandleEntity) -> (any PlayableNode)? {
        nodes[handle]
    }
}
