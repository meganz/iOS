import MEGADomain
import MEGAData

extension NodeCollectionViewCell {
    
    @objc func createNodeCollectionCellViewModel() -> NodeCollectionViewCellViewModel {
        let mediaUseCase = MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo,
                                        videoMediaUseCase: VideoMediaUseCase(videoMediaRepository: VideoMediaRepository.newRepo))
        return NodeCollectionViewCellViewModel(mediaUseCase: mediaUseCase)
    }
    
}
