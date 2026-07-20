import SwiftUI

/// Presentation model for the dialog header, produced by the mapper so the header views stay dumb.
/// Storage and transfer are distinct cases because they render differently (transfer carries an inline
/// "Learn more" link), so `QuotaDialogHeaderView` picks the matching subview.
enum QuotaDialogHeader {
    case storage(StorageQuotaHeader)
    case transfer(TransferQuotaHeader)
}

struct StorageQuotaHeader {
    let image: Image
    let title: String
    let subtitle: String
}

struct TransferQuotaHeader {
    struct LearnMore {
        let text: String
        let url: URL
    }

    let image: Image
    let title: String
    let subtitle: String
    let learnMore: LearnMore
}
