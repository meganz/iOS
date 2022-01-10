import SwiftUI

@available(iOS 14.0, *)
struct PhotoMonthCard: View {
    @StateObject var viewModel: PhotoMonthCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel) {
            if #available(iOS 15.0, *) {
                Text(viewModel.attributedTitle)
            } else {
                Text(viewModel.title)
                    .font(.title2.bold())
            }
        }
    }
}

@available(iOS 14.0, *)
extension PhotoMonthCard: Equatable {
    static func == (lhs: PhotoMonthCard, rhs: PhotoMonthCard) -> Bool {
        true // we are taking over the update of the view
    }
}
