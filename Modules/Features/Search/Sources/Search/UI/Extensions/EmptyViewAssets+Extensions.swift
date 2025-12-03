import MEGASwiftUI

public extension SearchConfig.EmptyViewAssets {
    var emptyViewModel: ContentUnavailableViewModel {
        .init(
            image: image,
            title: title,
            font: .body,
            titleTextColor: titleTextColor,
            actions: actions.map(\.action)
        )
    }
}

public extension SearchConfig.EmptyViewAssets.Action {
    var action: ContentUnavailableViewModel.MenuAction {
        .init(
            title: title,
            titleTextColor: titleTextColor,
            backgroundColor: backgroundColor,
            actions: menu.map(\.buttonAction)
        )
    }
}

public extension SearchConfig.EmptyViewAssets.MenuOption {
    var buttonAction: ContentUnavailableViewModel.ButtonAction {
        .init(title: title, image: image, handler: handler)
    }
}
