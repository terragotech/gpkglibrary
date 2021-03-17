package com.terragoedge.geopdf.read;

public class GeoPDFReader64 {

    static {
        System.loadLibrary("geopdfreader64");
    }

    //private native int createGeoPDFReader();
    //private native int destroyGeoPDF(long ptr);
    private native  long generateMBTiles(String scratchPath,
                                        String inputFile, String mbtilesFile,
                                        String gdalPath, String progressID,
                                        String tmpFolder, String utid );

    public GeoPDFReader64(){
        //ptr = createGeoPDFReader();
        //System.out.println("Pointer = " + ptr);
    }
    public long generateMBTilesW(String scratchPath, String inputFile, String mbtilesFile, String gdalPath, String progressID, String tmpFolder, String utid )
    {
        long nResult = 0;
        nResult = generateMBTiles(scratchPath,inputFile, mbtilesFile, gdalPath,progressID,tmpFolder,utid );
        return nResult;
    }
    /*public int destroyGeoPDF(){
        return destroyGeoPDF(ptr);
    }*/

}
