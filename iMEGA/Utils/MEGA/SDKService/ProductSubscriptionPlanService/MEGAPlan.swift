import Foundation

struct MEGAPlan {
    typealias DataMeasurementInGB = Measurement<UnitDataStorage>
    typealias DateDurationInMonth = Int
    typealias PriceInCents = Int
    typealias Currency = String
    typealias Price = (price: PriceInCents, currency: Currency)
    typealias Description = String
    typealias MEGASDKProductIndex = Int

    let id: MEGASDKProductIndex
    let storage: DataMeasurementInGB
    let transfer: DataMeasurementInGB
    let subscriptionLife: DateDurationInMonth
    let price: Price
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
