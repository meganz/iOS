import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct AboutView: View {
    @StateObject var viewModel: AboutViewModel
    
    var body: some View {
        List {
            Section {
                AppVersionView(viewModel: viewModel)
                AboutItemView(title: Strings.Localizable.sdkVersion, subtitle: viewModel.sdkVersion)
                ChatSdkVersionView(viewModel: viewModel)
            }
            Section {
                LinkView(viewModel: viewModel)
            }
        }
        .background()
        .foregroundColor(TokenColors.Text.primary.swiftUI)
        .listStyle(.grouped)
        .alert(isPresented: $viewModel.showApiEnvironmentChangedAlert) {
            Alert(title: Text("API URL changed"))
        }
    }
}

private struct LinkView: View {
    var viewModel: AboutViewModel
    
    var body: some View {
        Link(Strings.Localizable.viewSourceCode, destination: viewModel.sourceCodeURL)
            .separator()
        Link(Strings.Localizable.acknowledgements, destination: viewModel.acknowledgementsURL)
            .separator()
    }
}

private struct AppVersionView: View {
    @ObservedObject var viewModel: AboutViewModel
    
    var body: some View {
        AboutItemView(title: Strings.Localizable.appVersion, subtitle: viewModel.appVersion)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 5) {
                viewModel.refreshToggleLogsAlertStatus()
            }
            .alert(isPresented: $viewModel.showToggleLogsAlert) {
                Alert(title: Text(viewModel.titleForLogsAlert()),
                      message: Text(viewModel.messageForLogsAlert()),
                      primaryButton: .cancel(Text(Strings.Localizable.cancel)),
                      secondaryButton: .default(Text(Strings.Localizable.ok), action: {
                    viewModel.toggleLogs()
                }))
            }
            .onLongPressGesture(minimumDuration: 5) {
                viewModel.refreshChangeAPIEnvironmentAlertStatus()
            }
            .actionSheet(isPresented: $viewModel.showChangeApiEnvironmentAlert, content: {
                ActionSheet(title: Text(Strings.Localizable.changeToATestServer),
                            message: Text(Strings.Localizable.areYouSureYouWantToChangeToATestServerYourAccountMaySufferIrrecoverableProblems),
                            buttons: changeApiURLActionSheetButtons()
                )
            })
    }
    
    private func changeApiURLActionSheetButtons() -> [ActionSheet.Button] {
        var actionSheetButtons = viewModel.apiEnvironments.compactMap { action in
            ActionSheet.Button.default(Text(action.title)) {
                viewModel.changeAPIEnvironment(environment: action.environment)
            }
        }
        
        actionSheetButtons.append(ActionSheet.Button.cancel())
        
        return actionSheetButtons
    }
}

private struct ChatSdkVersionView: View {
    @ObservedObject var viewModel: AboutViewModel
    
    var body: some View {
        AboutItemView(title: Strings.Localizable.megachatSdkVersion, subtitle: viewModel.chatSdkVersion)
            .onTapGesture(count: 5) {
                viewModel.refreshToggleSfuServerAlertStatus()
            }
            .alert(Strings.Localizable.Settings.About.Sfu.ChangeAlert.title, isPresented: $viewModel.showSfuServerChangeAlert) {
                TextField(Strings.Localizable.Settings.About.Sfu.ChangeAlert.placeholder, text: $viewModel.sfuServerId)
                    .keyboardType(.numbersAndPunctuation)
                Button(Strings.Localizable.Settings.About.Sfu.ChangeAlert.changeButton) {
                    viewModel.changeSfuServer()
                }
                Button(Strings.Localizable.Settings.About.Sfu.ChangeAlert.cancelButton, role: .cancel) { }
            } message: {
                Text(Strings.Localizable.Settings.About.Sfu.ChangeAlert.message)
            }
    }
}
