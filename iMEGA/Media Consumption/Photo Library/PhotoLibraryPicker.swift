import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryPicker: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    @Environment(\.editMode) var editMode
    
    init(viewModel: PhotoLibraryContentViewModel) {
        self.viewModel = viewModel
        configSegmentedControlAppearance()
    }
    
    var body: some View {
        Group {
            if editMode?.wrappedValue.isEditing == true {
                EmptyView()
            } else {
                Picker("View Mode", selection: $viewModel.selectedMode.animation()) {
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
            }
        }
        .onReceive(viewModel.selection.$editMode.dropFirst()) {
            editMode?.wrappedValue = $0
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
