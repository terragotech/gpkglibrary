package com.terragoedge.geopdf.read;
import java.lang.IllegalArgumentException;
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
        int nResult = -1;
		/* Check all the JNI parameters before invoking the JNI call */
		if( (ptr != 0) && 
		(scratchPath != null) && 
		(inputFile != null) && 
		(mbtilesFile != null) && 
		(gdalPath != null) &&
		(progressID != null) && 
		(tmpFolder != null) && 
		(utid != null) )
		{
			nResult = generateMBTiles(ptr,scratchPath,inputFile, mbtilesFile, gdalPath,progressID,tmpFolder,utid );
		}
		else
		{
			throw new IllegalArgumentException("Bad parameters passed to native call");
		}
        return nResult;
    }
    public int destroyGeoPDF(){
		int result = -1;
		/* Check all the JNI parameters before invoking the JNI call */
		if(ptr != 0)
		{
			result = destroyGeoPDF(ptr);
		}
		else
		{
			 throw new IllegalArgumentException("Null pointer passed to native call");
		}
		return result;
    }
}
