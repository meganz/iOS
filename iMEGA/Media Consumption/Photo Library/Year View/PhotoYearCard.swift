import SwiftUI

@available(iOS 14.0, *)
struct PhotoYearCard: View {
    @StateObject var viewModel: PhotoYearCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel) {
            Text(viewModel.title)
                .font(.title2.bold())
        }
    }
}

@available(iOS 14.0, *)
extension PhotoYearCard: Equatable {
    static func == (lhs: PhotoYearCard, rhs: PhotoYearCard) -> Bool {
        true // we are taking over the update of the view
    }
}
