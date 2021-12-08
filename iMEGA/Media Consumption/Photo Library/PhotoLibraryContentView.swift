import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryContentView: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    
    @State private var selectedMode = PhotoLibraryContentViewModel.ViewMode.all
    
    init(viewModel: PhotoLibraryContentViewModel) {
        self.viewModel = viewModel
        configSegmentedControlAppearance()
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            ScrollView {
                photoContent()
            }
            .safeAreaInset(edge: .bottom) {
                pickerFooter()
            }
        } else {
            ZStack(alignment: .bottom) {
                ScrollView {
                    photoContent()
                        .padding(.bottom, 60)
                }
                pickerFooter()
            }
        }
    }
    
    private func pickerFooter() -> some View {
        viewModePicker()
            .blurryBackground(radius: 7)
            .padding(16)
    }
    
    private func viewModePicker() -> some View {
        Picker("View Mode", selection: $selectedMode) {
            ForEach(PhotoLibraryContentViewModel.ViewMode.allCases) {
                Text($0.title)
                    .font(.headline)
                    .bold()
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    private func photoContent() -> some View {
        switch selectedMode {
        case .year:
            let vm = PhotoLibraryYearViewModel(photosByYearList: viewModel.library.photosByYearList)
            PhotoLibraryYearView(viewModel: vm)
        case .month:
            let vm = PhotoLibraryMonthViewModel(photosByMonthList: viewModel.library.allPhotosByMonthList)
            PhotoLibraryMonthView(viewModel: vm)
        case .day:
            let vm = PhotoLibraryDayViewModel(photosByDayList: viewModel.library.allPhotosByDayList)
            PhotoLibraryDayView(viewModel: vm)
        case .all:
            let vm = PhotoLibraryAllViewModel(library: viewModel.library)
            PhotoLibraryAllView(viewModel: vm)
        }
    }
    
    private func configSegmentedControlAppearance() {
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 15, weight: .semibold)],
                for: .selected
            )
        
        UISegmentedControl
            .appearance()
            .setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 13, weight: .medium)],
                for: .normal
            )
    }
}
