
#import <Foundation/Foundation.h>

@interface MEGATransfer (MNZCategory)

- (void)mnz_parseAppData;

- (void)mnz_cancelPendingCUTransfer;
- (void)mnz_cancelPendingCUVideoTransfer;
- (void)mnz_saveInPhotosApp;
- (void)mnz_attachtToChatID:(NSString *)attachToChatID;
- (void)mnz_setNodeCoordinates;

@end
