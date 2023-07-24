import SwiftUI

struct AboutView: View {
    @StateObject var viewModel: AboutViewModel
    
    var body: some View {
        List {
            Section {
                HStack {
                    AboutItemView(title: viewModel.aboutSetting.appVersion.title,
                                  subtitle: viewModel.aboutSetting.appVersion.message)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 5) {
                    viewModel.refreshToggleLogsAlertStatus()
                }
                .alert(isPresented: $viewModel.showToggleLogsAlert) {
                    Alert(title: Text(viewModel.titleForLogsAlert()),
                          message: Text(viewModel.messageForLogsAlert()),
                          primaryButton: .cancel(Text(viewModel.aboutSetting.toggleLogs.cancelActionTitle)),
                          secondaryButton: .default(Text(viewModel.aboutSetting.toggleLogs.mainActionTitle), action: {
                        viewModel.toggleLogs()
                    }))
                }
                .onLongPressGesture(minimumDuration: 5) {
                    viewModel.refreshChangeAPIEnvironmentAlertStatus()
                }
                .actionSheet(isPresented: $viewModel.showChangeApiEnvironmentAlert, content: {
                    ActionSheet(title: Text(viewModel.aboutSetting.apiEnvironment.title),
                                message: Text(viewModel.aboutSetting.apiEnvironment.message),
                                buttons: changeApiURLActionSheetButtons()
                    )
                })
                AboutItemView(title: viewModel.aboutSetting.sdkVersion.title,
                              subtitle: viewModel.aboutSetting.sdkVersion.message)
                if #available(iOS 15.0, *) {
                    AboutItemView(title: viewModel.aboutSetting.chatSdkVersion.title,
                                  subtitle: viewModel.aboutSetting.chatSdkVersion.message)
                    .onTapGesture(count: 5) {
                        viewModel.refreshToggleSfuServerAlertStatus()
                    }
                    .alert(viewModel.aboutSetting.changeSfuServer.title, isPresented: $viewModel.showSfuServerChangeAlert) {
                        TextField(viewModel.aboutSetting.changeSfuServer.placeholder, text: $viewModel.sfuServerId)
                            .keyboardType(.numbersAndPunctuation)
                        Button(viewModel.aboutSetting.changeSfuServer.changeButton) {
                            viewModel.changeSfuServer()
                        }
                        Button(viewModel.aboutSetting.changeSfuServer.cancelButton, role: .cancel) { }
                    } message: {
                        Text(viewModel.aboutSetting.changeSfuServer.message)
                    }
                } else {
                    AboutItemView(title: viewModel.aboutSetting.chatSdkVersion.title,
                                  subtitle: viewModel.aboutSetting.chatSdkVersion.message)
                }
            }
            Section {
                Link(viewModel.aboutSetting.viewSourceLink.title,
                     destination: viewModel.aboutSetting.viewSourceLink.url)
                Link(viewModel.aboutSetting.acknowledgementsLink.title,
                     destination: viewModel.aboutSetting.acknowledgementsLink.url)
            }
        }
        .foregroundColor(.primary)
        .listStyle(.grouped)
        .alert(isPresented: $viewModel.showApiEnvironmentChangedAlert) {
            Alert(title: Text("API URL changed"))
        }
    }
    
    private func changeApiURLActionSheetButtons() -> [ActionSheet.Button] {
        var actionSheetButtons = viewModel.aboutSetting.apiEnvironment.actions.compactMap { action in
            ActionSheet.Button.default(Text(action.title)) {
                viewModel.changeAPIEnvironment(environment: action.environment)
            }
        }
        
        actionSheetButtons.append(ActionSheet.Button.cancel())
        
        return actionSheetButtons
    }
}
