import Foundation
@testable import MEGA

final class MockShareList: MEGAShareList {
    private let shares: [MEGAShare]
    
    init(shares: [MEGAShare] = []) {
        self.shares = shares
        super.init()
    }
    
    override var size: NSNumber! {
        NSNumber(value: shares.count)
    }
  
    override func share(at index: Int) -> MEGAShare! {
        shares[index]
    }
}
