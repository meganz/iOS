
import SwiftUI

public struct TermsAndPoliciesView: View {
    private let privacyUrl = URL(string: "https://mega.io/privacy") ?? URL(fileURLWithPath: "")
    private let cookieUrl = URL(string: "https://mega.nz/cookie") ?? URL(fileURLWithPath: "")
    private let termsUrl = URL(string: "https://mega.io/terms") ?? URL(fileURLWithPath: "")
    
    private let privacyPolicyText: String
    private let cookiePolicyText: String
    private let termsOfServicesText: String
    
    public init(privacyPolicyText: String,
                cookiePolicyText: String,
                termsOfServicesText: String) {
        self.privacyPolicyText = privacyPolicyText
        self.cookiePolicyText = cookiePolicyText
        self.termsOfServicesText = termsOfServicesText
    }
    
    public var body: some View {
        List {
            Link(destination: privacyUrl) {
                NavigationLink(privacyPolicyText, destination: EmptyView())
            }
            Link(destination: cookieUrl) {
                NavigationLink(cookiePolicyText, destination: EmptyView())
            }
            Link(destination: termsUrl) {
                NavigationLink(termsOfServicesText, destination: EmptyView())
            }
        }
        .foregroundColor(.primary)
        .listStyle(.grouped)
    }
}
