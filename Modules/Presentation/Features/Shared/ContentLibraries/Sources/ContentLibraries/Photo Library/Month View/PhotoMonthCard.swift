import SwiftUI

public struct PhotoMonthCard: View {
    @StateObject private var viewModel: PhotoMonthCardViewModel
    
    public init(viewModel: @autoclosure @escaping () -> PhotoMonthCardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        PhotoCard(viewModel: viewModel) {
            Text(viewModel.attributedTitle)
        }
    }
}
