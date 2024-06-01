import Foundation
import MEGADomain

public final class CancelAccountPlanViewModel: ObservableObject {
    let currentPlanName: String
    let currentPlanStorageUsed: String
    let featureListHelper: FeatureListHelperProtocol
    let router: CancelAccountPlanRouting
    
    @Published private(set) var features: [FeatureDetails] = []

    init(
        currentPlanName: String,
        currentPlanStorageUsed: String,
        featureListHelper: FeatureListHelperProtocol,
        router: CancelAccountPlanRouting
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
