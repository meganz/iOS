import MEGASwiftUI
import SwiftUI

struct PhotoLibraryPicker: View {
    @Environment(\.editMode) var editMode
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
        .blurBackground()
    }
}
