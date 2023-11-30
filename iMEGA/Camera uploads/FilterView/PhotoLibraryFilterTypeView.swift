import MEGASwiftUI
import SwiftUI

struct PhotoLibraryFilterTypeView: View {
    let type: PhotosFilterType
    
    @ObservedObject var filterViewModel: PhotoLibraryFilterViewModel
    
    private var selected: Bool {
        type == filterViewModel.selectedMediaType
    }
    
    private var foreground: Color {
        selected ? .white : Color.photosFilterNormalTextForeground
    }
    
    private var background: Color {
        selected ? Color.photosFilterTypeSelectionBackground : Color.photosFilterTypeNormalBackground
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
