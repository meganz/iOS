import WidgetKit
import SwiftUI
import MEGADomain
import MEGAData

struct FavouritesTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    var viewModel = FavouritesQuickAccessWidgetViewModel(
        credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo),
        copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository.newRepo),
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
        .configurationDisplayName(Strings.Localizable.quickAccess)
        .description(Strings.Localizable.quicklyAccessFilesOnFavouritesSection)
        .supportedFamilies([.systemLarge])
    }
}
