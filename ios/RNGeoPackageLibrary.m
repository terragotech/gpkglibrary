
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
RCT_EXPORT_METHOD(createFeatureclass:(NSDictionary *)featureDict  forGeomentryType:(GeomentryType)geomentry callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]createFeatureTable:featureDict forGeomentry:geomentry];
    callback(@[@""]);
}
//insertFeatureclassRecord:(featureRecordDict, geomentry)
RCT_EXPORT_METHOD(insertFeatureclassRecord:(NSDictionary *)featurerecordDict  forGeomentryType:(GeomentryType)geomentry callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]insertFeatureTableRecord:featurerecordDict forGeomentry:geomentry];
    callback(@[@""]);
}

@end
  
