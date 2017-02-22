//
//  GeoPackageImport.m
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 07/03/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import "GeoPackageImport.h"

@implementation GeoPackageImport

-(void)initGeoPackageforpath:(NSString*)urlString{
    manager = [GPKGGeoPackageFactory getManager];
    NSString *dbName = [[urlString lastPathComponent]stringByDeletingPathExtension];
    imported = [manager importGeoPackageFromPath:urlString andOverride:TRUE];
    if (imported) {
        srcPath = [urlString stringByDeletingLastPathComponent];
        fileManager = [NSFileManager defaultManager];
        NSArray * databases = [manager databases];
        geoPackage = [manager open:[databases objectAtIndex:[self getIndexforDB:databases withName:dbName]]];
    }
}

-(void)closeGeoPackage{
    imported = FALSE;
    [geoPackage close];
    [manager close];
}

-(NSArray*)getAllFeatureClasses{
    NSArray *features;
    if (imported) {
        features = [geoPackage getFeatureTables];
    }
    return features;
}

-(NSArray*)getAllAttributesforFeature:(NSString*)featureName{
    NSMutableArray *attributes = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        for (NSString *attrib in [[featureDao getFeatureTable]columnNames]) {
            if ([attrib isEqualToString:[[[featureDao getFeatureTable]getGeometryColumn]name]]) {
                continue;
            }
            [attributes addObject:attrib];;
        }
    }
    return attributes;
}

-(int)notescountforFeature:(NSString*)featureName{
    int cnt = 0;
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        cnt = [featureResults count];
        [featureResults close];
    }
    return cnt;
}

-(DMFormTemplate*)createFormTemplateforFeatureClass:(NSString*)featureName{
    if (imported) {
        NSMutableArray *formEleArray = [[NSMutableArray alloc]init];
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
       
        NSString *pkName = [[[featureDao getFeatureTable]getPkColumn]name];
        
        int index = 0;
        if ([[featureDao getFeatureTable]getPkColumn]) {
            FormElement *fe = [[FormElement alloc]init];
            [fe setComponent:@"numberInput"];
            [fe setIndex:index];
            [fe setFormelementID:index];
            index++;
            [fe setLabel:[[[featureDao getFeatureTable]getPkColumn]name]];
            [formEleArray addObject:fe];
        }
        for (GPKGFeatureColumn *clmn in [[featureDao getFeatureTable]columns]) {
            if ([clmn isGeometry] || [[clmn name]isEqualToString:pkName]) {
                continue;
            }
            FormElement *fe = [self formElementforDatatype:[clmn dataType]];
            if (!fe) {
                continue;
            }
            NSString *strCmnName = [clmn name];
            if ([strCmnName containsString:FormFeatureAudioColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureAudioColumn withString:@""];
                [fe setComponent:@"audioupload"];
            }else if ([strCmnName containsString:FormFeatureVideoColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureVideoColumn withString:@""];
                [fe setComponent:@"videoupload"];
            }else if ([strCmnName containsString:FormFeatureImageColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureImageColumn withString:@""];
                [fe setComponent:@"imageupload"];
            }else if ([strCmnName containsString:FormFeatureSignatureColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureSignatureColumn withString:@""];
                [fe setComponent:@"signature"];
            }
            [fe setLabel:strCmnName];
            [fe setIndex:index];
            [fe setFormelementID:index];
            index++;
            [formEleArray addObject:fe];
            
        }
        GeoPackageFormTemplate *geofTemp = [[GeoPackageFormTemplate alloc]init];
        return [geofTemp createFormtemplate:formEleArray withFormName:featureName];
    }
    return nil;
}

