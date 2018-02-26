//
//  GPKGConstant.h
//  RNGeoPackageLibrary
//
//  Created by Sunilkarthick Sivabalan on 27/02/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#ifndef GPKGConstant_h
#define GPKGConstant_h

#define GPKGStoragePath [NSString stringWithFormat:@"%@/Data", [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0]]
#define GPKGResourcePath [NSString stringWithFormat:@"%@/resources", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]]


#define repeatableDelimiter @"*|#*"
#define repeatableLabelDelimiter @"#"

#define NonFormFeatureColumnTitle @"Title"
#define FeatureColumnNoteType @"Note_Type"
#define NonFormFeatureColumnResourcePath @"Resource_Path"
#define FormFeatureImageColumn @"TGT_Image_Column_"
#define FormFeatureVideoColumn @"TGT_Video_Column_"
#define FormFeatureAudioColumn @"TGT_Audio_Column_"
#define FormFeatureSignatureColumn @"TGT_Signature_Column_"

#endif /* GPKGConstant_h */
