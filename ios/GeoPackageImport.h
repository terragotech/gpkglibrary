//
//  GeoPackageImport.h
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 07/03/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "geopackage-ios-Bridging-Header.h"
#import "GPKGDataTypes.h"
#import "GPKGConstant.h"

@interface GeoPackageImport : NSObject
{
    BOOL imported;
    GPKGGeoPackageManager *manager;
    GPKGGeoPackage * geoPackage;
    NSString *srcPath;
    NSFileManager *fileManager;
}
-(void)initGeoPackageforpath:(NSString*)urlString;
-(void)closeGeoPackage;
-(NSArray*)getAllFeatureClasses;
-(NSArray*)getAllAttributesforFeature:(NSString*)featureName;
-(int)notescountforFeature:(NSString*)featureName;
-(NSMutableDictionary*)createFormTemplateforFeatureClass:(NSString*)featureName;
-(NSMutableArray*)importFeaturesforFeatureTemplate:(NSMutableDictionary*)featureTemplate forFeatureClass:(NSString*)featureName;
-(NSMutableArray*)importFeaturesforFeatureTemplate:(NSMutableDictionary*)featureTemplate forFeatureClass:(NSString*)featureName withAttribute:(NSString*)attributeName;
-(NSString*)getFeatureIDforFeatureClass:(NSString*)featureName;
-(void)geoPackageImportforFeatureClass:(NSString*)featureName;

-(BOOL)isFormFeatureclass:(NSString*)featureClassName;
-(NSMutableArray*)importFeaturesforNonFormNotesFeatureClass:(NSString*)featureName;

@end
