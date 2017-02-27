
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

RCT_EXPORT_METHOD(initGeoPackageatPath:(NSString *)path  forFileName:(NSString*)filename callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]initGeoPackageatPath:path forFileName:filename];
    callback(@[@""]);
}
//createFeatureclass (featureDict, geomentry)
RCT_EXPORT_METHOD(createFeatureclass:(NSDictionary *)featureDict  forGeomentryType:(int)geomentry callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]createFeatureclass:featureDict forGeomentry:geomentry];
    callback(@[@""]);
}
//insertFeatureclassRecord:(featureRecordDict, geomentry)
RCT_EXPORT_METHOD(insertFeatureclassRecord:(NSDictionary *)featurerecordDict  forGeomentryType:(int)geomentry callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]insertFeatureclassRecord:featurerecordDict forGeomentry:geomentry];
    callback(@[@""]);
}

RCT_EXPORT_METHOD(closeGeoPackage:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]closeGeoPackage];
    callback(@[@""]);
}

//import details
RCT_EXPORT_METHOD(getgpkgFileDetails:(NSString *)path callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]initGeoPackageforPath:path];
     callback(@[@""]);
}

RCT_EXPORT_METHOD(checkIsRasterforPath:(NSString *)path callback:(RCTResponseSenderBlock)callback) {
    BOOL isRaster = [[GeoPackageSingleton getSharedInstanceValue]checkIsRasterforPath:path];
    NSString *result = @"false";
    if (isRaster) {
        result = @"true";
    }
    callback(@[result]);
}
@end

