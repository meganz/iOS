
#import <Foundation/Foundation.h>

@interface MEGATransfer (MNZCategory)

#pragma mark - Thumbnails and previews

- (void)mnz_createThumbnailAndPreview;
- (void)mnz_renameOrRemoveThumbnailAndPreview;

#pragma mark - App data

- (void)mnz_parseAppData;
- (void)mnz_saveInPhotosApp;
- (void)mnz_setNodeCoordinates;

- (NSUInteger)mnz_orderByState;

@end
