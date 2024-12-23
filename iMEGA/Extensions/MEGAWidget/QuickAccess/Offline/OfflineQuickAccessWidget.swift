import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SwiftUI
import WidgetKit

struct OfflineTimelineProvider: TimelineProvider {
    typealias Entry = QuickAccessWidgetEntry

    let viewModel: OfflineQuickAccessWidgetViewModel
    
    func placeholder(in context: Context) -> QuickAccessWidgetEntry {
        QuickAccessWidgetEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (QuickAccessWidgetEntry) -> Void) {
        Task { @MainActor in
            completion(QuickAccessWidgetEntry(date: Date(), section: SectionDetail.offline.title, link: SectionDetail.offline.link, value: viewModel.fetchOfflineItems()))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<QuickAccessWidgetEntry>) -> Void) {
        Task { @MainActor in
            let timeline = Timeline(entries: [QuickAccessWidgetEntry(date: Date(), section: SectionDetail.offline.title, link: SectionDetail.offline.link, value: viewModel.fetchOfflineItems())], policy: .never)
            completion(timeline)
        }
    }

}

struct OfflineQuickAccessWidget: Widget {
    let kind: String = MEGAOfflineQuickAccessWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: OfflineTimelineProvider(
                viewModel: OfflineQuickAccessWidgetViewModel(
                    credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo),
                    copyDataBasesUseCase: CopyDataBasesUseCase(repo: CopyDataBasesRepository.newRepo),
                    offlineFilesBasesUseCase: OfflineFilesUseCase(repo: OfflineFileFetcherRepository.newRepo)
                )
            )
        ) { entry in
            QuickAccessWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Localizable.quickAccess)
        .description(Strings.Localizable.quicklyAccessFilesOnOfflineSection)
        .supportedFamilies([.systemLarge])
    }
}
