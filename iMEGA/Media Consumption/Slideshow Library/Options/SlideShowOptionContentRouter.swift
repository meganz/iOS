import SwiftUI

protocol SlideShowOptionContentRouting {
    func slideShowOptionCell(for viewModel: SlideShowOptionCellViewModel) -> SlideShowOptionCellView
    func slideShowOptionDetailView(for viewModel: SlideShowOptionCellViewModel, isShowing: Binding<Bool>) -> SlideShowOptionDetailView
}

struct SlideShowOptionContentRouter: SlideShowOptionContentRouting {
    func slideShowOptionCell(for viewModel: SlideShowOptionCellViewModel) -> SlideShowOptionCellView {
        SlideShowOptionCellView(cellModel: viewModel)
    }
    
    func slideShowOptionDetailView(for viewModel: SlideShowOptionCellViewModel, isShowing: Binding<Bool>) -> SlideShowOptionDetailView {
        SlideShowOptionDetailView(viewModel: viewModel, isShowing: isShowing)
    }
}
