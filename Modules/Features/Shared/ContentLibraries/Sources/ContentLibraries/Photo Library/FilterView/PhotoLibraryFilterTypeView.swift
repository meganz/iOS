import MEGAAppPresentation
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PhotoLibraryFilterTypeView: View {
    let type: PhotosFilterType
    
    @ObservedObject var filterViewModel: PhotoLibraryFilterViewModel
    
    private var selected: Bool {
        type == filterViewModel.selectedMediaType
    }
    
    private var foreground: Color {
        selected ? TokenColors.Text.inverseAccent.swiftUI : TokenColors.Text.primary.swiftUI
    }
    
    private var background: Color {
        selected ? TokenColors.Components.selectionControl.swiftUI : TokenColors.Button.secondary.swiftUI
    }
    
    var body: some View {
        PillView(
            viewModel: .init(
                title: type.localization,
                icon: selected ? .leading(Image(systemName: "checkmark")) : .none,
                foreground: foreground,
                background: background
            )
        )
        .onTapGesture {
            filterViewModel.selectedMediaType = type
        }
    }
}
