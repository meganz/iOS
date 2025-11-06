import Combine
import MEGADomain
import SwiftUI

@MainActor
protocol AddItemsToCollectionViewModelProtocol {
    var isAddButtonDisabled: AnyPublisher<Bool, Never> { get }
    var isItemsNotEmptyPublisher: AnyPublisher<Bool, Never> { get }
    func addItems(_ photos: [NodeEntity])
}
