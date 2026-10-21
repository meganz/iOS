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

    // MARK: - Replacement

    /// A replaced file becomes a version of the file that replaced it — the update is a
    /// move whose new parent is a file.
    @Test("A file that became a version is reported as replaced by the file above it")
    func versionedNode_isReplacedByItsParent() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, parentHandle: 2, isFile: true)]],
            nodesByHandle: [
                2: file(2, name: "new.mp3", parent: 10),
                10: folder(10)
            ]
        )

        let batches = await collectRemovedNodes(sut)

        #expect(batches.map { $0.mapValues { $0?.handle } } == [[1: 2]])
        #expect(batches.first?[1]??.name == "new.mp3")
    }

    @Test("Replacements arriving together resolve to the latest version")
    func chainOfVersions_resolvesToTheLatest() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, parentHandle: 2, isFile: true)]],
            nodesByHandle: [
                2: file(2, parent: 3),
                3: file(3, parent: 10),
                10: folder(10)
            ]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: 3]])
    }

    /// Moves and Rubbish Bin moves are reported the same way, but land under a folder.
    @Test("A node moved into a folder is not a replacement")
    func nodeMovedIntoAFolder_isNotReplaced() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)]],
            nodesByHandle: [10: folder(10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches.isEmpty)
    }

    /// With file versioning off an upload over a file deletes it, and the new file lands
    /// under its name in the same update.
    @Test("A file removed in the same update a new file of its name lands in its folder is replaced by it")
    func removedNodeWithANewNamesake_isReplacedByIt() async {
        let uploaded = NodeEntity(changeTypes: .new, name: "song.mp3", handle: 2, parentHandle: 10, isFile: true)
        let sut = makeSUT(
            batches: [[
                NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true),
                uploaded
            ]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [uploaded]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: 2]])
    }

    @Test("A file that is not audio becoming a version is not reported")
    func nonAudioVersion_isNotReported() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "photo.jpg", handle: 1, parentHandle: 2, isFile: true)]],
            nodesByHandle: [
                2: file(2, name: "photo.jpg", parent: 10),
                10: folder(10)
            ]
        )

        let batches = await collectRemoved(sut)

        #expect(batches.isEmpty)
    }

    /// A file put back from the Rubbish Bin next to the one playing, under its name: nothing has
    /// left, so nothing was replaced.
    @Test("A file moved in next to one file of its name is not a replacement")
    func fileMovedInNextToANamesake_isNotReplaced() async {
        let moved = NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 2, parentHandle: 10, isFile: true)
        let sut = makeSUT(
            batches: [[moved]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(1, name: "song.mp3", parent: 10), moved]
        )

        let batches = await collectRemoved(sut)

        #expect(batches.isEmpty)
    }

    // MARK: - Replacement by a namesake left behind

    /// Another client replacing a file by putting one with its name in, then moving the old one
    /// to the Rubbish Bin — which keeps the folder it left as the one to restore to.
    @Test("A file moved to the Rubbish Bin from a folder holding one other file of its name is replaced by it")
    func fileMovedToRubbishBinNextToANamesake_isReplacedByIt() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, restoreParentHandle: 10, parentHandle: 99, isFile: true)]],
            isInRubbishBin: true,
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "song.mp3", parent: 10), file(3, name: "other.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: 2]])
    }

    @Test("A file permanently removed from a folder holding one other file of its name is replaced by it")
    func removedFileNextToANamesake_isReplacedByIt() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "song.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: 2]])
    }

    @Test("A removed file still listed in its folder is not its own namesake")
    func removedFileStillListed_isNotItsOwnNamesake() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(1, name: "song.mp3", parent: 10), file(2, name: "song.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: 2]])
    }

    @Test(
        "A removed file without exactly one other file of its name left is simply gone",
        arguments: [
            ("none", [NodeEntity(name: "other.mp3", handle: 2, parentHandle: 10, isFile: true)]),
            ("two", [
                NodeEntity(name: "song.mp3", handle: 2, parentHandle: 10, isFile: true),
                NodeEntity(name: "song.mp3", handle: 3, parentHandle: 10, isFile: true)
            ]),
            ("a folder", [NodeEntity(name: "song.mp3", handle: 2, parentHandle: 10, isFolder: true)])
        ]
    )
    func removedFileWithoutOneNamesake_isGone(scenario: String, children: [NodeEntity]) async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)]],
            nodesByHandle: [10: folder(10)],
            folderChildren: children
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: nil]], "\(scenario)")
    }

    @Test("Two files of one name deleted together are not paired with the one left, as it could have replaced either")
    func twoNamesakesDeletedTogether_areNotPaired() async {
        let sut = makeSUT(
            batches: [[
                NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true),
                NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 2, parentHandle: 10, isFile: true)
            ]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(3, name: "song.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: nil, 2: nil]])
    }

    @Test("A removed file that is not audio is not paired with a namesake")
    func nonAudioRemovedNextToANamesake_isGone() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .removed, name: "photo.jpg", handle: 1, parentHandle: 10, isFile: true)]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "photo.jpg", parent: 10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: nil]])
    }

    @Test("A file moved to the Rubbish Bin with no folder to restore to, nor one known from the queue, is simply gone")
    func fileMovedToRubbishBinWithNoFolderKnown_isGone() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, parentHandle: 99, isFile: true)]],
            isInRubbishBin: true,
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "song.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: nil]])
    }

    @Test("A file whose folder is in the Rubbish Bin is simply gone")
    func fileInAFolderInTheRubbishBin_isGone() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "song.mp3", parent: 10)],
            rubbishBinNodes: [folder(10)]
        )

        let batches = await collectRemoved(sut)

        #expect(batches == [[1: nil]])
    }

    // MARK: - The folder a deleted file left

    /// The webclient moves the old file to the Rubbish Bin and only writes the folder to restore
    /// it to in a later update
    @Test("A file moved to the Rubbish Bin with no folder to restore to yet is looked up in the folder it was last known in")
    func fileMovedToRubbishBinBeforeItsRestoreFolder_isLookedUpInItsLastKnownFolder() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, parentHandle: 99, isFile: true)]],
            isInRubbishBin: true,
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "song.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut, queuedFolders: [1: 10])

        #expect(batches == [[1: 2]])
    }

    /// Only folder 10 exists, so a lookup in the last known folder 20 would find nothing
    @Test("The folder to restore to wins over the one the file was last known in")
    func restoreFolder_winsOverLastKnownFolder() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, restoreParentHandle: 10, parentHandle: 99, isFile: true)]],
            isInRubbishBin: true,
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "song.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut, queuedFolders: [1: 20])

        #expect(batches == [[1: 2]])
    }

    /// Only folder 10 exists, so a lookup in the last known folder 20 would find nothing
    @Test("A file deleted for good is looked up in the folder it had, not the one it was last known in")
    func fileDeletedForGood_isLookedUpInTheFolderItHad() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)]],
            nodesByHandle: [10: folder(10)],
            folderChildren: [file(2, name: "song.mp3", parent: 10)]
        )

        let batches = await collectRemoved(sut, queuedFolders: [1: 20])

        #expect(batches == [[1: 2]])
    }

    // MARK: - Only queued nodes

    @Test("An update touching no queued node is not emitted at all")
    func updateWithNoQueuedNode_emitsNothing() async {
        let sut = makeSUT(batches: [[NodeEntity(changeTypes: .removed, handle: 1)]])

        let batches = await collectRemoved(sut, queuedFolders: [:])

        #expect(batches.isEmpty)
    }

    @Test("Only the queued nodes among those deleted are reported")
    func onlyQueuedDeletedNodes_areReported() async {
        let sut = makeSUT(batches: [[
            NodeEntity(changeTypes: .removed, handle: 1),
            NodeEntity(changeTypes: .removed, handle: 2)
        ]])

        let batches = await collectRemoved(sut, queuedFolders: [1: .invalid])

        #expect(batches == [[1: nil]])
    }

    @Test("A file not in the queue becoming a version is not reported")
    func versionOfFileNotQueued_isNotReported() async {
        let sut = makeSUT(
            batches: [[NodeEntity(changeTypes: .parent, name: "song.mp3", handle: 1, parentHandle: 2, isFile: true)]],
            nodesByHandle: [
                2: file(2, name: "song.mp3", parent: 10),
                10: folder(10)
            ]
        )

        let batches = await collectRemoved(sut, queuedFolders: [3: 10])

        #expect(batches.isEmpty)
    }

    // MARK: - Folder link

    @Test("A node removed from the folder-link tree counts as deleted")
    func folderLink_removedNode_isDeleted() async {
        let sut = makeSUT(folderLinkBatches: [[NodeEntity(changeTypes: .removed, handle: 1)]])

        let batches = await collectRemovedFolderLink(sut)

        #expect(batches == [[1: nil]])
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

        let batches = await collectRemovedFolderLink(sut)

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

    // MARK: - Folder link replacement

    /// A folder link shows no versions: the replaced file leaves the tree and a file with
    /// its name arrives in its folder, in the same update.
    @Test("A removed file with a new file of its name in its folder is replaced, not deleted")
    func folderLink_removedFileWithANewNamesake_isReplaced() async {
        let batches: [[NodeEntity]] = [[
            NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true),
            NodeEntity(changeTypes: .counter, handle: 10, isFolder: true),
            NodeEntity(changeTypes: [.new, .name], name: "song.mp3", handle: 2, parentHandle: 10, isFile: true)
        ]]
        let nodes = [HandleEntity(2): StubPlayableNode(handle: 2, name: "song.mp3")]

        let removals = await collectRemovedFolderLink(makeSUT(folderLinkBatches: batches, folderLinkNodes: nodes))

        #expect(removals == [[1: 2]], "a replacement is not a deletion")
    }

    @Test(
        "A removed file without exactly one new namesake in its folder is deleted",
        arguments: [
            ("another folder", [NodeEntity(changeTypes: .new, name: "song.mp3", handle: 2, parentHandle: 20, isFile: true)]),
            ("another name", [NodeEntity(changeTypes: .new, name: "other.mp3", handle: 2, parentHandle: 10, isFile: true)]),
            ("two namesakes", [
                NodeEntity(changeTypes: .new, name: "song.mp3", handle: 2, parentHandle: 10, isFile: true),
                NodeEntity(changeTypes: .new, name: "song.mp3", handle: 3, parentHandle: 10, isFile: true)
            ]),
            ("a folder, not a file", [NodeEntity(changeTypes: .new, name: "song.mp3", handle: 2, parentHandle: 10, isFolder: true)])
        ]
    )
    func folderLink_removedFileWithoutOneNamesake_isDeleted(scenario: String, added: [NodeEntity]) async {
        let removed = NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)
        let batches = [[removed] + added]
        let nodes = [HandleEntity(2): StubPlayableNode(handle: 2), 3: StubPlayableNode(handle: 3)]

        let removals = await collectRemovedFolderLink(makeSUT(folderLinkBatches: batches, folderLinkNodes: nodes))

        #expect(removals == [[1: nil]], "\(scenario)")
    }

    /// Only an audio file can back a track, so only one is worth pairing — but any removal is
    /// still reported, whatever the name it left under.
    @Test("A file that is not audio is not paired with a new namesake, only reported gone")
    func folderLink_nonAudioWithANewNamesake_isDeleted() async {
        let batches: [[NodeEntity]] = [[
            NodeEntity(changeTypes: .removed, name: "photo.jpg", handle: 1, parentHandle: 10, isFile: true),
            NodeEntity(changeTypes: .new, name: "photo.jpg", handle: 2, parentHandle: 10, isFile: true)
        ]]
        let nodes = [HandleEntity(2): StubPlayableNode(handle: 2, name: "photo.jpg")]

        let removals = await collectRemovedFolderLink(makeSUT(folderLinkBatches: batches, folderLinkNodes: nodes))

        #expect(removals == [[1: nil]])
    }

    @Test("Two removed namesakes and one new file leave it open which was replaced, so both are deleted")
    func folderLink_twoRemovedNamesakes_areDeleted() async {
        let batches: [[NodeEntity]] = [[
            NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true),
            NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 3, parentHandle: 10, isFile: true),
            NodeEntity(changeTypes: .new, name: "song.mp3", handle: 2, parentHandle: 10, isFile: true)
        ]]
        let nodes = [HandleEntity(2): StubPlayableNode(handle: 2)]

        let removals = await collectRemovedFolderLink(makeSUT(folderLinkBatches: batches, folderLinkNodes: nodes))

        #expect(removals == [[1: nil, 3: nil]])
    }

    /// Only one update can pair the two; split across updates, the removal stands alone.
    @Test("A removal and a new namesake in separate updates are a deletion")
    func folderLink_removalAndNamesakeInSeparateUpdates_isADeletion() async {
        let batches: [[NodeEntity]] = [
            [NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true)],
            [NodeEntity(changeTypes: .new, name: "song.mp3", handle: 2, parentHandle: 10, isFile: true)]
        ]
        let nodes = [HandleEntity(2): StubPlayableNode(handle: 2)]

        let removals = await collectRemovedFolderLink(makeSUT(folderLinkBatches: batches, folderLinkNodes: nodes))

        #expect(removals == [[1: nil]])
    }

    @Test("A replaced file whose replacing file can no longer be found is reported as simply gone")
    func folderLink_unresolvableNewFile_isReportedWithoutANode() async {
        let batches: [[NodeEntity]] = [[
            NodeEntity(changeTypes: .removed, name: "song.mp3", handle: 1, parentHandle: 10, isFile: true),
            NodeEntity(changeTypes: .new, name: "song.mp3", handle: 2, parentHandle: 10, isFile: true)
        ]]

        let removals = await collectRemovedFolderLink(makeSUT(folderLinkBatches: batches))

        #expect(removals == [[1: nil]], "paired, but with nothing to stand in")
    }

    // MARK: - Helpers

    /// Every node these tests touch counts as queued, none in a folder known to the queue
    private static let everyNodeQueued: [HandleEntity: HandleEntity] = [1: .invalid, 2: .invalid, 3: .invalid]

    private func file(_ handle: HandleEntity, name: String = "", parent: HandleEntity) -> NodeEntity {
        NodeEntity(name: name, handle: handle, parentHandle: parent, isFile: true)
    }

    private func folder(_ handle: HandleEntity) -> NodeEntity {
        NodeEntity(handle: handle, isFolder: true)
    }

    private func makeSUT(
        batches: [[NodeEntity]] = [],
        folderLinkBatches: [[NodeEntity]] = [],
        isInRubbishBin: Bool = false,
        folderLinkNodes: [HandleEntity: StubPlayableNode] = [:],
        nodesByHandle: [HandleEntity: NodeEntity] = [:],
        folderChildren: [NodeEntity] = [],
        rubbishBinNodes: [NodeEntity] = []
    ) -> AudioNodeUpdatesUseCase {
        AudioNodeUpdatesUseCase(
            nodeRepository: MockNodeRepository(
                nodesForHandle: nodesByHandle,
                childrenNodes: folderChildren,
                nodeUpdates: finiteSequence(of: batches),
                folderLinkNodeUpdates: finiteSequence(of: folderLinkBatches),
                isInRubbishBinNodes: rubbishBinNodes
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
        for await batch in sut.removedNodes(queuedFolders: { Self.everyNodeQueued }) {
            batches.append(Set(batch.keys))
        }
        return batches
    }

    /// Each removed node's handle, mapped to the handle of the file standing in for it
    ///
    /// - Parameter queuedFolders: the queued nodes and the folder each was in; every node queued,
    ///   in a folder not known, unless told otherwise
    private func collectRemoved(
        _ sut: AudioNodeUpdatesUseCase,
        queuedFolders: [HandleEntity: HandleEntity] = Self.everyNodeQueued
    ) async -> [[HandleEntity: HandleEntity?]] {
        await collectRemovedNodes(sut, queuedFolders: queuedFolders).map { $0.mapValues { $0?.handle } }
    }

    private func collectRemovedNodes(
        _ sut: AudioNodeUpdatesUseCase,
        queuedFolders: [HandleEntity: HandleEntity] = Self.everyNodeQueued
    ) async -> [[HandleEntity: NodeEntity?]] {
        var batches: [[HandleEntity: NodeEntity?]] = []
        for await batch in sut.removedNodes(queuedFolders: { queuedFolders }) {
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

    /// Each removed node's handle, mapped to the handle of the node that replaced it
    private func collectRemovedFolderLink(_ sut: AudioNodeUpdatesUseCase) async -> [[HandleEntity: HandleEntity?]] {
        var batches: [[HandleEntity: HandleEntity?]] = []
        for await batch in sut.removedFolderLinkNodes {
            batches.append(batch.mapValues { $0?.handle })
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
