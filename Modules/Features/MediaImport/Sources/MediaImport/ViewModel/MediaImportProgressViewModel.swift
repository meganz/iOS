import Foundation

@MainActor
public final class MediaImportProgressViewModel: ObservableObject {
    @Published public var progress: Double = 0
    @Published public var completedCount: Int = 0
    public let totalCount: Int

    public init(totalCount: Int) {
        self.totalCount = totalCount
    }
}
