import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct TermsAndPoliciesView: View {
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
        .designTokenBackground(isDesignTokenEnabled)
        .foregroundColor(.primary)
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Settings.Section.termsAndPolicies)
    }

    private func listItem(with url: URL, title: String) -> some View {
        Link(destination: url) {
            NavigationLink(title, destination: EmptyView())
        }
        .designTokenListItemBackground(isDesignTokenEnabled)
        .designTokenSeparator(isDesignTokenEnabled)
    }
}
