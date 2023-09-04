#import <Foundation/Foundation.h>
#import "AssetIdentifierInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface SavedIdentifierParser : NSObject

- (NSString *)savedIdentifierForLocalIdentifier:(NSString *)identifier mediaSubtype:(PHAssetMediaSubtype)subtype;
- (AssetIdentifierInfo *)parseSavedIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
