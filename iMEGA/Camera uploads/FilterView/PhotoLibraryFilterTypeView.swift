import MEGASwiftUI
import SwiftUI

struct PhotoLibraryFilterTypeView: View {
    let type: PhotosFilterType
    
    @ObservedObject var filterViewModel: PhotoLibraryFilterViewModel
    
    private var selected: Bool {
        type == filterViewModel.selectedMediaType
    }
    
    private var foreground: Color {
        selected ? .white : Colors.Photos.filterNormalTextForeground.swiftUIColor
    }
    
    private var background: Color {
        selected ? Colors.Photos.filterTypeSelectionBackground.swiftUIColor : Colors.Photos.filterTypeNormalBackground.swiftUIColor
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
