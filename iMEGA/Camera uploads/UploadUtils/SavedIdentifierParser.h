
#import <Foundation/Foundation.h>
#import "AssetIdentifierInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface SavedIdentifierParser : NSObject

- (AssetIdentifierInfo *)parseSavedIdentifier:(NSString *)identifier separator:(NSString *)separator;

@end

NS_ASSUME_NONNULL_END
