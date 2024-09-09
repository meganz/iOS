import Foundation
import SwiftUI

public struct SnackBarView: View {
    
    enum Implementation {
        case viewModel(SnackBarViewModel)
        case snackBar(SnackBar)
    }
    
    private let implementation: Implementation
    
    public init(viewModel: SnackBarViewModel) {
        implementation = .viewModel(viewModel)
    }
    
    public init(snackBar: SnackBar) {
        implementation = .snackBar(snackBar)
    }
    
    public var body: some View {
        switch implementation {
        case .viewModel(let viewModel):
            SnackBarViewModelContainerView(viewModel: viewModel)
        case .snackBar(let snackBar):
            SnackBarItemView(snackBar: snackBar)
        }
    }
}
