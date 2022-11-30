import SwiftUI

struct PhotoYearCard: View {
    @StateObject var viewModel: PhotoYearCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel) {
            Text(viewModel.title)
                .font(.title2.bold())
        }
    }
}

extension PhotoYearCard: Equatable {
    static func == (lhs: PhotoYearCard, rhs: PhotoYearCard) -> Bool {
        true // we are taking over the update of the view
    }
}
