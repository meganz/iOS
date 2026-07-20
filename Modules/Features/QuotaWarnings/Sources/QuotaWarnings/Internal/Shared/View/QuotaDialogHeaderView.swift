import SwiftUI

struct QuotaDialogHeaderView: View {
    private let header: QuotaDialogHeader

    init(header: QuotaDialogHeader) {
        self.header = header
    }

    var body: some View {
        switch header {
        case let .storage(header):
            StorageQuotaHeaderView(header: header)
        case let .transfer(header):
            TransferQuotaHeaderView(header: header)
        }
    }
}
