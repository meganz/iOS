import SwiftUI

public struct PhotoYearCard: View {
    @StateObject private var viewModel: PhotoYearCardViewModel
    
    public init(viewModel: @autoclosure @escaping () -> PhotoYearCardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        PhotoCard(viewModel: viewModel) {
            Text(viewModel.title)
                .font(.title2.bold())
        }
    }
}

extension PhotoYearCard: Equatable {
    nonisolated public static func == (lhs: PhotoYearCard, rhs: PhotoYearCard) -> Bool {
        true // we are taking over the update of the view
    }
}
