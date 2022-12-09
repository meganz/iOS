import Foundation
import MEGAFoundation

struct MEGAPlan: Equatable {
    typealias DataMeasurementInGB = Measurement<UnitDataStorage>
    typealias DateDurationInMonth = Int
    typealias PriceInCents = Int
    typealias Currency = String
    typealias Price = PriceInCents
    typealias Description = String
    typealias MEGASDKProductIndex = Int

    let id: MEGASDKProductIndex
    let storage: DataMeasurementInGB
    let transfer: DataMeasurementInGB
    let subscriptionLife: DateDurationInMonth
    let price: Price
    let currency: Currency?
    let proLevel: MEGAAccountType
    let description: Description
}

extension MEGAPlan {

    var readableName: String {
        MEGAAccountDetails.string(for: proLevel)
    }

    var storageSpaceInBytes: Measurement<UnitDataStorage> {
        storage.converted(to: .bytes)
    }
}
