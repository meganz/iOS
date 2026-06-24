import MEGADomain
import MEGASdk

public extension TransferEntity {
    func toMEGATransfer(in sdk: MEGASdk) -> MEGATransfer? {
        sdk.transfer(byTag: tag)
    }

    /// Whether the transfer was a download saved into the Photos library, encoded in
    /// `appData`. Such downloads have no deep-linkable folder, so the Transfers list
    /// hides `View in folder` for them. The `>SaveInPhotosApp` raw value mapping lives
    /// in this Data layer (see `TransferMetaDataEntity+Mapper`).
    var isSavedToPhotos: Bool {
        appData?.contains(TransferMetaDataEntity.saveInPhotos.rawValue) ?? false
    }
}

public extension Array where Element == TransferEntity {
    func toMEGATransfers(in sdk: MEGASdk) -> [MEGATransfer] {
        compactMap { $0.toMEGATransfer(in: sdk) }
    }
}
