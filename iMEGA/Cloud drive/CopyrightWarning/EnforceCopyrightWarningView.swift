import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct EnforceCopyrightWarningView<T: View>: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: EnforceCopyrightWarningViewModel
    let termsAgreedView: () -> T
    var invokeDismiss: (() -> Void)?
    
    var body: some View {
        NavigationStackView {
            ZStack {
                switch viewModel.viewStatus {
                case .agreed:
                    termsAgreedView()
                case .declined:
                    CopyrightWarningView(copyrightMessage: viewModel.copyrightMessage,
                                         isTermsAgreed: $viewModel.isTermsAgreed)
                case .unknown:
                    EmptyView()
                }
                ProgressView()
                    .controlSize(.large)
                    .opacity(viewModel.viewStatus == .unknown ? 1.0 : 0.0)
            }
            .task {
                await viewModel.determineViewState()
            }
            .onReceive(viewModel.$isTermsAgreed.dropFirst()) {
                guard !$0 else { return }
                presentationMode.wrappedValue.dismiss()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct CopyrightWarningView: View {
    let copyrightMessage: String
    
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isTermsAgreed: Bool
    
    var body: some View {
        ScrollView {
            VStack {
                Text("©")
                    .font(Font.system(size: 145, weight: .bold, design: .default))
                    .fontWeight(.light)
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 24)
                
                Text(Strings.Localizable.copyrightWarningToAll)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 24)
                
                Text(copyrightMessage)
                    .font(.body)
            }
            .padding([.top, .horizontal], 16)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        isTermsAgreed = false
                    } label: {
                        Text(Strings.Localizable.disagree)
                            .font(.body)
                            .foregroundColor(TokenColors.Text.primary.swiftUI)
                    }
                    
                    Button {
                        isTermsAgreed = true
                    } label: {
                        Text(Strings.Localizable.agree)
                            .font(.body)
                            .foregroundColor(TokenColors.Text.primary.swiftUI)
                    }
                }
            }
            .navigationTitle(Strings.Localizable.copyrightWarning)
        }
    }
}
