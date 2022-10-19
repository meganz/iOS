
import SwiftUI

@available(iOS 14.0, *)
struct TermsAndPoliciesView: View {
    let viewModel: TermsAndPoliciesViewModel
    var body: some View {
        List {
            Button(action: {
                viewModel.dispatch(.showPrivacyPolicy)
            }) {
                NavigationLink(Strings.Localizable.privacyPolicyLabel, destination: EmptyView())
            }
            Button(action: {
                viewModel.dispatch(.showCookiePolicy)
            }) {
                NavigationLink(Strings.Localizable.General.cookiePolicy, destination: EmptyView())
            }
            Button(action: {
                viewModel.dispatch(.showTermsOfService)
            }) {
                NavigationLink(Strings.Localizable.termsOfServicesLabel, destination: EmptyView())
            }
        }
        .foregroundColor(.primary)
        .listStyle(.grouped)
    }
}
