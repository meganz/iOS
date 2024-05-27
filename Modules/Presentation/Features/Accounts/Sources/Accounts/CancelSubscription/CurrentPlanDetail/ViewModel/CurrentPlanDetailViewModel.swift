import Foundation
import MEGADomain

public final class CurrentPlanDetailViewModel: ObservableObject {
    let currentPlanName: String
    let currentPlanStorageUsed: String
    let featureListHelper: FeatureListHelperProtocol
    let router: CurrentPlanDetailRouting
    
    @Published private(set) var features: [FeatureDetails] = []

    init(
        currentPlanName: String,
        currentPlanStorageUsed: String,
        featureListHelper: FeatureListHelperProtocol,
        router: CurrentPlanDetailRouting
    ) {
        self.currentPlanName = currentPlanName
        self.currentPlanStorageUsed = currentPlanStorageUsed
        self.featureListHelper = featureListHelper
        self.router = router
    }
    
    @MainActor
    func setupFeatureList() {
        features = featureListHelper.createCurrentFeatures()
    }
    
    func dismiss() {
        router.dismiss()
    }
}
