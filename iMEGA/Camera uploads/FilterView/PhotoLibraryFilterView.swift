import SwiftUI

struct PhotoLibraryFilterView: View {
    @ObservedObject var viewModel: PhotoLibraryFilterViewModel
    @Binding var isPresented: Bool
    let onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)?
    
    var btnCancel: some View {
        Button {
            isPresented.toggle()
        } label: {
            Text(viewModel.cancelTitle)
                .font(Font.system(size: 17, weight: .regular, design: Font.Design.default))
                .foregroundColor(Color(Colors.Photos.filterNormalTextForeground.color))
        }
    }
    
    private func onDone() {
        onFilterUpdate?(
            viewModel.filterOption(for: viewModel.selectedMediaType),
            viewModel.filterOption(for: viewModel.selectedLocation)
        )
        
        viewModel.applyFilters()
        Task { await viewModel.saveFilters() }
        isPresented.toggle()
    }
    
    var btnDone: some View {
        Button {
            onDone()
        } label: {
            Text(viewModel.doneTitle)
                .font(Font.system(size: 17, weight: .semibold, design: Font.Design.default))
                .foregroundColor(Color(Colors.Photos.filterNormalTextForeground.color))
        }
    }
    
    var navigationBar: some View {
        HStack {
            btnCancel
            Spacer()
            Text(viewModel.filterTitle)
                .bold()
            Spacer()
            btnDone
        }
    }
    
    @ViewBuilder
    func typeView(_ geo: GeometryProxy) -> some View {
        if viewModel.shouldShowMediaTypeFilter {
            VStack {
                PhotoLibraryFilterViewHeadline(viewModel.chooseTypeTitle)
                ForEach(viewModel.filterTypeMatrixRepresentation(forScreenWidth: geo.size.width, fontSize: 15, horizontalPadding: 15), id: \.self) { row in
                    HStack {
                        ForEach(row, id: \.self) { type in
                            PhotoLibraryFilterTypeView(type: type, filterViewModel: viewModel)
                        }
                        Spacer()
                    }
                    .lineLimit(1)
                }
            }
        }
    }
    
    var locationView: some View {
        VStack(spacing: 8) {
            PhotoLibraryFilterViewHeadline(viewModel.showItemsFromTitle)
            VStack(spacing: 2) {
                ForEach(PhotosFilterLocation.allCases, id: \.self) { location in
                    if location != PhotosFilterLocation.allCases.first { Divider() }
                    PhotoLibraryFilterLocationView(location: location, filterViewModel: viewModel)
                }
            }
            .background(Color(Colors.Photos.filterLocationItemBackground.color))
            .cornerRadius(8)
        }
    }
    
    var rememberPreferenceView: some View {
        HStack {
            Toggle(Strings.Localizable.CameraUploads.Timeline.Filter.rememberPreferences, isOn: $viewModel.selectedSavePreferences)
                .toggleStyle(SwitchToggleStyle(tint: Color(Colors.Photos.filterTypeSelectionBackground.color)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundColor(Color(Colors.Photos.filterLocationItemForeground.color))
        .background(Color(Colors.Photos.filterLocationItemBackground.color))
        .cornerRadius(8)
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 35) {
                navigationBar
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        typeView(geo)
                        locationView
                        rememberPreferenceView
                            .padding(.top, 12)
                            .opacity(viewModel.isRememberPreferencesFeatureFlagEnabled ? 1.0: 0.0)
                    }
                    .padding(.horizontal, 5)
                    .padding(.bottom, 50)
                }
                .frame(height: geo.size.height)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 20)
        .background(Color(Colors.Photos.filterBackground.color))
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            viewModel.setSelectedFiltersToAppliedFiltersIfRequired()
            Task { await viewModel.applySavedFilters() }
        }
    }
}

private struct PhotoLibraryFilterViewHeadline: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(Font.system(size: 22, weight: .bold, design: Font.Design.default))
                .foregroundColor(Color(Colors.Photos.filterTextForeground.color))
                .minimumScaleFactor(0.5)
            Spacer()
        }
    }
}
