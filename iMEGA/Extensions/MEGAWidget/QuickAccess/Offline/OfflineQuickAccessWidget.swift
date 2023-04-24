import WidgetKit
import SwiftUI
import MEGADomain

struct OfflineTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    var viewModel = OfflineQuickAccessWidgetViewModel(
        credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo),
        copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository(fileManager: FileManager.default)),
        offlineFilesBasesUseCase: OfflineFilesUseCase(repo: OfflineFileFetcherRepository.newRepo)
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