-(NSMutableArray*)importFeaturesforFeatureTemplate:(DMFormTemplate*)featureTemplate forFeatureClass:(NSString*)featureName{
     NSMutableArray *retArray = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
                NSMutableArray *frmCaptArr = [[NSMutableArray alloc]init];
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                FormDefinition *form=[[FormDefinition alloc]init];
                [form setFormGuid:[featureTemplate getGUID]];
                [form setFormName:[featureTemplate getName]];
                [form setFormTemplateGuid:[featureTemplate getGUID]];
                [form setFormTemplateId:[featureTemplate getId]];
                [form setFormDefinition:[featureTemplate getFormTemplateJson]];
                [form setFormTemplateDefFromJsonString:[featureTemplate getFormTemplateJson]];
                [form setCategory:[featureTemplate getCategory]];
                
                int index = 0;
                if ([featureRow getPkColumn]) {
                    FormCaptured *fc = [[FormCaptured alloc]init];
                    [fc setFormComponentID:index];
                    index++;
                    [fc setLabel:[[featureRow getPkColumn]name]];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]];
                    }
                    [fc setLabvalue:[NSString stringWithFormat:@"%@%@%@",[fc label],repeatableLabelDelimiter,val]];
                    [fc setGroupID:-1];
                    [fc setGroupRepeatableIndex:-1];
                    [fc setIsAttachment:FALSE];
                    [frmCaptArr addObject:fc];
                }
                for (GPKGFeatureColumn *featColm in [[featureRow table]columns]) {
                    if ([featColm isGeometry] || [[featColm name]isEqualToString:[[[featureDao getFeatureTable]getPkColumn]name]]) {
                        continue;
                    }
                    
                    if ([[featColm name]isEqualToString:@"SURVEY_DAT"]) {
                        
                    }
                    FormCaptured *fc = [[FormCaptured alloc]init];
                    [fc setFormComponentID:index];
                    [fc setLabel:[featColm name]];
                    [fc setIsAttachment:FALSE];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featColm index]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featColm index]]];
                    }
                    if ([[fc label]containsString:@"PicturesofDamage"]) {
                        
                    }
                    NSString *strCmnName = [fc label];
                    if ([strCmnName containsString:FormFeatureAudioColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureAudioColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureVideoColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureVideoColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureImageColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureImageColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureSignatureColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureSignatureColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }
                    [fc setLabel:strCmnName];
                    [fc setLabvalue:[NSString stringWithFormat:@"%@%@%@",[fc label],repeatableLabelDelimiter,val]];
                    [fc setGroupID:-1];
                    [fc setGroupRepeatableIndex:-1];
                    
                    [frmCaptArr addObject:fc];
                    index++;
                    
                }
                FormCaptureWrite *fcp = [[FormCaptureWrite alloc]init];
                [form setFormCapturedValues:[fcp writeFormdata:frmCaptArr]];
                GeoPackageDMEdgeNote *gpDMEdgeNote = [[GeoPackageDMEdgeNote alloc]init];
                [gpDMEdgeNote setEdgeForm:form];
                
                
                ED_EdgeNoteCopy *note = [[ED_EdgeNoteCopy alloc]init];
                [note setNoteType:@"forms"];
                NSMutableArray *coordi = [[NSMutableArray alloc]init];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                            CLLocation *loc = [[CLLocation alloc]initWithLatitude:cd.latitude longitude:cd.longitude];
                            [coordi addObject:loc];
                            [note setGeoType:@"Point"];
                            
                        }
                    }
                }
                if([[geometryData geometry]geometryType]==WKB_POLYGON){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolygon *polygon = (MKPolygon*)[shape shape];
                            int pointCount = (int)[polygon pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polygon getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setGeoType:@"Polygon"];
//                            
                        }
                    }
                }
                
                if([[geometryData geometry]geometryType]==WKB_LINESTRING){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolyline *polyLine = (MKPolyline*)[shape shape];
                            int pointCount = (int)[polyLine pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polyLine getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setGeoType:@"LineString"];
                        }
                    }
                }
                
                [note setCoordinates:coordi];
                [gpDMEdgeNote setEdgeNote:note];
                [retArray addObject:gpDMEdgeNote];

            }
        }@finally {
            [featureResults close];
            return retArray;
        }
    }
    return retArray;
}

-(void)copyResourceforFormNote:(NSString*)values{
    NSArray *tarr = [values componentsSeparatedByString:@","];
    for (NSString *path in tarr) {
        NSString *src = [NSString stringWithFormat:@"%@/resources/%@",srcPath,[path lastPathComponent]];
        if ([fileManager fileExistsAtPath:src] ) {
            NSError *error;
            NSString *dest = [NSString stringWithFormat:@"%@/%@",StoragePath,[path lastPathComponent]];
//            [note setResourceRef:dest];
            [fileManager copyItemAtPath:src toPath:dest error:&error];
            
        }
    }
}

-(NSString*)getFeatureIDforFeatureClass:(NSString*)featureName{
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        return [[[featureDao getFeatureTable]getPkColumn]name];
    }
    return nil;
}

