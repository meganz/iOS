import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct EnforceCopyrightWarningView<T: View>: View, DismissibleContentView {
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
                    .scaleEffect(1.5)
                    .opacity(viewModel.viewStatus == .unknown ? 1.0 : 0.0)
            }
            .taskForiOS14 {
                await viewModel.determineViewState()
            }
            .onReceive(viewModel.$isTermsAgreed.dropFirst()) {
                guard !$0 else { return }
                if #available(iOS 15.0, *) {
                    presentationMode.wrappedValue.dismiss()
                } else {
                    invokeDismiss?()
                }
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
                            .foregroundColor(textColor)
                    }
                    
                    if #unavailable(iOS 15) {
                        Spacer()
                    }
                    
                    Button {
                        isTermsAgreed = true
                    } label: {
                        Text(Strings.Localizable.agree)
                            .font(.body)
                            .foregroundColor(textColor)
                    }
                }
            }
            .navigationTitle(Strings.Localizable.copyrightWarning)
        }
    }
    
    private var textColor: Color {
        Color(colorScheme == .dark ? UIColor.mnz_grayD1D1D1() : UIColor.mnz_gray515151())
    }
}
