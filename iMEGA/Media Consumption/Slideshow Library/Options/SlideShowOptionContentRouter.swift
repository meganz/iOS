import SwiftUI

@available(iOS 14.0, *)
protocol SlideShowOptionContentRouting {
    func slideShowOptionCell(for viewModel: SlideShowOptionCellViewModel) -> SlideShowOptionCellView
    func slideShowOptionDetailView(for viewModel: SlideShowOptionCellViewModel, isShowing: Binding<Bool>) -> SlideShowOptionDetailView
}

@available(iOS 14.0, *)
struct SlideShowOptionContentRouter: SlideShowOptionContentRouting {
    func slideShowOptionCell(for viewModel: SlideShowOptionCellViewModel) -> SlideShowOptionCellView {
        SlideShowOptionCellView(cellModel: viewModel)
    }
    
    func slideShowOptionDetailView(for viewModel: SlideShowOptionCellViewModel, isShowing: Binding<Bool>) -> SlideShowOptionDetailView {
        SlideShowOptionDetailView(viewModel: viewModel, isShowing: isShowing)
    }
}