-(NSMutableArray*)importFeaturesforFeatureTemplate:(DMFormTemplate*)featureTemplate forFeatureClass:(NSString*)featureName withAttribute:(NSString*)attributeName{
    NSMutableArray *retArray = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
                NSMutableArray *frmCaptArr = [[NSMutableArray alloc]init];
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                FormDefinition *form=[[FormDefinition alloc]init];
                [form setFormGuid:[featureTemplate getGUID]];
                [form setFormName:[featureTemplate getName]];
                [form setFormTemplateGuid:[featureTemplate getGUID]];
                [form setFormTemplateId:[featureTemplate getId]];
                [form setFormDefinition:[featureTemplate getFormTemplateJson]];
                [form setFormTemplateDefFromJsonString:[featureTemplate getFormTemplateJson]];
                [form setCategory:[featureTemplate getCategory]];
                NSString *noteTitle = @"";
                int index = 0;
                if ([featureRow getPkColumn]) {
                    FormCaptured *fc = [[FormCaptured alloc]init];
                    [fc setFormComponentID:index];
                    index++;
                    [fc setLabel:[[featureRow getPkColumn]name]];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]];
                    }
                    if ([attributeName isEqualToString:[[featureRow getPkColumn]name]]) {
                        noteTitle = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]];
                    }
                    [fc setLabvalue:[NSString stringWithFormat:@"%@%@%@",[fc label],repeatableLabelDelimiter,val]];
                    [fc setGroupID:-1];
                    [fc setGroupRepeatableIndex:-1];
                    [fc setIsAttachment:FALSE];
                    [frmCaptArr addObject:fc];
                }
                for (GPKGFeatureColumn *featColm in [[featureRow table]columns]) {
                    if ([featColm isGeometry] || [[featColm name]isEqualToString:[[[featureDao getFeatureTable]getPkColumn]name]]) {
                        continue;
                    }
                    if ([[featColm name]isEqualToString:@"SURVEY_DAT"]) {
                        
                    }
                    FormCaptured *fc = [[FormCaptured alloc]init];
                    [fc setFormComponentID:index];
                    [fc setLabel:[featColm name]];
                    [fc setIsAttachment:FALSE];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featColm index]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featColm index]]];
                    }
                    if ([attributeName isEqualToString:[featColm name]]) {
                        if ([featureRow getDatabaseValueWithIndex:[featColm index]]) {
                            noteTitle = [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                        }
                        if (noteTitle.length==0) {
                            noteTitle = @"Forms";
                        }
//                        noteTitle = @"Forms";
                    }
                    NSString *strCmnName = [fc label];
                    if ([strCmnName containsString:FormFeatureAudioColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureAudioColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureVideoColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureVideoColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureImageColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureImageColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureSignatureColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureSignatureColumn withString:@""];
                        [fc setIsAttachment:TRUE];
                        [self copyResourceforFormNote:val];
                    }
                    [fc setLabel:strCmnName];
                    [fc setLabvalue:[NSString stringWithFormat:@"%@%@%@",[fc label],repeatableLabelDelimiter,val]];
                    [fc setGroupID:-1];
                    [fc setGroupRepeatableIndex:-1];
                    [frmCaptArr addObject:fc];
                    index++;
                    
                }
                FormCaptureWrite *fcp = [[FormCaptureWrite alloc]init];
                [form setFormCapturedValues:[fcp writeFormdata:frmCaptArr]];
                GeoPackageDMEdgeNote *gpDMEdgeNote = [[GeoPackageDMEdgeNote alloc]init];
                [gpDMEdgeNote setEdgeForm:form];
                
                
                ED_EdgeNoteCopy *note = [[ED_EdgeNoteCopy alloc]init];
                [note setNoteType:@"forms"];
                [note setNoteTitle:noteTitle];
                NSMutableArray *coordi = [[NSMutableArray alloc]init];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                            CLLocation *loc = [[CLLocation alloc]initWithLatitude:cd.latitude longitude:cd.longitude];
                            [coordi addObject:loc];
                            [note setGeoType:@"Point"];
                            
                        }
                    }
                }
                if([[geometryData geometry]geometryType]==WKB_POLYGON){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolygon *polygon = (MKPolygon*)[shape shape];
                            int pointCount = (int)[polygon pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polygon getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setGeoType:@"Polygon"];
                            //                            
                        }
                    }
                }
                
                if([[geometryData geometry]geometryType]==WKB_LINESTRING){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolyline *polyLine = (MKPolyline*)[shape shape];
                            int pointCount = (int)[polyLine pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polyLine getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setGeoType:@"LineString"];
                        }
                    }
                }
                
                [note setCoordinates:coordi];
                [gpDMEdgeNote setEdgeNote:note];
                [retArray addObject:gpDMEdgeNote];
                
            }
        }@finally {
            [featureResults close];
            return retArray;
        }
    }
    return retArray;
}

