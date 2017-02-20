//
//  GeoPackageColumn.h
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 23/03/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeoPackageColumn : NSObject

@property(nonatomic, assign)int formelementID;
@property(nonatomic, retain)NSString *columnName;
@property(nonatomic, retain)NSString *columnComponent;

@end
