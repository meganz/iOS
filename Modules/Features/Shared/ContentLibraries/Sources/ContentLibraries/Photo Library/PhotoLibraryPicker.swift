import MEGAInfrastructure
import MEGASwiftUI
import SwiftUI

struct PhotoLibraryPicker: View {
    @Environment(\.editMode) var editMode
    @Binding var selectedMode: PhotoLibraryViewMode
    let isMediaRevampEnabled: Bool
    
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
        // on iOS 26.0 beta the Swift runtime crashes when instantiating a value of a type
        // that includes the glassEffect modifier, due to __swift_instantiateConcreteTypeFromMangledNameV2
        // failing to instantiate the concrete glassEffect type. Skip on iOS 26.0 beta and use the fallback directly.
        if #available(iOS 26.0, *), !ProcessInfo.isRunningIOS26_0Beta {
            basePicker
                .glassEffect(.regular)
        } else {
            basePicker
                .blurBackground()
        }
    }
}
