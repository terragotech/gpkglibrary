package com.terragoedge.geopdf.read;

/**
 * Created by Ganesan on 10/25/2017.
 */

public class GeoPDFEstimate {
    private long ptr;
    static {
        System.loadLibrary("estimator");
    }

    private native int createGeoPDFEstimate();
    private native int destroyGeoPDFEstimate(long ptr);
    private native  String getSupportInfo(long ptr,
                                        String inputFile,
                                        String gdalPath, String tableName,
                                        String formatType);
    public GeoPDFEstimate(){
        ptr = createGeoPDFEstimate();
        System.out.println("Pointer = " + ptr);
    }
    public String getSupportInfo(String inputFile, String gdalPath, String tableName, String formatType)
    {
        String nResult = "";
        nResult = getSupportInfo(ptr, inputFile, gdalPath,tableName,formatType );
        return nResult;
    }
    public int destroyGeoPDFEstimate(){
        return destroyGeoPDFEstimate(ptr);
    }
}