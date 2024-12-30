import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

typealias Helper = NodeTagsUpdatesUseCaseTests.Helper

@Suite("NodeTagsUpdatesUseCase")
struct NodeTagsUpdatesUseCaseTests {

    @Suite("Single update related to the target node")
    struct TargetNodeSingleUpdateTests {
        @Test(
            "Verify output events for updates related to target node",
            arguments: [
                Arguments.targetNodeRemoved,
                .targetNodeInRubbishedBin,
                .targetNodeTagsUpdated,
                .targetNodeAttributesUpdated
            ]
        )
        func tagsUpdates(argument: Arguments) async {
            let (sut, nodeRepo, nodeTagsRepo) = Helper.makeSut()
            let results = Atomic<[TagsUpdatesEntity]>(wrappedValue: [])

            let listeningTask = Task {
                for await event in sut.tagsUpdates(for: Helper.targetNode) {
                    results.mutate { $0.append(event) }
                }
            }

            try? await Task.sleep(nanoseconds: 1_000_000)

            Task {
                let updatedNode = argument.input.updatedNode
                argument.input.setupRepos?(nodeRepo, nodeTagsRepo)
                nodeRepo.simulateNodeUpdates([updatedNode])
                try? await Task.sleep(nanoseconds: 10_000_000)
                #expect(results.wrappedValue == argument.output)
                listeningTask.cancel()
            }

            await listeningTask.value
        }
    }

    @Suite("Single update not related to the target node")
    struct GeneralNodeSingleUpdateTests {
        @Test(
            "Verify output events for updates related to target node",
            arguments: [
                Arguments.targetNodeAttributesUpdated,
                .nonTargetNodeRemovedWithTags,
                .nonTargetNodeRemovedWithoutTags,
                .nonTargetNodeUpdatedWithTags
            ]
        )
        func tagsUpdates(argument: Arguments) async {
            let (sut, nodeRepo, nodeTagsRepo) = Helper.makeSut()
            let results = Atomic<[TagsUpdatesEntity]>(wrappedValue: [])

            let listeningTask = Task {
                for await event in sut.tagsUpdates(for: Helper.targetNode) {
                    results.mutate { $0.append(event) }
                }
            }

            try? await Task.sleep(nanoseconds: 1_000_000)

            Task {
                let updatedNode = argument.input.updatedNode
                argument.input.setupRepos?(nodeRepo, nodeTagsRepo)
                nodeRepo.simulateNodeUpdates([updatedNode])
                try? await Task.sleep(nanoseconds: 10_000_000)
                #expect(results.wrappedValue == argument.output)
                listeningTask.cancel()
            }

            await listeningTask.value
        }
    }
}

