import MEGADesignToken
import MEGAPresentation
import SwiftUI

struct PhotoLibraryFilterLocationView: View {
    let location: PhotosFilterLocation
    
    @ObservedObject var filterViewModel: PhotoLibraryFilterViewModel
    
    var btnSelectedLabel: some View {
        HStack {
            Text(location.localization)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundStyle(
                    TokenColors.Support.success.swiftUI
                )
                .offset(x: 5, y: 0)
        }
    }
    
    var btnNormalLabel: some View {
        HStack {
            Text(location.localization)
            Spacer()
        }
    }
    
    var btnNormal: some View {
        Button {
            filterViewModel.selectedLocation = location
        } label: {
            btnNormalLabel
        }
    }
    
    var selected: Bool {
        location == filterViewModel.selectedLocation
    }
    
    var body: some View {
        HStack {
            if selected {
                btnSelectedLabel
            } else {
                btnNormal
            }
            Spacer()
        }
        .foregroundStyle(
            TokenColors.Text.primary.swiftUI
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
