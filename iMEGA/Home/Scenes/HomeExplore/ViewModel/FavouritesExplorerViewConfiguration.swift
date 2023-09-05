import MEGAL10n

struct FavouritesExplorerViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return Strings.Localizable.Home.Favourites.title
    }
    
    var emptyStateType: EmptyStateType {
        return .favourites
    }
    
    var listSourceType: any FilesExplorerListSourceProtocol.Type {
        return FavouritesExplorerListSource.self
    }
}
