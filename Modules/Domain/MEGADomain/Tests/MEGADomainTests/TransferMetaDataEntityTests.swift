import MEGADomain
import MEGADomainMock
import Testing

/// Covers the `appData` strings a transfer is tagged with.
///
/// The raw values are the SDK's wire format, not a detail of the enum: a download writes one into
/// `appData` when it starts, and whoever picks the transfer up later -- the Transfers list, the
/// save handlers -- reads the string back to tell what the download was for. Renaming one silently
/// unlinks the two halves, so they are pinned here.
@Suite("TransferMetaDataEntity Tests")
struct TransferMetaDataEntityTests {

    @Test(
        "Each kind of download is tagged with the string the SDK carries",
        arguments: [
            (TransferMetaDataEntity.exportFile, ">exportFile"),
            (.saveInPhotos, ">SaveInPhotosApp"),
            (.makeAvailableOffline, ">makeAvailableOffline")
        ]
    )
    func rawValue(metaData: TransferMetaDataEntity, expected: String) {
        #expect(metaData.rawValue == expected)
    }

    @Test("A tag read back off a transfer resolves to the kind that wrote it")
    func initFromRawValue() {
        #expect(TransferMetaDataEntity(rawValue: ">exportFile") == .exportFile)
        #expect(TransferMetaDataEntity(rawValue: ">SaveInPhotosApp") == .saveInPhotos)
        #expect(TransferMetaDataEntity(rawValue: ">makeAvailableOffline") == .makeAvailableOffline)
    }

    @Test("Anything else is not one of ours")
    func initFromUnknownRawValue() {
        #expect(TransferMetaDataEntity(rawValue: "SaveInPhotosApp") == nil)
        #expect(TransferMetaDataEntity(rawValue: "") == nil)
    }
}

/// Covers how a transfer is recognised as one that ended up in the Photos library.
@Suite("TransferEntity save to Photos Tests")
struct TransferEntityIsSavedToPhotosTests {

    @Test("A download tagged as saved to Photos is recognised as one")
    func appDataHoldingTheTag() {
        #expect(TransferEntity(appData: ">SaveInPhotosApp").isSavedToPhotos)
    }

    @Test("The tag is still found when the transfer carries more than one")
    func appDataHoldingSeveralTags() {
        #expect(TransferEntity(appData: ">exportFile>SaveInPhotosApp").isSavedToPhotos)
    }

    @Test(
        "A download tagged as anything else, or as nothing, is not",
        arguments: [nil, "", ">exportFile", ">makeAvailableOffline"]
    )
    func appDataWithoutTheTag(appData: String?) {
        #expect(TransferEntity(appData: appData).isSavedToPhotos == false)
    }
}
