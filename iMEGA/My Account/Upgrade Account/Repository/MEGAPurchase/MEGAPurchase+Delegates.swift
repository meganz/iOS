import Foundation

extension MEGAPurchase {
    private static let delegateQueue = DispatchQueue(label: "nz.mega.MEGAPurchase.delegateQueue")

    @objc func addPurchaseDelegate(_ delegate: any MEGAPurchaseDelegate) {
        Self.delegateQueue.sync {
            if !purchaseDelegateMutableArray.contains(where: { ($0 as AnyObject) === (delegate as AnyObject) }) {
                purchaseDelegateMutableArray.add(delegate)
            }
        }
    }

    @objc func removePurchaseDelegate(_ delegate: any MEGAPurchaseDelegate) {
        Self.delegateQueue.sync {
            purchaseDelegateMutableArray.remove(delegate)
        }
    }

    @objc func addRestoreDelegate(_ delegate: any MEGARestoreDelegate) {
        Self.delegateQueue.sync {
            if !restoreDelegateMutableArray.contains(where: { ($0 as AnyObject) === (delegate as AnyObject) }) {
                restoreDelegateMutableArray.add(delegate)
            }
        }
    }

    @objc func removeRestoreDelegate(_ delegate: any MEGARestoreDelegate) {
        Self.delegateQueue.sync {
            restoreDelegateMutableArray.remove(delegate)
        }
    }

    @objc func addPricingsDelegate(_ delegate: any MEGAPurchasePricingDelegate) {
        Self.delegateQueue.sync {
            if !pricingsDelegateMutableArray.contains(where: { ($0 as AnyObject) === (delegate as AnyObject) }) {
                pricingsDelegateMutableArray.add(delegate)
            }
        }
    }

    @objc func removePricingsDelegate(_ delegate: any MEGAPurchasePricingDelegate) {
        Self.delegateQueue.sync {
            pricingsDelegateMutableArray.remove(delegate)
        }
    }

    @objc var purchaseDelegates: [any MEGAPurchaseDelegate] {
        Self.delegateQueue.sync {
            purchaseDelegateMutableArray.compactMap { $0 as? any MEGAPurchaseDelegate }
        }
    }

    @objc var restoreDelegates: [any MEGARestoreDelegate] {
        Self.delegateQueue.sync {
            restoreDelegateMutableArray.compactMap { $0 as? any MEGARestoreDelegate }
        }
    }

    @objc var pricingDelegates: [any MEGAPurchasePricingDelegate] {
        Self.delegateQueue.sync {
            pricingsDelegateMutableArray.compactMap { $0 as? any MEGAPurchasePricingDelegate }
        }
    }
}
