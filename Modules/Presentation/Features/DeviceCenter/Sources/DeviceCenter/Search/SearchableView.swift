import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct SearchableView<WrappedView: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let wrappedView: WrappedView
    @Binding private var searchText: String
    @Binding private var isEditing: Bool
    
    var isFilteredListEmpty: Bool
    var searchAssets: SearchAssets
    var emptyStateAssets: EmptyStateAssets
    
    private var contentView: some View {
        VStack(spacing: 5.0) {
            SearchBarView(
                text: $searchText,
                isEditing: $isEditing,
                placeholder: searchAssets.placeHolder,
                cancelTitle: searchAssets.cancelTitle,
                isDesignTokenEnabled: DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
            )
            .padding(8)
            .background(colorScheme == .dark ? searchAssets.darkBGColor : searchAssets.lightBGColor)
            wrappedView
        }
        .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : .clear)
    }
    
    public init(wrappedView: WrappedView, searchText: Binding<String>, isEditing: Binding<Bool>, isFilteredListEmpty: Bool, searchAssets: SearchAssets, emptyStateAssets: EmptyStateAssets) {
        self.wrappedView = wrappedView
        self._searchText = searchText
        self._isEditing = isEditing
        self.isFilteredListEmpty = isFilteredListEmpty
        self.searchAssets = searchAssets
        self.emptyStateAssets = emptyStateAssets
    }
    
    var body: some View {
       contentView
            .emptyStateOverlay(
                isSearchActive: isEditing,
                isFilteredListEmpty: isFilteredListEmpty,
                emptyStateImage: emptyStateAssets.image,
                emptyStateTitle: emptyStateAssets.title
            )
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
