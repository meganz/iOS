public enum DIContainer {
    public nonisolated(unsafe) static var searchTracker: (any SearchAnalyticsTracking) = PlaceHolderSearchAnalyticsTracker()
}

private struct PlaceHolderSearchAnalyticsTracker: SearchAnalyticsTracking {
    func trackChipTapped(_ chip: SearchChipEntity, selected: Bool) {}
    func trackChipPickerShow(_ chip: SearchChipEntity) {}
    func trackResultContextMenuTapped() {}
}