-(void)geoPackageImportforFeatureClass:(NSString*)featureName{

    if (imported) {

        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
       
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                }
                if(geometryData != nil && !geometryData.empty){
                    WKBGeometry * geometry = geometryData.geometry;
                    if(geometry != nil){
                        GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                        CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                        
                    }
                }
            }
        }@finally {
            [featureResults close];
        }
    }
}

-(FormElement*)formElementforDatatype:(int)datatype{
    FormElement *fe = [[FormElement alloc]init];
    switch (datatype) {
        case 0:
            [fe setComponent:@"radio"];
            [fe setOptions:[[NSMutableArray alloc]initWithObjects:@"Yes",@"No",nil]];
            break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
            [fe setComponent:@"numberInput"];
            break;
        case 9:
            [fe setComponent:@"textInput"];
            break;
        case 11:
            [fe setComponent:@"textInput"];
            break;
        case 12:
            [fe setComponent:@"textInput"];
            break;
        default:
            return nil;
            break;
    }
    
    return fe;
}

-(int)getIndexforDB:(NSArray*)arr withName:(NSString*)dbName{
    int ret = -1;
    for (NSString *str in arr) {
        ret++;
        if ([str isEqualToString:dbName]) {
            break;
        }
    }
    return ret;
}
-(BOOL)isFormFeatureclass:(NSString*)featureClassName{
    GPKGFeatureDao *featureDao = [geoPackage getFeatureDaoWithTableName:featureClassName];
    for (NSString *columnName in [featureDao columns]) {
        if ([columnName isEqualToString:FeatureColumnNoteType]) {
            
            GPKGResultSet * featureResults = [featureDao queryForAll];
            @try {
                while([featureResults moveToNext]){
                    GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                    NSString *noteType = (NSString*)[featureRow getDatabaseValueWithColumnName:FeatureColumnNoteType];
                    if ([noteType isEqualToString:@"forms"]||[noteType isEqualToString:@"multi"]) {
                        return TRUE;
                    }
                }
            }@catch(NSException *exception){
                
            }@finally{
                [featureResults close];
                return FALSE;
            }
            return FALSE;
        }
    }
    return TRUE;
}

-(NSMutableArray*)importFeaturesforNonFormNotesFeatureClass:(NSString*)featureName{
    NSMutableArray *retArray = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
//                NSMutableArray *frmCaptArr = [[NSMutableArray alloc]init];
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                
                ED_EdgeNoteCopy *note = [[ED_EdgeNoteCopy alloc]init];
                [note setNoteType:@"forms"];
                NSMutableArray *coordi = [[NSMutableArray alloc]init];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                            CLLocation *loc = [[CLLocation alloc]initWithLatitude:cd.latitude longitude:cd.longitude];
                            [coordi addObject:loc];
                            [note setGeoType:@"Point"];
                            
                        }
                    }
                }
                if([[geometryData geometry]geometryType]==WKB_POLYGON){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolygon *polygon = (MKPolygon*)[shape shape];
                            int pointCount = (int)[polygon pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polygon getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setGeoType:@"Polygon"];
                            //                            
                        }
                    }
                }
                
                if([[geometryData geometry]geometryType]==WKB_LINESTRING){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolyline *polyLine = (MKPolyline*)[shape shape];
                            int pointCount = (int)[polyLine pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polyLine getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setGeoType:@"LineString"];
                        }
                    }
                }
                
                [note setCoordinates:coordi];
                [note setNoteTitle:(NSString*)[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnTitle]];
                [note setNoteType:(NSString*)[featureRow getDatabaseValueWithColumnName:FeatureColumnNoteType]];
                if ([self checkIsResourceNote:note]) {
                    NSString *src = [NSString stringWithFormat:@"%@/resources/%@",srcPath,[(NSString*)[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnResourcePath]lastPathComponent]];
                    if ([fileManager fileExistsAtPath:src] ) {
                        NSError *error;
                        NSString *dest = [NSString stringWithFormat:@"%@/%@",StoragePath,[(NSString*)[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnResourcePath]lastPathComponent]];
                        [note setResourceRef:dest];
                        [fileManager copyItemAtPath:src toPath:dest error:&error];
                        
                    }

                }
//                [gpDMEdgeNote setEdgeNote:note];
                [retArray addObject:note];
                
            }
        }@finally {
            [featureResults close];
            return retArray;
        }
    }
    return retArray;
}

-(BOOL)checkIsResourceNote:(ED_EdgeNoteCopy*)note{
    if ([[note getNoteType]isEqualToString:@"none"]) {
        return FALSE;
    }
    return TRUE;
}
@end
