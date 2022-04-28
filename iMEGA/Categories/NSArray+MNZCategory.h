NS_ASSUME_NONNULL_BEGIN

@interface NSArray (MNZCategory)

- (nonnull NSArray<NSNumber *> *)mnz_numberOfFilesAndFolders;

/**
 Returns the object located at index, or return nil when out of bounds.
 It's similar to `objectAtIndex:`, but it never throw exception.
 
 @param index The object located at index.
 */
- (nullable id)objectOrNilAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
