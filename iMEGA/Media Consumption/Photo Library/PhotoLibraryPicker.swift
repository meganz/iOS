import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryPicker: View {
    @Environment(\.editMode) var editMode
    @Binding var selectedMode: PhotoLibraryViewMode
    
    var body: some View {
        if editMode?.wrappedValue.isEditing == true {
            EmptyView()
        } else {
            pickerView()
        }
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
        .blurryBackground(radius: 7)
        .padding(16)
        .onAppear {
            configSegmentedControlAppearance()
        }
    }

    
    private func configSegmentedControlAppearance() {
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                 .foregroundColor: UIColor.systemBackground],
                for: .selected
            )
        
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 13, weight: .medium),
                 .foregroundColor: UIColor.label],
                for: .normal
            )
        
        UISegmentedControl
            .appearance()
            .selectedSegmentTintColor = UIColor.label.withAlphaComponent(0.4)
    }
}
