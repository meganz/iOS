import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct VisualMediaSearchHistoryView: View {
    let searchedItems: [SearchHistoryItem]
    @Binding var selectedRecentlySearched: String?
    
    var body: some View {
        List {
            Section {
                ForEach(searchedItems) { item in
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 10) {
                            MEGAAssetsImageProvider.image(named: .clockMediumThin)
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                            
                            Text(item.query)
                                .font(.body)
                                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        }
                        
                        Divider()
                            .frame(maxHeight: 0.5)
                            .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(TokenColors.Background.page.swiftUI)
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        selectedRecentlySearched = item.query
                    }
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
    ], selectedRecentlySearched: .constant(nil))
}
