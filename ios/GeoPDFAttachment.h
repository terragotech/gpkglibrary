//
//  GeoPDFAttachment.h
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 11/03/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface GeoPDFAttachment : NSObject

-(BOOL)isPDFcontainsGeoPackage:(NSString*)filePath;
-(NSMutableArray*)getAllGeoPackagesforPDF:(NSString*)filePath;
-(NSString*)extractGeoPackagefromPDF:(NSString*)pdfPath forGeoPackage:(NSString*)geoPackageName;

@end
