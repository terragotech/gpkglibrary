package com.terragoedge.geopdf.read;

/**
 * Created by Ganesan on 7/6/2017.
 */

public class GeoPDFReader {
      private long ptr;
    static {
        System.loadLibrary("geopdfreader");
    }

    private native int createGeoPDFReader();
    private native int destroyGeoPDF(long ptr);
    private native  int generateMBTiles(long ptr,String inputFile, String mbtilesFile, String gdalPath, String progressID, String tmpFolder );

    public GeoPDFReader(){
        ptr = createGeoPDFReader();
        System.out.println("Pointer = " + ptr);
    }
    public int generateMBTiles(String inputFile, String mbtilesFile, String gdalPath, String progressID, String tmpFolder )
    {
        int nResult = 0;
        nResult = generateMBTiles(ptr,inputFile, mbtilesFile, gdalPath,progressID,tmpFolder );
        return nResult;
    }
    public int destroyGeoPDF(){
        return destroyGeoPDF(ptr);
    }
}
