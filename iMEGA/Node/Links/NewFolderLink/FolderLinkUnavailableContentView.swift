import MEGADomain
import SwiftUI

/// Folder link's binding of the shared unavailable layout to its own copy.
struct FolderLinkUnavailableContentView: View {
    let reason: LinkUnavailableReason

    var body: some View {
        LinkUnavailableContentView(reason: reason, copy: .folderLink)
    }
}

#Preview("Generic") {
    FolderLinkUnavailableContentView(reason: .generic)
}

#Preview("Copyright suspension") {
    FolderLinkUnavailableContentView(reason: .copyrightSuspension)
}
