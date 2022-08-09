@interface NSObject (Debounce)

- (void)debounce:(SEL)action delay:(NSTimeInterval)delay;

@end