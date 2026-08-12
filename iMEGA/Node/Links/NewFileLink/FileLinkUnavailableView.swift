import MEGADomain
import SwiftUI

/// Unavailable state of a file link. The screen it belongs to only exists with the link revamp flag
/// on, so there is no legacy layout to fall back to: it always shows the revamped empty state, the
/// same one the folder link shows.
struct FileLinkUnavailableView: View {
    let reason: LinkUnavailableReason

    var body: some View {
        LinkUnavailableContentView(reason: reason, copy: .fileLink)
    }
}

#Preview("Generic") {
    FileLinkUnavailableView(reason: .generic)
}

#Preview("Expired") {
    FileLinkUnavailableView(reason: .expired)
}
