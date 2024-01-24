import MEGAL10n
import SwiftUI

public struct TermsAndPoliciesView: View {
    @StateObject var viewModel: TermsAndPoliciesViewModel
    
    public init(viewModel: TermsAndPoliciesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        List {
            Link(destination: viewModel.privacyUrl) {
                NavigationLink(Strings.Localizable.privacyPolicyLabel, destination: EmptyView())
            }
            Link(destination: viewModel.cookieUrl) {
                NavigationLink(Strings.Localizable.General.cookiePolicy, destination: EmptyView())
            }
            Link(destination: viewModel.termsUrl) {
                NavigationLink(Strings.Localizable.termsOfServicesLabel, destination: EmptyView())
            }
        }
        .task {
            await viewModel.setupCookiePolicyURL()
        }
        .foregroundColor(.primary)
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Settings.Section.termsAndPolicies)
    }
}

