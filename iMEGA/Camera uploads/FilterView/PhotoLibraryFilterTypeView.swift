import MEGASwiftUI
import SwiftUI

struct PhotoLibraryFilterTypeView: View {
    let type: PhotosFilterType
    
    @ObservedObject var filterViewModel: PhotoLibraryFilterViewModel
    
    private var selected: Bool {
        type == filterViewModel.selectedMediaType
    }
    
    private var foreground: Color {
        selected ? MEGAAppColor.White._FFFFFF.color : MEGAAppColor.Photos.filterNormalTextForeground.color
    }
    
    private var background: Color {
        selected ? MEGAAppColor.Photos.filterTypeSelectionBackground.color : MEGAAppColor.Photos.filterTypeNormalBackground.color
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
