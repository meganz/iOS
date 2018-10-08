//
//  MOAssetUploadStatus+CoreDataProperties.m
//  
//
//  Created by Simon Wang on 9/10/18.
//
//

#import "MOAssetUploadStatus+CoreDataProperties.h"

@implementation MOAssetUploadStatus (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadStatus *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadRecord"];
}

@dynamic localIdentifier;
@dynamic status;

@end
