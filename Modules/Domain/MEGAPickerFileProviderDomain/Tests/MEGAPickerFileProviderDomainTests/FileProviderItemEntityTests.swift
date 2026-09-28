import FileProvider
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderItemEntityTests {
    private static let modificationTime = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func contentVersion_ofFileWithFingerprint_isTheFingerprint() {
        let item = makeItem(node: NodeEntity(fingerprint: "fingerprint", isFile: true))

        #expect(item.contentVersion == Data("fingerprint".utf8))
    }

    @Test(arguments: [nil, ""])
    func contentVersion_ofFileWithoutFingerprint_changesWithSizeAndModificationTime(fingerprint: String?) {
        let item = makeItem(node: NodeEntity(fingerprint: fingerprint, isFile: true, size: 10, modificationTime: Self.modificationTime))
        let resized = makeItem(node: NodeEntity(fingerprint: fingerprint, isFile: true, size: 11, modificationTime: Self.modificationTime))
        let touched = makeItem(node: NodeEntity(fingerprint: fingerprint, isFile: true, size: 10, modificationTime: Self.modificationTime + 1))

        #expect(item.contentVersion != resized.contentVersion)
        #expect(item.contentVersion != touched.contentVersion)
    }

    @Test
    func contentVersion_ofFolder_doesNotChangeWithModificationTime() {
        let folder = makeItem(node: NodeEntity(isFolder: true, modificationTime: Self.modificationTime))
        let touched = makeItem(node: NodeEntity(isFolder: true, modificationTime: Self.modificationTime + 1))

        #expect(folder.contentVersion == touched.contentVersion)
    }

    @Test
    func versions_ofTheSameNodeState_areEqual() {
        let item = makeItem(node: NodeEntity(name: "a.txt", isFile: true, size: 10, modificationTime: Self.modificationTime))
        let sameItem = makeItem(node: NodeEntity(name: "a.txt", isFile: true, size: 10, modificationTime: Self.modificationTime))

        #expect(item.contentVersion == sameItem.contentVersion)
        #expect(item.metadataVersion == sameItem.metadataVersion)
    }

    @Test
    func metadataVersion_changesWithNameParentAndModificationTime() {
        let item = makeItem(node: NodeEntity(name: "a.txt", modificationTime: Self.modificationTime))
        let renamed = makeItem(node: NodeEntity(name: "b.txt", modificationTime: Self.modificationTime))
        let trashed = makeItem(parentIdentifier: .trashContainer, node: NodeEntity(name: "a.txt", modificationTime: Self.modificationTime))
        let touched = makeItem(node: NodeEntity(name: "a.txt", modificationTime: Self.modificationTime + 1))

        #expect(item.metadataVersion != renamed.metadataVersion)
        #expect(item.metadataVersion != trashed.metadataVersion)
        #expect(item.metadataVersion != touched.metadataVersion)
    }

    @Test
    func metadataVersion_changesWithChildCount() {
        let node = NodeEntity(isFolder: true, modificationTime: Self.modificationTime)
        let folder = makeItem(node: node, childCount: 1)
        let grown = makeItem(node: node, childCount: 2)

        #expect(folder.metadataVersion != grown.metadataVersion)
    }

    @Test
    func metadataVersion_doesNotMixUpValuesAcrossFields() {
        let item = makeItem(parentIdentifier: NSFileProviderItemIdentifier("b"), node: NodeEntity(name: "a", modificationTime: Self.modificationTime))
        let shifted = makeItem(
            parentIdentifier: NSFileProviderItemIdentifier(""),
            node: NodeEntity(name: "ab", modificationTime: Self.modificationTime)
        )

        #expect(item.metadataVersion != shifted.metadataVersion)
    }

    private func makeItem(
        parentIdentifier: NSFileProviderItemIdentifier = .rootContainer,
        node: NodeEntity,
        childCount: Int? = nil
    ) -> FileProviderItemEntity {
        FileProviderItemEntity(
            identifier: NSFileProviderItemIdentifier("item"),
            parentIdentifier: parentIdentifier,
            node: node,
            childCount: childCount
        )
    }
}

struct NSFileProviderPageOffsetTests {
    @Test(arguments: [0, 1, 200, 12_345])
    func offset_ofPageCreatedWithOffset_isThatOffset(offset: Int) {
        #expect(NSFileProviderPage(offset: offset).offset == offset)
    }

    @Test(arguments: [
        NSFileProviderPage.initialPageSortedByName as Data,
        NSFileProviderPage.initialPageSortedByDate as Data,
        Data("-1".utf8)
    ])
    func offset_ofPageThatIsNotAnOffset_isZero(pageData: Data) {
        #expect(NSFileProviderPage(pageData).offset == 0)
    }
}
