import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct TermsAndPoliciesView: View {
    @StateObject var viewModel: TermsAndPoliciesViewModel
    var isPresentedModal: Bool = false
    
    public init(viewModel: TermsAndPoliciesViewModel, isPresented: Bool) {
        _viewModel = StateObject(wrappedValue: viewModel)
        isPresentedModal = isPresented
    }
    
    public var body: some View {
        if isPresentedModal {
            NavigationStackView {
                TermsAndPoliciesContentView(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarColor(isDesignTokenEnabled ? TokenColors.Background.surface1 : UIColor.clear)
                    .toolbar {
                        ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                            Button {
                                viewModel.dismiss()
                            } label: {
                                Text(Strings.Localizable.close)
                                    .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                            }
                        }
                    }
                    .interactiveDismissDisabled()
            }
        } else {
            TermsAndPoliciesContentView(viewModel: viewModel)
        }
    }
}

private struct TermsAndPoliciesContentView: View {
    @StateObject var viewModel: TermsAndPoliciesViewModel
    
    public init(viewModel: TermsAndPoliciesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        List {
            listItem(with: viewModel.privacyUrl, title: Strings.Localizable.privacyPolicyLabel)
            listItem(with: viewModel.cookieUrl, title: Strings.Localizable.General.cookiePolicy)
            listItem(with: viewModel.termsUrl, title: Strings.Localizable.termsOfServicesLabel)
        }
        .task {
            await viewModel.setupCookiePolicyURL()
        }
        .background()
        .foregroundColor(.primary)
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Settings.Section.termsAndPolicies)
    }

    private func listItem(with url: URL, title: String) -> some View {
        Link(destination: url) {
            NavigationLink(title, destination: EmptyView())
        }
        .listItemBackground()
        .separator()
    }
}
