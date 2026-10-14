import FileProvider
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderItemUseCaseTests {
    private static let rootNode = NodeEntity(handle: 1, base64Handle: "1", isFolder: true)
    private static let rubbishNode = NodeEntity(handle: 2, base64Handle: "2", isFolder: true)

    @Test
    func item_forRootContainer_returnsRootNode() throws {
        let sut = makeSUT(nodeRepo: MockNodeRepository(nodeRoot: Self.rootNode))

        let item = try sut.item(for: .rootContainer)

        #expect(item == FileProviderItemEntity(identifier: .rootContainer, parentIdentifier: .rootContainer, node: Self.rootNode, childCount: 0))
    }

    @Test
    func item_forTrashContainer_returnsRubbishBinNode() throws {
        let sut = makeSUT(nodeRepo: MockNodeRepository(rubbishBinNode: Self.rubbishNode))

        let item = try sut.item(for: .trashContainer)

        #expect(item == FileProviderItemEntity(identifier: .trashContainer, parentIdentifier: .rootContainer, node: Self.rubbishNode, childCount: 0))
    }

    @Test
    func item_forNodeInCloudDriveRoot_hasRootContainerAsParent() throws {
        let node = NodeEntity(handle: 10, base64Handle: "10", parentHandle: Self.rootNode.handle, isFile: true)
        let sut = makeSUT(nodeRepo: MockNodeRepository(node: node, rubbishBinNode: Self.rubbishNode, nodeRoot: Self.rootNode))

        let item = try sut.item(for: NSFileProviderItemIdentifier("10"))

        #expect(item == FileProviderItemEntity(identifier: NSFileProviderItemIdentifier("10"), parentIdentifier: .rootContainer, node: node))
    }

    @Test
    func item_forNodeInRubbishBin_hasTrashContainerAsParent() throws {
        let node = NodeEntity(handle: 10, base64Handle: "10", parentHandle: Self.rubbishNode.handle, isFile: true)
        let sut = makeSUT(nodeRepo: MockNodeRepository(node: node, rubbishBinNode: Self.rubbishNode, nodeRoot: Self.rootNode))

        let item = try sut.item(for: NSFileProviderItemIdentifier("10"))

        #expect(item.parentIdentifier == .trashContainer)
    }

    @Test
    func item_forNodeInAFolder_hasTheFolderAsParent() throws {
        let folder = NodeEntity(handle: 20, base64Handle: "20", parentHandle: Self.rootNode.handle, isFolder: true)
        let node = NodeEntity(handle: 10, base64Handle: "10", parentHandle: folder.handle, isFile: true)
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: [folder, node]))

        let item = try sut.item(for: NSFileProviderItemIdentifier("10"))

        #expect(item.parentIdentifier == NSFileProviderItemIdentifier("20"))
    }

    @Test
    func item_forAnEarlierVersionOfAFile_throwsNoSuchItem() {
        let file = NodeEntity(handle: 20, base64Handle: "20", parentHandle: Self.rootNode.handle, isFile: true)
        let version = NodeEntity(handle: 10, base64Handle: "10", parentHandle: file.handle, isFile: true)
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: [file, version]))

        #expect(throws: NSFileProviderError(.noSuchItem)) {
            try sut.item(for: NSFileProviderItemIdentifier("10"))
        }
    }

    @Test(arguments: [NSFileProviderItemIdentifier("10"), NSFileProviderItemIdentifier("not a handle"), .rootContainer, .trashContainer])
    func item_whenNodeDoesNotExist_throwsNoSuchItem(identifier: NSFileProviderItemIdentifier) {
        let sut = makeSUT(nodeRepo: MockNodeRepository())

        #expect(throws: NSFileProviderError(.noSuchItem)) {
            try sut.item(for: identifier)
        }
    }

    @Test(arguments: [
        (NSFileProviderItemIdentifier.rootContainer, rootNode),
        (NSFileProviderItemIdentifier.trashContainer, rubbishNode)
    ])
    func children_ofContainer_haveContainerAsParent(containerIdentifier: NSFileProviderItemIdentifier, container: NodeEntity) async throws {
        let children = [
            NodeEntity(handle: 10, base64Handle: "10", isFolder: true),
            NodeEntity(handle: 11, base64Handle: "11", isFile: true)
        ]
        let sut = makeSUT(
            filesSearchRepo: MockFilesSearchRepository(nodesForHandle: [container.handle: children]),
            nodeRepo: MockNodeRepository(rubbishBinNode: Self.rubbishNode, nodeRoot: Self.rootNode)
        )

        let items = try await sut.children(of: containerIdentifier, page: SearchPageEntity(startingOffset: 0, pageSize: 0))

        #expect(items == [
            FileProviderItemEntity(
                identifier: NSFileProviderItemIdentifier("10"),
                parentIdentifier: containerIdentifier,
                node: children[0],
                childCount: 0
            ),
            FileProviderItemEntity(identifier: NSFileProviderItemIdentifier("11"), parentIdentifier: containerIdentifier, node: children[1])
        ])
    }

    @Test
    func children_ofFolder_searchesTheFolderOnlyForNonSensitiveNodes() async throws {
        let folder = NodeEntity(handle: 10, base64Handle: "10", isFolder: true)
        let filesSearchRepo = MockFilesSearchRepository(nodesForHandle: [folder.handle: []])
        let sut = makeSUT(filesSearchRepo: filesSearchRepo, nodeRepo: MockNodeRepository(node: folder))

        _ = try await sut.children(of: NSFileProviderItemIdentifier("10"), page: SearchPageEntity(startingOffset: 0, pageSize: 0))

        let filter = try #require(filesSearchRepo.searchedFilters.first)
        #expect(filter.recursive == false)
        #expect(filter.sensitiveFilterOption == .nonSensitiveOnly)
    }

    @Test
    func children_ofFile_throwsNoSuchItem() async {
        let file = NodeEntity(handle: 10, base64Handle: "10", isFile: true)
        let sut = makeSUT(nodeRepo: MockNodeRepository(node: file))

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.children(of: NSFileProviderItemIdentifier("10"), page: SearchPageEntity(startingOffset: 0, pageSize: 0))
        }
    }

    @Test
    func item_forFolder_hasItsChildCount() throws {
        let folder = NodeEntity(handle: 10, base64Handle: "10", parentHandle: Self.rootNode.handle, isFolder: true)
        let sut = makeSUT(
            nodeRepo: MockNodeRepository(node: folder, nodeRoot: Self.rootNode),
            nodeAttributeRepo: MockNodeAttributeRepository(children: 3)
        )

        #expect(try sut.item(for: NSFileProviderItemIdentifier("10")).childCount == 3)
    }

    @Test
    func children_haveAChildCountForFoldersOnly() async throws {
        let children = [
            NodeEntity(handle: 10, base64Handle: "10", isFolder: true),
            NodeEntity(handle: 11, base64Handle: "11", isFile: true)
        ]
        let sut = makeSUT(
            filesSearchRepo: MockFilesSearchRepository(nodesForHandle: [Self.rootNode.handle: children]),
            nodeRepo: MockNodeRepository(nodeRoot: Self.rootNode),
            nodeAttributeRepo: MockNodeAttributeRepository(children: 3)
        )

        let items = try await sut.children(of: .rootContainer, page: SearchPageEntity(startingOffset: 0, pageSize: 0))

        #expect(items.map(\.childCount) == [3, nil])
    }

    @Test
    func presentableItem_whenTheNodeTreeIsNotLoaded_throwsCannotSynchronize() {
        let sut = makeSUT(nodeRepo: MockNodeRepository())

        #expect(throws: NSFileProviderError(.cannotSynchronize)) {
            try sut.presentableItem(for: NSFileProviderItemIdentifier("10"))
        }
    }

    @Test(arguments: [NSFileProviderItemIdentifier.rootContainer, .trashContainer])
    func presentableItem_forAContainer_isTheContainer(identifier: NSFileProviderItemIdentifier) throws {
        let sut = makeSUT(nodeRepo: MockNodeRepository(rubbishBinNode: Self.rubbishNode, nodeRoot: Self.rootNode))

        #expect(try sut.presentableItem(for: identifier) == sut.item(for: identifier))
    }

    @Test
    func presentableItem_forAMissingRubbishBin_throwsCannotSynchronize() {
        let sut = makeSUT(nodeRepo: MockNodeRepository(nodeRoot: Self.rootNode))

        #expect(throws: NSFileProviderError(.cannotSynchronize)) {
            try sut.presentableItem(for: .trashContainer)
        }
    }

    @Test
    func presentableItem_forANodeInAFolder_hasTheFolderAsParent() throws {
        let folder = NodeEntity(handle: 20, base64Handle: "20", parentHandle: Self.rootNode.handle, isFolder: true)
        let node = NodeEntity(handle: 10, base64Handle: "10", parentHandle: folder.handle, isFile: true)
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: [folder, node]))

        let item = try sut.presentableItem(for: NSFileProviderItemIdentifier("10"))

        #expect(item == FileProviderItemEntity(identifier: NSFileProviderItemIdentifier("10"), parentIdentifier: NSFileProviderItemIdentifier("20"), node: node))
    }

    @Test
    func presentableItem_forANodeInTheRubbishBin_hasTheTrashAsParent() throws {
        let node = NodeEntity(handle: 10, base64Handle: "10", parentHandle: Self.rubbishNode.handle, isFile: true)
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: [node]))

        #expect(try sut.presentableItem(for: NSFileProviderItemIdentifier("10"))?.parentIdentifier == .trashContainer)
    }

    @Test
    func presentableItem_forAMissingNode_isNil() throws {
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: []))

        #expect(try sut.presentableItem(for: NSFileProviderItemIdentifier("10")) == nil)
    }

    @Test
    func presentableItem_forAnEarlierVersionOfAFile_isNil() throws {
        let file = NodeEntity(handle: 20, base64Handle: "20", parentHandle: Self.rootNode.handle, isFile: true)
        let version = NodeEntity(handle: 10, base64Handle: "10", parentHandle: file.handle, isFile: true)
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: [file, version]))

        #expect(try sut.presentableItem(for: NSFileProviderItemIdentifier("10")) == nil)
    }

    @Test
    func presentableItem_forANodeOutsideTheCloudDriveAndTheRubbishBin_isNil() throws {
        let incomingShare = NodeEntity(handle: 20, base64Handle: "20", parentHandle: 99, isFolder: true)
        let node = NodeEntity(handle: 10, base64Handle: "10", parentHandle: incomingShare.handle, isFile: true)
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: [incomingShare, node]))

        #expect(try sut.presentableItem(for: NSFileProviderItemIdentifier("10")) == nil)
    }

    @Test(arguments: [(true, false), (false, true)])
    func presentableItem_forASensitiveNode_isNil(isMarkedSensitive: Bool, isInheritingSensitivity: Bool) throws {
        let node = NodeEntity(handle: 10, base64Handle: "10", parentHandle: Self.rootNode.handle, isFile: true, isMarkedSensitive: isMarkedSensitive)
        let sut = makeSUT(nodeRepo: makeNodeRepo(nodes: [node], isInheritingSensitivity: isInheritingSensitivity))

        #expect(try sut.presentableItem(for: NSFileProviderItemIdentifier("10")) == nil)
    }

    private func makeNodeRepo(nodes: [NodeEntity], isInheritingSensitivity: Bool = false) -> MockNodeRepository {
        let allNodes = nodes + [Self.rootNode, Self.rubbishNode]
        return MockNodeRepository(
            nodesForHandle: Dictionary(uniqueKeysWithValues: allNodes.map { ($0.handle, $0) }),
            rubbishBinNode: Self.rubbishNode,
            nodeRoot: Self.rootNode,
            isInheritingSensitivityResult: .success(isInheritingSensitivity)
        )
    }

    private func makeSUT(
        filesSearchRepo: MockFilesSearchRepository = MockFilesSearchRepository(),
        nodeRepo: MockNodeRepository = MockNodeRepository(),
        nodeAttributeRepo: MockNodeAttributeRepository = MockNodeAttributeRepository()
    ) -> FileProviderItemUseCase<MockFilesSearchRepository, MockNodeRepository, MockMEGAHandleRepository, MockNodeAttributeRepository> {
        FileProviderItemUseCase(
            filesSearchRepo: filesSearchRepo,
            nodeRepo: nodeRepo,
            megaHandleRepo: MockMEGAHandleRepository(),
            nodeAttributeRepo: nodeAttributeRepo
        )
    }
}
