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
}

typedef enum Goetypes
{
    POINT = 1,
    LINESTRING = 2,
    POLYGON = 3
} GeomentryType;

@property(nonatomic, retain)NSMutableArray* columnsTypesArray;
@property(nonatomic, retain)NSMutableArray* featureClasses;

+(GeoPackageSingleton*)getSharedInstanceValue;
-(int)createFeatureTable:(NSMutableDictionary*)featureDict forGeomentry:(GeomentryType)geomentry;
-(void)insertFeatureTableRecord:(NSMutableDictionary*)featureRecordDict forGeomentry:(GeomentryType)geomentry;
-(void)initGeoPackageatPath:(NSString*)path forFileName:(NSString*)filename;

@end
