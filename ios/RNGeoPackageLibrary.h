
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#import "RCTDefines.h"
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTDefines.h>
#endif
#import "GeoPackageSingleton.h"

@interface RNGeoPackageLibrary : NSObject <RCTBridgeModule>

@end

