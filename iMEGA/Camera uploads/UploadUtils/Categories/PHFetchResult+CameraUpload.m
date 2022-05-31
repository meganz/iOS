
#import "PHFetchResult+CameraUpload.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "SavedIdentifierParser.h"
#import "MEGA-Swift.h"

@implementation PHFetchResult (CameraUpload)

- (NSArray<PHAsset *> *)findNewAssetsInUploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    return [self findNewAssetsInUploadRecords:records isForLivePhoto:NO];
}

- (NSArray<PHAsset *> *)findNewLivePhotoAssetsInUploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    return [self findNewAssetsInUploadRecords:records isForLivePhoto:YES];
}

- (NSArray<PHAsset *> *)findNewAssetsInUploadRecords:(NSArray<MOAssetUploadRecord *> *)records isForLivePhoto:(BOOL)isForLivePhoto {
    if (self.count == 0) {
        return @[];
    }
    
    NSMutableDictionary<NSString *, NSNumber *> *localRecordsDict = [NSMutableDictionary dictionaryWithCapacity:records.count];
    for (MOAssetUploadRecord *record in records) {
        if (record.localIdentifier) {
            localRecordsDict[record.localIdentifier] = @(YES);
        }
    }
    
    SavedIdentifierParser *identifierParser = [[SavedIdentifierParser alloc] init];
    NSMutableArray<PHAsset *> *newAssets = [NSMutableArray array];
    for (PHAsset *asset in self) {
        @autoreleasepool {
            NSString *identifier = asset.localIdentifier;
            if (isForLivePhoto) {
                if (!asset.mnz_isLivePhoto) {
                    continue;
                }
                
                identifier = [identifierParser savedIdentifierForLocalIdentifier:identifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
            }
            
            if (![localRecordsDict[identifier] boolValue]) {
                [newAssets addObject:asset];
            }
        }
    }
    
    return [newAssets copy];
}


@end
