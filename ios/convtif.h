//
//  convtif.h
//  PDFIUM
//
//  Created by Venkata Sudhakara Rao on 22/08/17.
//  Copyright © 2017 Venkata Sudhakara Rao. All rights reserved.
//

#ifndef convtif_h
#define convtif_h

//int convertPDFToTIFF(char *pdfFileName, char *tifFileName, char *gdalPath);
int geopdf_generateMBTilesFromGeoPDF(char *ptrScratchFolder,char *ptrFileName,char *ptrMBTileName,char *ptrGdalPath,char *ptrProgressID,char *ptrTMP, char *ptrUtid);
#endif /* convtif_h */
