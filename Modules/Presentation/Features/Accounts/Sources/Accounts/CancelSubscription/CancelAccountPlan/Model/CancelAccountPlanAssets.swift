public struct CancelAccountPlanAssets {
    let availableImageName: String
    let unavailableImageName: String

    public init(availableImageName: String, unavailableImageName: String) {
        self.availableImageName = availableImageName
        self.unavailableImageName = unavailableImageName
    }
}
