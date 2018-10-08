//
//  MOAssetUploadRecord+CoreDataProperties.m
//  
//
//  Created by Simon Wang on 9/10/18.
//
//

#import "MOAssetUploadRecord+CoreDataProperties.h"

@implementation MOAssetUploadRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AssetUploadRecord"];
}

@dynamic localIdentifier;
@dynamic status;

@end
