import WidgetKit
import SwiftUI

struct FavouritesTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    var viewModel = FavouritesQuickAccessWidgetViewModel(
        authUseCase: AuthUseCase(repo: AuthRepository(sdk: MEGASdkManager.sharedMEGASdk())),
        copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository(fileManager: FileManager.default)),
        favouriteItemsUseCase: FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance()))
    )
    
    func placeholder(in context: Context) -> QuickAccessWidgetEntry {
        QuickAccessWidgetEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickAccessWidgetEntry) -> Void) {
        completion(QuickAccessWidgetEntry(date: Date(), section: SectionDetail.favourites.title, link: SectionDetail.favourites.link, value: viewModel.fetchFavouriteItems()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAccessWidgetEntry>) -> Void) {
        let timeline = Timeline(entries: [QuickAccessWidgetEntry(date: Date(), section: SectionDetail.favourites.title, link: SectionDetail.favourites.link, value: viewModel.fetchFavouriteItems())], policy: .never)
        completion(timeline)
    }

}

struct FavouritesQuickAccessWidget: Widget {
    let kind: String = MEGAFavouritesQuickAccessWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavouritesTimelineProvider()) { entry in
            QuickAccessWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("Quick Access", comment: "Title for the QuickAccess widget"))
        .description(NSLocalizedString("Quickly access files on Favourites section", comment: "Text description for the Favourites QuickAccess widget"))
        .supportedFamilies([.systemLarge])
    }
}
