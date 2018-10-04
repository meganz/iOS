//
//  MOAssetUploadStatus+CoreDataProperties.m
//  
//
//  Created by Simon Wang on 5/10/18.
//
//

#import "MOAssetUploadStatus+CoreDataProperties.h"

@implementation MOAssetUploadStatus (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadStatus *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadStatus"];
}

@dynamic localIdentifier;
@dynamic statusCode;

@end
