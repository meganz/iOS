import SwiftUI

struct PhotoLibraryFilterTypeView: View {
    let type: PhotosFilterType
    
    @ObservedObject var filterViewModel: PhotoLibraryFilterViewModel
    
    var btnSelectedLabel: some View {
        HStack(spacing: 4){
            Image(systemName: "checkmark")
            Text(type.localization)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(Colors.Photos.filterTypeSelectionBackground.color))
    }
    
    var btnNormalLabel: some View {
        Text(type.localization)
            .foregroundColor(Color(Colors.Photos.filterNormalTextForeground.color))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(Colors.Photos.filterTypeNormalBackground.color))
    }
    
    var btnNormal: some View {
        Button {
            filterViewModel.selectedMediaType = type
        } label: {
            btnNormalLabel
        }
    }
    
    var selected: Bool {
        type == filterViewModel.selectedMediaType
    }
    
    var body: some View {
        ZStack {
            if selected {
                btnSelectedLabel
            } else {
                btnNormal
            }
        }
        .font(.system(size: 15, weight: .medium, design: .default))
        .cornerRadius(8)
    }
}
