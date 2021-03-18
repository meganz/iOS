import WidgetKit
import SwiftUI

struct RecentsTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    var viewModel = RecentsQuickAccessWidgetViewModel(
        authUseCase: AuthUseCase(repo: AuthRepository(sdk: MEGASdkManager.sharedMEGASdk())),
        copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository(fileManager: FileManager.default)),
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
        .configurationDisplayName(NSLocalizedString("Quick Access", comment: "Title for the QuickAccess widget"))
        .description(NSLocalizedString("Quickly access files on Recents section", comment: "Text description for the Recents QuickAccess widget"))
        .supportedFamilies([.systemLarge])
    }
}
