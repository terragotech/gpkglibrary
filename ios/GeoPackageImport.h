//
//  GeoPackageImport.h
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 07/03/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "geopackage-ios-Bridging-Header.h"
#import "FormElement.h"
#import "GPKGDataTypes.h"
#import "GeoPackageFormTemplate.h"
#import "GeoPackageEdgeNote.h"
#import "GeoPackageDMEdgeNote.h"
#import "FormCaptured.h"
#import "FormCaptureWrite.h"
#import "Constants.h"

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
-(DMFormTemplate*)createFormTemplateforFeatureClass:(NSString*)featureName;
-(NSMutableArray*)importFeaturesforFeatureTemplate:(DMFormTemplate*)featureTemplate forFeatureClass:(NSString*)featureName;
-(NSMutableArray*)importFeaturesforFeatureTemplate:(DMFormTemplate*)featureTemplate forFeatureClass:(NSString*)featureName withAttribute:(NSString*)attributeName;
-(NSString*)getFeatureIDforFeatureClass:(NSString*)featureName;
-(void)geoPackageImportforFeatureClass:(NSString*)featureName;

-(BOOL)isFormFeatureclass:(NSString*)featureClassName;
-(NSMutableArray*)importFeaturesforNonFormNotesFeatureClass:(NSString*)featureName;

@end
