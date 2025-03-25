import DeviceCenter
import MEGAL10n
import SwiftUI

final class ResourceInfoViewModel: ObservableObject {
    var icon: Image {
        infoModel.icon
    }
    
    var title: String {
        infoModel.name
    }
    
    var totalSize: String {
        String.memoryStyleString(fromByteCount: Int64(infoModel.totalSize))
    }
    
    var formattedDate: String {
        infoModel.formattedAddedDate
    }
    
    var contentDescription: String {
        infoModel.counter.formattedResourceContents
    }
    
    var infoModel: ResourceInfoModel
    var router: any ResourceInfoViewRouting
    
    init(
        infoModel: ResourceInfoModel,
        router: any ResourceInfoViewRouting
    ) {
        self.infoModel = infoModel
        self.router = router
    }
    
    func dismiss() {
        router.dismiss()
    }
}
