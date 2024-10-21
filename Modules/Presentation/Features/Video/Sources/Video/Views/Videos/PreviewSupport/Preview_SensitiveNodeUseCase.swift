import Foundation
import MEGADomain
import MEGASwift

struct Preview_SensitiveNodeUseCase: SensitiveNodeUseCaseProtocol {
    func isAccessible() -> Bool {
        false
    }
        
    func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        false
    }
    
    func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        false
    }
    
    func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    }
    
    func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func mergeInheritedAndDirectSensitivityChanges(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    }
    
    func folderSensitivityChanged() -> AnyAsyncSequence<Void> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
