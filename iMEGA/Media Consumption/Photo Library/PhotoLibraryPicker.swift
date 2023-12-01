import MEGASwiftUI
import SwiftUI

struct PhotoLibraryPicker: View {
    @Environment(\.editMode) var editMode
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedMode: PhotoLibraryViewMode
    
    var body: some View {
        pickerView()
            .opacity(editMode?.wrappedValue.isEditing == true ? 0 : 1)
            .onChange(of: colorScheme) { _ in
                configSegmentedControlAppearance()
            }
    }
    
    init(selectedMode: Binding<PhotoLibraryViewMode>) {
        _selectedMode = selectedMode
        
        configSegmentedControlAppearance()
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
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.white).background(.thinMaterial))
        .cornerRadius(7)
        .padding(16)
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
            .backgroundColor = UIColor.mediaConsumptionTimelineYMDATabs
        
        UISegmentedControl
            .appearance()
            .selectedSegmentTintColor = UIColor.mediaConsumptionTimelineYMDATabsSelected
    }
}
