public struct RubbishBinSettingsEntity: Sendable {
    public let rubbishBinAutopurgePeriod: Int
    public let rubbishBinCleaningSchedulerEnabled: Bool
    
    public init(rubbishBinAutopurgePeriod: Int, rubbishBinCleaningSchedulerEnabled: Bool) {
        self.rubbishBinAutopurgePeriod = rubbishBinAutopurgePeriod
        self.rubbishBinCleaningSchedulerEnabled = rubbishBinCleaningSchedulerEnabled
    }
}
