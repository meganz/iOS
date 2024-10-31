import SwiftUI

public struct PhotoCell: View {
    @StateObject private var viewModel: PhotoCellViewModel
    
    public init(viewModel: @autoclosure @escaping () -> PhotoCellViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        PhotoCellContent(viewModel: viewModel)
    }
}

extension PhotoCell: Equatable {
     public static func == (lhs: PhotoCell, rhs: PhotoCell) -> Bool {
        true // we are taking over the update of the view
    }
}
