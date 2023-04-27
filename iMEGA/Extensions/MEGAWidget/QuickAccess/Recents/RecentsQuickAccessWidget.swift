import WidgetKit
import SwiftUI
import MEGADomain
import MEGAData

struct RecentsTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    var viewModel = RecentsQuickAccessWidgetViewModel(
        credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo),
        copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository.newRepo),
        recentItemsUseCase: RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance()))
    )
    
    func placeholder(in context: Context) -> QuickAccessWidgetEntry {
        QuickAccessWidgetEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickAccessWidgetEntry) -> Void) {
        completion(QuickAccessWidgetEntry(date: Date(), section: SectionDetail.recents.title, link: SectionDetail.recents.link, value: viewModel.fetchRecentItems()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAccessWidgetEntry>) -> Void) {
        let timeline = Timeline(entries: [QuickAccessWidgetEntry(date: Date(), section: SectionDetail.recents.title, link: SectionDetail.recents.link, value: viewModel.fetchRecentItems())], policy: .never)
        completion(timeline)
    }

}

struct RecentsQuickAccessWidget: Widget {
    let kind: String = MEGARecentsQuickAccessWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentsTimelineProvider()) { entry in
            QuickAccessWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Localizable.quickAccess)
        .description(Strings.Localizable.quicklyAccessFilesOnRecentsSection)
        .supportedFamilies([.systemLarge])
    }
}
