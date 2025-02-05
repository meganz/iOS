import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public struct FileManagementView: View {
    @StateObject private var viewModel: FileManagementViewModel
    
    public init(viewModel: @autoclosure @escaping () -> FileManagementViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                onMegaSection
                onYourDeviceSection
            }
        }
        .noInternetViewModifier()
        .snackBar($viewModel.snackBar)
        .pageBackground()
        .navigationTitle(Strings.Localizable.Settings.FileManagement.title)
        .task {
            viewModel.setupFileManagement()
        }
    }
    
    private var onMegaSection: some View {
        VStack(alignment: .leading) {
            Text(Strings.Localizable.Settings.FileManagement.Header.onMEGA)
                .font(.headline)
                .padding(16)
            
            MEGAList(
                title: Strings.Localizable.Settings.FileManagement.useMobileDataForHighResolution,
                subtitle: Strings.Localizable.Settings.FileManagement.UseMobileDataForHighResolution.description
            ).replaceTrailingView {
                MEGAToggle(state: .init(isOn: viewModel.isMobileDataEnabled)) { state in
                    viewModel.toggleMobileDataUsage(isCurrentlyEnabled: state.isOn)
                }
            }
            
            Button(action: viewModel.onTapRubbishBinSettings) {
                MEGAList(
                    title: Strings.Localizable.Settings.FileManagement.rubbishBinSettings
                )
                .trailingChevron()
            }
            
            Button(action: viewModel.onTapFileVersioning) {
                MEGAList(
                    title: Strings.Localizable.Settings.FileManagement.fileVersioning
                )
                .trailingChevron()
            }
        }
    }
    
    private var onYourDeviceSection: some View {
        VStack(alignment: .leading) {
            Text(Strings.Localizable.Settings.FileManagement.Header.onYourDevice)
                .font(.headline)
                .padding(16)
            
            Button(action: viewModel.onTapClearCache) {
                MEGAList(
                    title: Strings.Localizable.Settings.FileManagement.clearCache,
                    subtitle: viewModel.formattedCacheSize
                )
                .trailingChevron()
            }
            
            Button(action: viewModel.onTapClearOfflineFiles) {
                MEGAList(
                    title: Strings.Localizable.Settings.FileManagement.clearOfflineFiles,
                    subtitle: viewModel.formattedOfflineFilesSize
                )
                .trailingChevron()
            }
        }
        .alert(isPresented: $viewModel.showClearOfflineFilesAlert) {
            Alert(
                title: Text(Strings.Localizable.Settings.FileManagement.ClearOfflineFiles.Alert.title),
                message: Text(Strings.Localizable.Settings.FileManagement.ClearOfflineFiles.Alert.description),
                primaryButton: .cancel(Text(Strings.Localizable.cancel)),
                secondaryButton: .default(Text(Strings.Localizable.Settings.FileManagement.ClearOfflineFiles.Alert.confirmationButton)) {
                    viewModel.clearOfflineFiles()
                }
            )
        }
    }
}
