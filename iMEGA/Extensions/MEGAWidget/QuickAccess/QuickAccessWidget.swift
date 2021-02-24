
import WidgetKit
import SwiftUI

struct QuickAccessProvider: IntentTimelineProvider {
    
    var viewController = QuickAccessViewController(
        viewModel: QuickAccessWidgetViewModel(
            authUseCase: AuthUseCase(repo: AuthRepository(sdk: MEGASdkManager.sharedMEGASdk())),
            copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository(fileManager: FileManager.default)),
            offlineFilesBasesUseCase: OfflineFilesUseCase(repo: OfflineFilesRepository(store: MEGAStore.shareInstance())),
            recentItemsUseCase: RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance())),
            favouriteItemsUseCase: FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance()))))
    
    typealias Intent = SelectSectionIntent

    typealias Entry = QuickAccessWidgetEntry
    
    func placeholder(in context: Context) -> QuickAccessWidgetEntry {
        QuickAccessWidgetEntry(date: Date(),
                               section: SectionDetail.defaultSection.title,
                               link: "not-valid-link",
                               value: ([QuickAccessItemModel(thumbnail: Image("generic"),name: "File.txt", url: URL(fileURLWithPath: "not-valid-url"), image: nil, description: nil)], .connected))
    }
    
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        completion(viewController.entries(for: configuration))
    }
    
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let timeline = Timeline(entries: [viewController.entries(for: configuration)], policy: .never)
        completion(timeline)
    }
}

struct QuickAccessWidget: Widget {
    let kind: String = MEGAQuickAccessWidget

    var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: SelectSectionIntent.self, provider: QuickAccessProvider()) { entry in
            QuickAccessWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("Quick Access", comment: "Text title for shortcuts, ie in the widget"))
        .description(NSLocalizedString("Display items of a section in the MEGA app", comment: "Text description leading the user to perform an action, ie the shortcuts widget"))
        .supportedFamilies([.systemLarge])
    }
}

typealias EntryValue = (items: [QuickAccessItemModel], status: WidgetStatus)

struct QuickAccessWidgetEntry: TimelineEntry {
    let date: Date
    let section: String
    let link: String
    let value: EntryValue
}

