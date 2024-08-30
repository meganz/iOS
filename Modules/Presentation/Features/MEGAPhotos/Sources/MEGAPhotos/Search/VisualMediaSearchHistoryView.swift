import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct VisualMediaSearchHistoryView: View {
    let searchedItems: [SearchHistoryItem]
    
    var body: some View {
        List {
            Section {
                ForEach(searchedItems) {
                    Text($0.query)
                        .font(.body)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .listRowSeparator(.hidden)
                        .listRowBackground(TokenColors.Background.page.swiftUI)
                }
            } header: {
                Text(Strings.Localizable.Photos.SearchHistory.Section.title)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    VisualMediaSearchHistoryView(searchedItems: [
        .init(id: UUID(), query: "Test"),
        .init(id: UUID(), query: "Search")
    ])
}
