import MEGASwiftUI
import SwiftUI

struct PhotoLibraryPicker: View {
    @Environment(\.editMode) var editMode
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedMode: PhotoLibraryViewMode
    
    var body: some View {
        pickerView()
            .padding(16)
            .opacity(editMode?.wrappedValue.isEditing == true ? 0 : 1)
    }
    
    private func pickerView() -> some View {
        Picker("View Mode", selection: $selectedMode) {
            ForEach(PhotoLibraryViewMode.allCases) {
                Text($0.title)
                    .font(.headline)
                    .bold()
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
        .background(
            MEGAAppColor.Background.backgroundRegularPrimaryElevated.color
                .cornerRadius(7, corners: .allCorners)
        )
    }
}
