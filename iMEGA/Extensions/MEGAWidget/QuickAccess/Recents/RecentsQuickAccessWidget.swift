import MEGADomain
import MEGAL10n
import MEGARepo
import SwiftUI
import WidgetKit

struct RecentsTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    let viewModel: RecentsQuickAccessWidgetViewModel
    
    func placeholder(in context: Context) -> QuickAccessWidgetEntry {
        QuickAccessWidgetEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (QuickAccessWidgetEntry) -> Void) {
        Task { @MainActor in
            completion(QuickAccessWidgetEntry(date: Date(), section: SectionDetail.recents.title, link: SectionDetail.recents.link, value: viewModel.fetchRecentItems()))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<QuickAccessWidgetEntry>) -> Void) {
        Task { @MainActor in
            let timeline = Timeline(entries: [QuickAccessWidgetEntry(date: Date(), section: SectionDetail.recents.title, link: SectionDetail.recents.link, value: viewModel.fetchRecentItems())], policy: .never)
            completion(timeline)
        }
    }

}

struct RecentsQuickAccessWidget: Widget {
    let kind: String = MEGARecentsQuickAccessWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: RecentsTimelineProvider(
                viewModel: RecentsQuickAccessWidgetViewModel(
                    credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo),
                    copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository.newRepo),
                    recentItemsUseCase: RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance()))
                )
            )
        ) { entry in
            QuickAccessWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Localizable.quickAccess)
        .description(Strings.Localizable.quicklyAccessFilesOnRecentsSection)
        .supportedFamilies([.systemLarge])
    }
}
