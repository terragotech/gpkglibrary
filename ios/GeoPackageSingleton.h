//
//  GeoPackageSingleton.h
//  RNGeoPackageLibrary
//
//  Created by Sunilkarthick Sivabalan on 18/02/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "geopackage-ios-Bridging-Header.h"
#import "GeoPackageColumn.h"
#import "GeoPackageRaster.h"
#import "GeoPackageImport.h"

@interface GeoPackageSingleton : NSObject
{
    GPKGGeoPackageManager *manager;
    GPKGGeoPackage *geoPackage;
    GPKGDataColumnsDao *dataColumnsDao;
    GPKGSpatialReferenceSystemDao *srsDao;
    GPKGSpatialReferenceSystem *epsgSrs;
    GPKGGeometryColumnsDao *geometryColumnsDao;
    GPKGContentsDao *contentsDao;
    GPKGDataColumnConstraintsDao *constraintsDao;
    
    //import
    GeoPackageImport *import;
}

typedef enum Goetypes
{
    POINT = 1,
    LINESTRING = 2,
    POLYGON = 3
} GeomentryType;

@property(nonatomic, retain)NSMutableArray* columnsTypesArray;
@property(nonatomic, retain)NSMutableArray* featureClasses;

//Export
+(GeoPackageSingleton*)getSharedInstanceValue;
-(int)createFeatureclass:(NSMutableDictionary*)featureDict forGeomentry:(int)geomentry;
-(void)insertFeatureclassRecord:(NSMutableDictionary*)featureRecordDict forGeomentry:(int)geomentry;
-(void)initGeoPackageatPath:(NSString*)path forFileName:(NSString*)filename;
-(void)closeGeoPackage;

//Import
@property(nonatomic,retain)GeoPackageRaster *georaster;
-(void)initGeoPackageforPath:(NSString*)path;
-(BOOL)checkIsRasterforPath:(NSString*)path;

@end
