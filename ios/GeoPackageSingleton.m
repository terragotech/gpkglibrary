//
//  GeoPackageSingleton.m
//  RNGeoPackageLibrary
//
//  Created by Sunilkarthick Sivabalan on 18/02/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "GeoPackageSingleton.h"

static GeoPackageSingleton *sharedsingletonGeoPackageValue = nil;
@implementation GeoPackageSingleton

+(GeoPackageSingleton*)getSharedInstanceValue{
    if (!sharedsingletonGeoPackageValue) {
        sharedsingletonGeoPackageValue = [[super allocWithZone:NULL]init];
    }
    return sharedsingletonGeoPackageValue;
}

-(void)initGeoPackageatPath:(NSString*)path forFileName:(NSString*)filename{
    NSError *error;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString * file = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",filename]];
    NSString* folderPath = [[NSString alloc]initWithFormat:@"%@",file ];
    if (![fileManager fileExistsAtPath:file])
        [fileManager createDirectoryAtPath:file withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    NSString* resourcePath =[NSString stringWithFormat:@"%@/resources",folderPath];
    if (![fileManager fileExistsAtPath:resourcePath])
        [fileManager createDirectoryAtPath:resourcePath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    
    file = [NSString stringWithFormat:@"%@/%@.gpkg",file,filename];
    
    manager = [GPKGGeoPackageFactory getManager];
    //    [manager open:[NSString stringWithFormat:@"%@/%@.gpkg",exportPath,fileName]];
    [manager deleteAll];
    //    [manager create:fileName];
    [manager close];
    manager = [GPKGGeoPackageFactory getManager];
    self.columnsTypesArray = [[NSMutableArray alloc]init];
    [manager create:filename];
    NSArray * databases = [manager databases];
    geoPackage = [manager open:[databases objectAtIndex:0]];
    [manager close];
    [geoPackage createGeometryColumnsTable];
    
    srsDao = [geoPackage getSpatialReferenceSystemDao];
    epsgSrs = (GPKGSpatialReferenceSystem *)[srsDao queryForIdObject:[NSNumber numberWithInt:4326]];
    geometryColumnsDao = [geoPackage getGeometryColumnsDao];
    contentsDao = [geoPackage getContentsDao];
    
    if (!self.featureClasses) {
        self.featureClasses = [[NSMutableArray alloc]init];
    }
    
    [self.featureClasses removeAllObjects];
}

-(int)createFeatureclass:(NSMutableDictionary*)featureDict forGeomentry:(int)geomentry{
    int ret = -1;
    
    NSString *featureName = [featureDict objectForKey:@"FeatureName"];
    NSMutableArray *featureColumns = [featureDict objectForKey:@"Columns"];
    GPKGContents * point2dContents = [[GPKGContents alloc] init];
    [point2dContents setTableName:featureName];
    [point2dContents setContentsDataType:GPKG_CDT_FEATURES];
    [point2dContents setIdentifier:featureName];
    //                [point2dContents set:@""];
    [point2dContents setLastChange:[NSDate date]];
    [point2dContents setMinX:[[NSDecimalNumber alloc] initWithDouble:-180.0]];
    [point2dContents setMinY:[[NSDecimalNumber alloc] initWithDouble:-90.0]];
    [point2dContents setMaxX:[[NSDecimalNumber alloc] initWithDouble:180.0]];
    [point2dContents setMaxY:[[NSDecimalNumber alloc] initWithDouble:90.0]];
    [point2dContents setSrs:epsgSrs];
    
    [self.columnsTypesArray removeAllObjects];
    
    enum WKBGeometryType geoColumnType = WKB_POINT;
    if (geomentry == 2) {
        geoColumnType = WKB_LINESTRING;
    }
    if (geomentry == 3) {
        geoColumnType = WKB_POLYGON;
    }
    NSMutableArray *columns = [[NSMutableArray alloc]init];
    [GPKGUtils addObject:[GPKGFeatureColumn createPrimaryKeyColumnWithIndex:0 andName:@"f_id"] toArray:columns];
    [GPKGUtils addObject:[GPKGFeatureColumn createGeometryColumnWithIndex:1 andName:@"geom" andGeometryType:geoColumnType andNotNull:false andDefaultValue:nil]toArray:columns];
    
    int i =2;
    for (NSDictionary *tdict in featureColumns) {
        GeoPackageColumn *gpc = [[GeoPackageColumn alloc]init];
        [gpc setFormelementID:[[tdict objectForKey:@"columnID"]intValue]];
        [gpc setColumnName:[tdict objectForKey:@"columnName"]];
        [gpc setColumnComponent:[tdict objectForKey:@"columnType"]];
        [self.columnsTypesArray addObject:gpc];
        [GPKGUtils addObject:[GPKGFeatureColumn createColumnWithIndex:i andName:[gpc columnName] andDataType:GPKG_DT_TEXT andNotNull:false andDefaultValue:nil]toArray:columns];
        i++;
    }
    
    GPKGFeatureTable *featureTable = [[GPKGFeatureTable alloc]initWithTable:featureName andColumns:columns];
    [geoPackage createFeatureTable:featureTable];
    
    [contentsDao create:point2dContents];
    
    GPKGGeometryColumns * point2dGeometryColumns = [[GPKGGeometryColumns alloc] init];
    [point2dGeometryColumns setContents:point2dContents];
    [point2dGeometryColumns setColumnName:@"geom"];
    [point2dGeometryColumns setGeometryType:geoColumnType];
    [point2dGeometryColumns setSrsId: point2dContents.srsId];
    [point2dGeometryColumns setZ:[NSNumber numberWithInt:0]];
    [point2dGeometryColumns setM:[NSNumber numberWithInt:0]];
    [geometryColumnsDao create:point2dGeometryColumns];
    
    ret = (int)[self.featureClasses count];
    [self.featureClasses addObject:featureTable];
    
    return ret;
}

-(void)insertFeatureclassRecord:(NSMutableDictionary*)featureRecordDict forGeomentry:(int)geomentry{
    
    NSString *featureName = [featureRecordDict objectForKey:@"FeatureName"];
    GPKGFeatureDao *featureDAO = [geoPackage getFeatureDaoWithTableName:featureName];
    
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDAO.projection];
    NSNumber * srsId = featureDAO.geometryColumns.srsId;
    
    GPKGFeatureRow * newLine;// = [featureDAO newRow];
    GPKGGeometryData * GeomData;
    NSString* geojson = [featureRecordDict objectForKey:@"Location"];
    
    NSMutableArray *pointsArray = [[NSMutableArray alloc]init];
    if (geomentry == 2) {
        for (CLLocation *loc in [self getCoordinatesFromGeoJson:geojson]) {
            [pointsArray addObject:[[GPKGMapPoint alloc]initWithLocation:[loc coordinate]]];
        }
        WKBLineString *line = [converter toLineStringWithMapPoints:pointsArray];
        GeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
        [GeomData setGeometry:line];
    }
    if (geomentry == 3) {
        for (CLLocation *loc in [self getCoordinatesFromGeoJson:geojson]) {
            [pointsArray addObject:[[GPKGMapPoint alloc]initWithLocation:[loc coordinate]]];
        }
        WKBPolygon *polygon = [converter toPolygonWithMapPoints:pointsArray andHolePoints:nil];
        GeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
        [GeomData setGeometry:polygon];
    }
    if (geomentry == 1) {
        GPKGMapPoint *pt;
        if ([[self getCoordinatesFromGeoJson:geojson]count]>=1) {
            CLLocationCoordinate2D cd = [(CLLocation*)[[self getCoordinatesFromGeoJson:geojson]objectAtIndex:0]coordinate];
            pt = [[GPKGMapPoint alloc]initWithLocation:cd];
        }
        WKBPoint * point = [converter toPointWithMapPoint:pt];
        GeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
        [GeomData setGeometry:point];
    }
    
    newLine = [featureDAO newRow];
    [newLine setGeometry:GeomData];
    NSMutableArray *valuesArray = [featureRecordDict objectForKey:@"values"];
    for (NSDictionary *tdict in valuesArray) {
        if ([[tdict objectForKey:@"columnName"]isEqualToString:@"fid"]) {
            continue;
        }
        [newLine setValueWithColumnName:[tdict objectForKey:@"columnName"] andValue:[tdict objectForKey:@"columnValue"]];
    }
    [featureDAO insert:newLine];
    
}

-(void)closeGeoPackage{
    [geoPackage close];
    [manager close];
}

-(NSMutableArray*)getCoordinatesFromGeoJson:(NSString*)geojson {
    NSMutableArray* coordinates = [[NSMutableArray alloc]init];
    @try {
        
        if ( !geojson || [geojson isEqualToString:@""] ) {
            return coordinates;
        }
        //     NSString * newString = [geometryVal stringByReplacingOccurrencesOfString:@"\"\"" withString:@"\""];
        //        NSString* geometry = geojson;
        
        
        NSMutableDictionary *json  = [NSJSONSerialization JSONObjectWithData:[geojson dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options:0 error:NULL];
        
        NSMutableDictionary *geomentry = [json objectForKey:@"geometry"];
        
        
        //for polygon geojson
        if ([[geomentry objectForKey:@"type"]isEqualToString:@"Polygon"]) {
            NSMutableArray *points = [[geomentry valueForKeyPath:@"coordinates"]objectAtIndex:0];
            for (int i = 0; i < [points count]; i++) {
                NSArray *arr = [points objectAtIndex:i];
                CLLocation *lc = [[CLLocation alloc]initWithLatitude:[[arr objectAtIndex:1]doubleValue] longitude:[[arr objectAtIndex:0]doubleValue]];
                [coordinates addObject:lc];
            }
        }
        //     {"type":"Feature","geometry":{"type":"LineString","coordinates":[[-65.56640624087308,-14.60484715306493],[-58.88671874180289,-4.390228925853468]]},"properties":{"name":""}}
        //for polyline geojson
        if ([[geomentry objectForKey:@"type"]isEqualToString:@"LineString"]) {
            NSMutableArray *points = [geomentry valueForKeyPath:@"coordinates"];
            for (int i = 0; i < [points count]; i++) {
                NSArray *arr = [points objectAtIndex:i];
                CLLocation *lc = [[CLLocation alloc]initWithLatitude:[[arr objectAtIndex:1]doubleValue] longitude:[[arr objectAtIndex:0]doubleValue]];
                [coordinates addObject:lc];
            }
        }
        
        //for point geojson
        if ([[geomentry objectForKey:@"type"]isEqualToString:@"Point"]) {
            NSMutableArray *points = [geomentry valueForKeyPath:@"coordinates"];
            if ([points count]==2) {
                CLLocation *lc = [[CLLocation alloc]initWithLatitude:[[points objectAtIndex:1]doubleValue] longitude:[[points objectAtIndex:0]doubleValue]];
                [coordinates addObject:lc];
            }
        }
    }
    @catch (NSException *exception) {
        
    }
    @finally{
        return coordinates;
    }
}

@end
