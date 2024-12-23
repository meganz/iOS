import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SwiftUI
import WidgetKit

struct FavouritesTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry
    
    let viewModel: FavouritesQuickAccessWidgetViewModel
    
    func placeholder(in context: Context) -> QuickAccessWidgetEntry {
        QuickAccessWidgetEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @Sendable @escaping (QuickAccessWidgetEntry) -> Void) {
        Task { @MainActor in
            completion(QuickAccessWidgetEntry(date: Date(), section: SectionDetail.favourites.title, link: SectionDetail.favourites.link, value: viewModel.fetchFavouriteItems()))
        }
    }
    
    func getTimeline(in context: Context, completion: @Sendable @escaping (Timeline<QuickAccessWidgetEntry>) -> Void) {
        Task { @MainActor in
            let timeline = Timeline(entries: [QuickAccessWidgetEntry(date: Date(), section: SectionDetail.favourites.title, link: SectionDetail.favourites.link, value: viewModel.fetchFavouriteItems())], policy: .never)
            completion(timeline)
        }
    }

}

struct FavouritesQuickAccessWidget: Widget {
    let kind: String = MEGAFavouritesQuickAccessWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: FavouritesTimelineProvider(
                viewModel: FavouritesQuickAccessWidgetViewModel(
                    credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo),
                    copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository.newRepo),
                    favouriteItemsUseCase: FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance()))
                )
            )
        ) { entry in
            QuickAccessWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Localizable.quickAccess)
        .description(Strings.Localizable.quicklyAccessFilesOnFavouritesSection)
        .supportedFamilies([.systemLarge])
    }
}
