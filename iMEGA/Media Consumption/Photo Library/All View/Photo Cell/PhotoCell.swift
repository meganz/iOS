import SwiftUI

struct PhotoCell: View {
    @StateObject var viewModel: PhotoCellViewModel
    var body: some View {
        PhotoCellContent(viewModel: viewModel)
    }
}

extension PhotoCell: Equatable {
    static func == (lhs: PhotoCell, rhs: PhotoCell) -> Bool {
        true // we are taking over the update of the view
    }
}
