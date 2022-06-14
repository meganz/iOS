import WidgetKit
import SwiftUI

struct OfflineTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    var viewModel = OfflineQuickAccessWidgetViewModel(
        authUseCase: AuthUseCase(repo: AuthRepository(sdk: MEGASdkManager.sharedMEGASdk()), credentialRepo: CredentialRepository()),
        copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository(fileManager: FileManager.default)),
        offlineFilesBasesUseCase: OfflineFilesUseCase(repo: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdkManager.sharedMEGASdk()))
    )
    
    func placeholder(in context: Context) -> QuickAccessWidgetEntry {
        QuickAccessWidgetEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickAccessWidgetEntry) -> Void) {
        completion(QuickAccessWidgetEntry(date: Date(), section: SectionDetail.offline.title, link: SectionDetail.offline.link, value: viewModel.fetchOfflineItems()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAccessWidgetEntry>) -> Void) {
        let timeline = Timeline(entries: [QuickAccessWidgetEntry(date: Date(), section: SectionDetail.offline.title, link: SectionDetail.offline.link, value: viewModel.fetchOfflineItems())], policy: .never)
        completion(timeline)
    }

}

struct OfflineQuickAccessWidget: Widget {
    let kind: String = MEGAOfflineQuickAccessWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OfflineTimelineProvider()) { entry in
            QuickAccessWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Localizable.quickAccess)
        .description(Strings.Localizable.quicklyAccessFilesOnOfflineSection)
        .supportedFamilies([.systemLarge])
    }
}
