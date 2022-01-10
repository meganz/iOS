import Foundation
import Combine

extension Publisher {
    func combinePrevious(_ initialResult: Output) -> AnyPublisher<(previous: Output, current: Output), Failure> {
        scan((initialResult, initialResult)) {
            ($0.1, $1)
        }
        .eraseToAnyPublisher()
    }
}
