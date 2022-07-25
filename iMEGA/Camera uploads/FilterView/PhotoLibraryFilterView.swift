import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryFilterView: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    @ObservedObject var filterViewModel: PhotoLibraryFilterViewModel
    private let onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions, Bool) -> Void)?
    
    private let screen: String
    
    init(
        _ viewModel: PhotoLibraryContentViewModel,
        filterViewModel: PhotoLibraryFilterViewModel,
        forScreen screen: String,
        onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions, Bool) -> Void)?
    ) {
        self.viewModel = viewModel
        self.filterViewModel = filterViewModel
        self.screen = screen
        self.onFilterUpdate = onFilterUpdate
    }
    
    var btnCancel: some View {
        Button {
            filterViewModel.restoreLastSelection()
            viewModel.showFilter.toggle()
        } label: {
            Text(filterViewModel.cancelTitle)
                .font(Font.system(size: 17, weight: .regular, design: Font.Design.default))
                .foregroundColor(Color(Colors.Photos.filterNormalTextForeground.color))
        }
    }
    
    private func onDone() {
        onFilterUpdate?(
            filterViewModel.filterOption(for: filterViewModel.selectedMediaType),
            filterViewModel.filterOption(for: filterViewModel.selectedLocation),
            FeatureToggle.filterMenuOnCameraUploadExplorer.isEnabled   
        )
        
        viewModel.showFilter.toggle()
    }
    
    var btnDone: some View {
        Button {
            onDone()
        } label: {
            Text(filterViewModel.doneTitle)
                .font(Font.system(size: 17, weight: .semibold, design: Font.Design.default))
                .foregroundColor(Color(Colors.Photos.filterNormalTextForeground.color))
        }
    }
    
    var navigationBar: some View {
        HStack {
            btnCancel
            Spacer()
            Text(filterViewModel.filterTitle)
            Spacer()
            btnDone
        }
    }
    
    func typeView(_ geo: GeometryProxy) -> some View {
        VStack {
            PhotoLibraryFilterViewHeadline(filterViewModel.chooseTypeTitle)
            ForEach(filterViewModel.filterTypeMatrixRepresentation(forScreenWidth: geo.size.width, fontSize: 15, horizontalPadding: 15), id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { type in
                        PhotoLibraryFilterTypeView(type: type, filterViewModel: filterViewModel)
                    }
                    Spacer()
                }
                .lineLimit(1)
            }
        }
    }
    
    var locationView: some View {
        VStack (spacing: 8){
            PhotoLibraryFilterViewHeadline(filterViewModel.showItemsFromTitle)
            VStack (spacing: 2) {
                ForEach(PhotosFilterLocation.allCases, id: \.self) { location in
                    if location != PhotosFilterLocation.allCases.first { Divider() }
                    PhotoLibraryFilterLocationView(location: location, filterViewModel: filterViewModel)
                }
            }
            .background(Color(Colors.Photos.filterLocationItemBackground.color))
            .cornerRadius(8)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack (spacing: 35) {
                navigationBar
                VStack (spacing: 20) {
                    typeView(geo)
                    locationView
                }
                .padding(.horizontal, 5)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 20)
        .background(Color(Colors.Photos.filterBackground.color))
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            filterViewModel.initializeLastSelection()
        }
    }
}

fileprivate struct PhotoLibraryFilterViewHeadline: View {
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
