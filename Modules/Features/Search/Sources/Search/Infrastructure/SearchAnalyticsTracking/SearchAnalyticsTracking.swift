public protocol SearchAnalyticsTracking: Sendable {
    func trackChipTapped(_ chip: SearchChipEntity, selected: Bool)
    func trackChipPickerShow(_ chip: SearchChipEntity)
    func trackResultContextMenuTapped()
}
