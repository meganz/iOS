import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
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
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }
    
    private func onDone() {
        onFilterUpdate?(
            viewModel.filterOption(for: viewModel.selectedMediaType),
            viewModel.filterOption(for: viewModel.selectedLocation)
        )
        
        viewModel.applyFilters()
        Task {
            await viewModel.saveFilters()
        }
        isPresented.toggle()
    }
    
    var btnDone: some View {
        Button {
            onDone()
        } label: {
            Text(viewModel.doneTitle)
                .font(Font.system(size: 17, weight: .semibold, design: Font.Design.default))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }
    
    @ViewBuilder
    private var navigationBar: some View {
        ZStack(alignment: .top) {
            Group { TokenColors.Background.surface1.swiftUI }
                .ignoresSafeArea()
            
            NavigationBarView(
                leading: { btnCancel },
                trailing: { btnDone },
                center: { NavigationTitleView(title: viewModel.filterTitle) },
                backgroundColor: TokenColors.Background.surface1.swiftUI
            )
            .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    func typeView(_ geo: GeometryProxy) -> some View {
        if viewModel.shouldShowMediaTypeFilter {
            VStack {
                PhotoLibraryFilterViewHeadline(viewModel.chooseTypeTitle)
                    .padding(.top, 35)
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
                    if location != PhotosFilterLocation.allCases.first {
                        Divider()
                            .background(TokenColors.Border.strong.swiftUI)
                    }
                    PhotoLibraryFilterLocationView(location: location, filterViewModel: viewModel)
                }
            }
            .background(TokenColors.Background.surface1.swiftUI)
            .cornerRadius(8)
        }
    }
    
    var rememberPreferenceView: some View {
        HStack {
            Toggle(Strings.Localizable.CameraUploads.Timeline.Filter.rememberPreferences, isOn: $viewModel.selectedSavePreferences)
                .toggleStyle(SwitchToggleStyle(tint: TokenColors.Support.success.swiftUI))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundStyle(TokenColors.Text.primary.swiftUI)
        .background(TokenColors.Background.surface1.swiftUI)
        .cornerRadius(8)
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                navigationBar
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        typeView(geo)
                        locationView
                        rememberPreferenceView
                            .padding(.top, 12)
                            .opacity(viewModel.isRememberPreferenceActive ? 1.0: 0.0)
                    }
                    .padding(.horizontal, 5)
                    .padding(.bottom, 50)
                }
                .frame(height: geo.size.height)
                .padding(.horizontal, 10)
                Spacer()
            }
        }
        .background(TokenColors.Background.page.swiftUI)
        .ignoresSafeArea(edges: [.top, .bottom])
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
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .minimumScaleFactor(0.5)
            Spacer()
        }
        .background(TokenColors.Background.page.swiftUI)
    }
}

#Preview {
    PhotoLibraryFilterView(
        viewModel: PhotoLibraryFilterViewModel(contentConsumptionUserAttributeUseCase: Preview_ContentConsumptionUserAttributeUseCase()),
        isPresented: .constant(true),
        onFilterUpdate: nil
    )
}
