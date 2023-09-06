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
    
    private var icon: Image? {
        selected ? Image(systemName: "checkmark") : nil
    }
    
    var body: some View {
        PillView(
            viewModel: .init(
                title: type.localization,
                icon: icon,
                foreground: foreground,
                background: background
            )
        )
        .onTapGesture {
            filterViewModel.selectedMediaType = type
        }
    }
}
