import MEGADomain
import MEGAL10n

extension NodeEntity {
    /// Name of a Recents bucket's parent folder. While the SDK cannot decrypt a node's
    /// attributes it reports the name "NO_KEY", so show the undecrypted placeholder instead.
    var recentParentFolderName: String {
        isNodeKeyDecrypted ? name : Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
    }
}
