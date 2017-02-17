
#import "RNGeoPackageLibrary.h"

@implementation RNGeoPackageLibrary

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(LibrarySampleCall:(NSString *)testString callback:(RCTResponseSenderBlock)callback) {
     callback(@[testString]);
}

@end
  
