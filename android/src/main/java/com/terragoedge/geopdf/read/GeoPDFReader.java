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
    private native  int generateMBTiles(long ptr,String scratchPath,
                                        String inputFile, String mbtilesFile,
                                        String gdalPath, String progressID,
                                        String tmpFolder, String utid );

    public GeoPDFReader(){
        ptr = createGeoPDFReader();
        System.out.println("Pointer = " + ptr);
    }
    public int generateMBTiles(String scratchPath, String inputFile, String mbtilesFile, String gdalPath, String progressID, String tmpFolder, String utid )
    {
        int nResult = 0;
        nResult = generateMBTiles(ptr,scratchPath,inputFile, mbtilesFile, gdalPath,progressID,tmpFolder,utid );
        return nResult;
    }
    public int destroyGeoPDF(){
        return destroyGeoPDF(ptr);
    }
}
