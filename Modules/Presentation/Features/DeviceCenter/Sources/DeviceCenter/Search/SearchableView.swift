import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct SearchableView<WrappedView: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let wrappedView: WrappedView
    @Binding private var searchText: String
    @Binding private var isEditing: Bool
    @Binding private var hasNetworkConnection: Bool
    
    var isFilteredListEmpty: Bool
    
    private var contentView: some View {
        VStack(spacing: 5.0) {
            SearchBarView(
                text: $searchText,
                isEditing: $isEditing,
                placeholder: Strings.Localizable.search,
                cancelTitle: Strings.Localizable.cancel
            )
            .padding(8)
            .background(TokenColors.Background.surface1.swiftUI)
            wrappedView
        }
        .background()
    }
    
    public init(
        wrappedView: WrappedView,
        searchText: Binding<String>,
        isEditing: Binding<Bool>,
        isFilteredListEmpty: Bool,
        hasNetworkConnection: Binding<Bool>
    ) {
        self.wrappedView = wrappedView
        self._searchText = searchText
        self._isEditing = isEditing
        self.isFilteredListEmpty = isFilteredListEmpty
        self._hasNetworkConnection = hasNetworkConnection
    }
    
    var body: some View {
        if hasNetworkConnection {
            contentView
                 .emptyStateOverlay(
                     isSearchActive: isEditing,
                     isFilteredListEmpty: isFilteredListEmpty,
                     emptyStateImage: "searchEmptyState",
                     emptyStateTitle: Strings.Localizable.noResults
                 )
        } else {
            contentView
        }
    }
}

struct EmptyStateOverlayModifier: ViewModifier {
    var isSearchActive: Bool
    var isFilteredListEmpty: Bool
    var emptyStateImage: String
    var emptyStateTitle: String
    
    func body(content: Content) -> some View {
        content.overlay(
            VStack {
                if isSearchActive && isFilteredListEmpty {
                    DeviceCenterEmptyStateView(
                        image: emptyStateImage,
                        title: emptyStateTitle
                    )
                }
            }
            , alignment: .center
        )
    }
}

extension View {
    func emptyStateOverlay(
        isSearchActive: Bool,
        isFilteredListEmpty: Bool,
        emptyStateImage: String,
        emptyStateTitle: String
    ) -> some View {
        self.modifier(
            EmptyStateOverlayModifier(
                isSearchActive: isSearchActive,
                isFilteredListEmpty: isFilteredListEmpty,
                emptyStateImage: emptyStateImage,
                emptyStateTitle: emptyStateTitle
            )
        )
    }
}
