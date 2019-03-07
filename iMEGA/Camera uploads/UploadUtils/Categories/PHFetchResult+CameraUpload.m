
#import "PHFetchResult+CameraUpload.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "SavedIdentifierParser.h"
#import "PHAsset+CameraUpload.h"

@implementation PHFetchResult (CameraUpload)

- (NSArray<PHAsset *> *)findNewAssetsByUploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    return [self findNewAssetsByUploadRecords:records forLivePhoto:NO];
}

- (NSArray<PHAsset *> *)findNewLivePhotoAssetsByUploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    return [self findNewAssetsByUploadRecords:records forLivePhoto:YES];
}

- (NSArray<PHAsset *> *)findNewAssetsByUploadRecords:(NSArray<MOAssetUploadRecord *> *)records forLivePhoto:(BOOL)livePhoto {
    if (self.count == 0) {
        return @[];
    }
    
    NSMutableArray<NSString *> *scannedLocalIds = [NSMutableArray arrayWithCapacity:records.count];
    for (MOAssetUploadRecord *record in records) {
        if (record.localIdentifier) {
            [scannedLocalIds addObject:record.localIdentifier];
        }
    }
    NSComparator localIdComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    NSArray<NSString *> *sortedLocalIds = [scannedLocalIds sortedArrayUsingComparator:localIdComparator];
    
    SavedIdentifierParser *identifierParser = [[SavedIdentifierParser alloc] init];
    
    NSMutableArray<PHAsset *> *newAssets = [NSMutableArray array];
    for (PHAsset *asset in self) {
        NSString *identifier = asset.localIdentifier;
        if (livePhoto) {
            if (!asset.mnz_isLivePhoto) {
                continue;
            }
            
            identifier = [identifierParser savedIdentifierForLocalIdentifier:identifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
        }
        
        NSUInteger matchingIndex = [sortedLocalIds indexOfObject:identifier inSortedRange:NSMakeRange(0, sortedLocalIds.count) options:NSBinarySearchingFirstEqual usingComparator:localIdComparator];
        if (matchingIndex == NSNotFound) {
            [newAssets addObject:asset];
        }
    }
    
    return [newAssets copy];
}


@end
