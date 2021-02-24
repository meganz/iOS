
import WidgetKit

final class QuickAccessViewController: ViewType {
    
    let viewModel: QuickAccessWidgetViewModel

    init(viewModel: QuickAccessWidgetViewModel) {
        self.viewModel = viewModel
        
        self.viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        self.viewModel.dispatch(.onWidgetReady)
    }
    
    func executeCommand(_ command: QuickAccessWidgetViewModel.Command) {
        WidgetCenter.shared.reloadTimelines(ofKind: QuickAccessWidget().kind)
    }
    
    func entries(for configuration: SelectSectionIntent) -> QuickAccessWidgetEntry {
        switch configuration.section?.identifier {
        case SectionDetail.offline.link:
            return QuickAccessWidgetEntry(date: Date(), section: SectionDetail.offline.title, link: SectionDetail.offline.link, value: viewModel.fetchOfflineItems())
        case SectionDetail.recents.link:
            return QuickAccessWidgetEntry(date: Date(), section: SectionDetail.recents.title, link: SectionDetail.recents.link, value: viewModel.fetchRecentItems())
        case SectionDetail.favourites.link:
            return QuickAccessWidgetEntry(date: Date(), section: SectionDetail.favourites.title, link: SectionDetail.favourites.link, value: viewModel.fetchFavouriteItems())
        default:
            return QuickAccessWidgetEntry(date: Date(), section: SectionDetail.defaultSection.title, link: SectionDetail.defaultSection.link, value: viewModel.fetchOfflineItems())
        }
    }
}
