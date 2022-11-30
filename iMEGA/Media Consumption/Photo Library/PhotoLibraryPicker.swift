import SwiftUI
import MEGASwiftUI

struct PhotoLibraryPicker: View {
    @Environment(\.editMode) var editMode
    @Binding var selectedMode: PhotoLibraryViewMode
    
    var body: some View {
        pickerView()
            .opacity(editMode?.wrappedValue.isEditing == true ? 0 : 1)
    }
    
    private func pickerView() -> some View {
        Picker("View Mode", selection: $selectedMode.animation()) {
            ForEach(PhotoLibraryViewMode.allCases) {
                Text($0.title)
                    .font(.headline)
                    .bold()
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
        .blurryBackground(radius: 7, singleColorTheme: true)
        .padding(16)
        .onAppear {
            configSegmentedControlAppearance()
        }
    }
    
    private func configSegmentedControlAppearance() {
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 13, weight: .medium),
                 .foregroundColor: UIColor.white],
                for: .selected
            )
        
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 13, weight: .medium),
                 .foregroundColor: UIColor.black],
                for: .normal
            )

        UISegmentedControl
            .appearance()
            .backgroundColor = Colors.MediaConsumption.timelineYMDATabs.color
        
        UISegmentedControl
            .appearance()
            .selectedSegmentTintColor = Colors.MediaConsumption.timelineYMDATabsSelected.color
    }
}
