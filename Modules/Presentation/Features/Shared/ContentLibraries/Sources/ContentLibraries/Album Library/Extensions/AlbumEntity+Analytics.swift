import MEGAAnalyticsiOS
import MEGADomain

extension AlbumEntity {
    func makeAlbumSelectedEvent(selectionType: AlbumSelected.SelectionType) -> AlbumSelectedEvent {
        AlbumSelectedEvent(
            selectionType: selectionType,
            imageCount: metaData?.imageCount.toKotlinInt(),
            videoCount: metaData?.videoCount.toKotlinInt()
        )
    }
}
 
