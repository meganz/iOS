#import "AssetFetchResult.h"

@implementation AssetFetchResult

- (instancetype)initWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes fetchResult:(PHFetchResult<PHAsset *> *)fetchResult {
    self = [super init];
    if (self) {
        _mediaTypes = mediaTypes;
        _fetchResult = fetchResult;
    }
    
    return self;
}

- (BOOL)isContainedByAssetFetchResult:(AssetFetchResult *)result {
    for (NSNumber *mediaType in self.mediaTypes) {
        if (![result.mediaTypes containsObject:mediaType]) {
            return NO;
        }
    }
    
    return YES;
}

@end
