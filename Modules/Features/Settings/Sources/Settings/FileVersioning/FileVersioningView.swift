import MEGAConnectivity
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public struct FileVersioningView: View {
    @StateObject private var viewModel: FileVersioningViewModel
    
    public init(viewModel: @autoclosure @escaping () -> FileVersioningViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            fileVersioningToggleView
            deleteAllOlderVersionView
        }
        .noInternetViewModifier()
        .snackBar($viewModel.snackBar)
        .pageBackground()
        .navigationTitle(Strings.Localizable.Settings.FileManagement.fileVersioning)
        .task {
            await viewModel.setupFileVersioning()
        }
    }
    
    private var fileVersioningToggleView: some View {
        VStack(alignment: .leading) {
            MEGAList(
                title: Strings.Localizable.Settings.FileManagement.fileVersioning,
                subtitle: Strings.Localizable.Settings.FileManagement.FileVersioning.Menu.subtitle
            ).replaceTrailingView {
                MEGAToggle(state: .init(isOn: viewModel.isFileVersioningEnabled)) { state in
                    viewModel.toggleFileVersioning(isCurrentlyEnabled: state.isOn)
                }
            }
            
            footerText(viewModel.fileVersionMessage)
        }
        .padding(.bottom, TokenSpacing._5)
        .alert(isPresented: $viewModel.showDisableAlert) {
            Alert(
                title: Text(Strings.Localizable.Settings.FileManagement.FileVersioning.DisableFileVersioning.Alert.title),
                message: Text(Strings.Localizable.Settings.FileManagement.FileVersioning.DisableFileVersioning.Alert.message),
                primaryButton: .cancel(Text(Strings.Localizable.cancel)),
                secondaryButton: .default(Text(Strings.Localizable.Settings.FileManagement.FileVersioning.DisableFileVersioning.Alert.disableButton)) {
                    viewModel.updateFileVersioning(isEnabled: false)
                }
            )
        }
    }
    
    private var deleteAllOlderVersionView: some View {
        VStack(alignment: .leading) {
            HStack {
                MEGAButton(
                    Strings.Localizable.Settings.FileManagement.FileVersioning.DeleteOlderVersions.button,
                    type: .destructiveText,
                    state: viewModel.fileVersionCount == 0 ? .disabled : .default
                ) {
                    viewModel.onTapDeleteAllOlderVersionsButton()
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.trailing, TokenSpacing._5)
                        .frame(
                            idealWidth: 22,
                            idealHeight: 22,
                            alignment: .trailing
                        )
                }
            }
            .padding(.horizontal, TokenSpacing._2)
            
            footerText(Strings.Localizable.Settings.FileManagement.FileVersioning.Footer.title)
        }
        .alert(isPresented: $viewModel.showDeleteOlderVersionsAlert) {
            Alert(
                title: Text(Strings.Localizable.Settings.FileManagement.FileVersioning.DeleteOlderVersions.Alert.title),
                message: Text(Strings.Localizable.Settings.FileManagement.FileVersioning.DeleteOlderVersions.Alert.message),
                primaryButton: .cancel(Text(Strings.Localizable.cancel)),
                secondaryButton: .default(Text(Strings.Localizable.delete)) {
                    viewModel.deleteOlderVersions()
                }
            )
        }
    }
    
    private func footerText(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .multilineTextAlignment(.leading)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .padding(.horizontal, TokenSpacing._5)
    }
}
