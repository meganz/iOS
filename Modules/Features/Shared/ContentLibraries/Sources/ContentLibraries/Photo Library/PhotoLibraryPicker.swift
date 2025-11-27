import MEGASwiftUI
import SwiftUI

struct PhotoLibraryPicker: View {
    @Environment(\.editMode) var editMode
    @Binding var selectedMode: PhotoLibraryViewMode
    
    var body: some View {
        pickerView
            .padding(16)
            .opacity(editMode?.wrappedValue.isEditing == true ? 0 : 1)
    }
}

private extension PhotoLibraryPicker {
    private var basePicker: some View {
        Picker("View Mode", selection: $selectedMode) {
            ForEach(PhotoLibraryViewMode.allCases) { mode in
                Text(mode.title)
                    .font(.headline)
                    .bold()
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    private var pickerView: some View {
        if #available(iOS 26.0, *), ContentLibraries.configuration.featureFlagProvider.isLiquidGlassEnabled() {
            basePicker
                .glassEffect(.regular)
        } else {
            basePicker
                .blurBackground()
        }
    }
}
