import Foundation
@testable import MEGA

extension ShareEntity {
    init() {
        self.init(sharedUserEmail: nil, nodeHandle: 0, accessLevel: .unknown, createdDate: Date(), isPending: false)
    }
}
