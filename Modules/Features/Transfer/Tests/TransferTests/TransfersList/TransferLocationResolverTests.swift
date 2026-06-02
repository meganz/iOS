import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

@Suite("TransferLocationResolver")
struct TransferLocationResolverTests {

    @Test func upload_resolvesDestinationParentNodeCloudPath() async {
        let parentHandle: HandleEntity = 42
        let parentNode = NodeEntity(handle: parentHandle)
        let sut = TransferLocationResolver(
            nodeUseCase: MockNodeUseCase(nodes: [parentHandle: parentNode]),
            nodeAttributeUseCase: MockNodeAttributeUseCase(pathForNodes: [parentNode: "/Cloud drive/Documents"])
        )
        let entity = TransferEntity(type: .upload, parentHandle: parentHandle, state: .complete)

        let location = await sut.location(for: entity)

        #expect(location == "/Cloud drive/Documents")
    }

    @Test func download_usesLocalParentPath() async {
        let sut = TransferLocationResolver(
            nodeUseCase: MockNodeUseCase(),
            nodeAttributeUseCase: MockNodeAttributeUseCase()
        )
        let entity = TransferEntity(type: .download, parentPath: "/Downloads/MEGA", state: .complete)

        let location = await sut.location(for: entity)

        #expect(location == "/Downloads/MEGA")
    }

    @Test func upload_withUnresolvableParent_returnsNil() async {
        let sut = TransferLocationResolver(
            nodeUseCase: MockNodeUseCase(),
            nodeAttributeUseCase: MockNodeAttributeUseCase()
        )
        let entity = TransferEntity(type: .upload, parentHandle: 99, state: .complete)

        let location = await sut.location(for: entity)

        #expect(location == nil)
    }
}
