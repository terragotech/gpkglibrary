package com.reactlibrary.gpkgimport;

import android.content.Context;
import android.os.Environment;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.gson.Gson;
import com.reactlibrary.RNGeoPackageLibraryModule;
import com.reactlibrary.enums.FormComponentType;
import com.reactlibrary.enums.NotesType;
import com.reactlibrary.json.LatLng;
import com.reactlibrary.json.Location;
import com.reactlibrary.json.Properties;
import com.reactlibrary.utils.FileUtils;
import com.reactlibrary.utils.GeoPackageUtil;
import com.reactlibrary.utils.Utils;
import com.terragoedge.geopkg.read.GeoPackageRasterReader;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import mil.nga.geopackage.GeoPackage;
import mil.nga.geopackage.GeoPackageManager;
import mil.nga.geopackage.db.GeoPackageDataType;
import mil.nga.geopackage.factory.GeoPackageFactory;
import mil.nga.geopackage.features.user.FeatureColumn;
import mil.nga.geopackage.features.user.FeatureCursor;
import mil.nga.geopackage.features.user.FeatureDao;
import mil.nga.geopackage.features.user.FeatureRow;
import mil.nga.geopackage.features.user.FeatureTable;
import mil.nga.geopackage.geom.GeoPackageGeometryData;
import mil.nga.geopackage.projection.Projection;
import mil.nga.geopackage.projection.ProjectionConstants;
import mil.nga.geopackage.projection.ProjectionFactory;
import mil.nga.geopackage.projection.ProjectionTransform;
import mil.nga.wkb.geom.Geometry;

public class GpkgImportService {
    private Context context = null;
    private GeoPackage geoPackage = null;
    private List<String> features = new ArrayList<>();
    private FeatureDao featureDao = null;
    private FeatureCursor featureCursor = null;
    private FeatureRow featureRow = null;
    private int geomState,geomTypeFound;
    private ProjectionTransform projectionTransform = null;
    private Gson gson = new Gson();

    public GpkgImportService(Context context) {
        this.context = context;
    }

    public void openFile(String fileName){
        File geoPkgFile = new File(fileName);
        GeoPackageManager geoPackageManager = GeoPackageFactory.getManager(context);
        try{
            // Import database
            if(!geoPackageManager.exists(fileName)){
                geoPackageManager.importGeoPackage(geoPkgFile,true);
            }
        }catch (Exception e){
            e.printStackTrace();
        }
        // Available databases
        List<String> databases = geoPackageManager.databases();
        int index = databases.indexOf(FileUtils.getResourceNameNoExt(fileName));
        if(index != -1){
            geoPackage = geoPackageManager.open(databases.get(index));
        }
    }

    /**
     * get feature tables count
     * @return
     */
    public int getLayerCount(){
        int featureClassCount = 0;
        if(geoPackage != null){
            features = geoPackage.getFeatureTables();
            if(features != null){
                featureClassCount = features.size();
            }
        }
        return featureClassCount;
    }
    public String selectLayerByIndex(int layerIndex){
        String tableName = "";
        if(features != null && geoPackage != null){
            //As the layer selected make sure the Dao object is created
            //So all other method can access the data via dao
            featureDao = geoPackage.getFeatureDao(features.get(layerIndex));
            featureCursor = featureDao.queryForAll();
            tableName = featureCursor.getTable().getTableName();
            //Get the status of the Projection
            geomState = GeoPackageUtil.getProjStatus(featureDao);

            geomTypeFound = GeoPackageUtil.getGeomType(featureDao.getGeometryType());
            //If required generate the projection transformation object, so it can
            //be used when processing the Geometry objects

            if(geomState == GeoPackageUtil.PROJ_STATUS_RE_PROJ_REQUIRED){
                //Generate Projection Objection  once
                Projection prj4326 = ProjectionFactory.getProjection(ProjectionConstants.EPSG_WORLD_GEODETIC_SYSTEM);
                Projection projection = featureDao.getProjection();
                projectionTransform = projection.getTransformation(prj4326);
            }
        }
        return tableName;
    }

    private WritableArray getColumnNames(){
        String[] columns = featureDao.getTable().getColumnNames();
        WritableArray writableArray = Arguments.createArray();
        int size = columns.length;
        for(int i=0;i<size;i++){
            if(i != featureDao.getTable().getGeometryColumnIndex()){
                writableArray.pushString(columns[i]);
            }
        }
        return writableArray;
    }
    private int getSelectedLayerFeatureCount(){
        int featureCount;
        featureCount = featureDao.count();
        return featureCount;
    }

    private WritableArray getRasterLayers(String rasterFilePath){
        WritableArray writableArray = Arguments.createArray();
        GeoPackageRasterReader gr = new GeoPackageRasterReader();
        String gdalDataPath = "file:///android_asset/";
        gr.openGeoPackage(rasterFilePath, gdalDataPath);
        String rasterNameList =  gr.getGeoPackageRasterNameListAsJSON();
        try{
            JSONObject obj = new JSONObject(rasterNameList);
            JSONArray arrayJS = obj.getJSONArray("tile_sources");
            int rasterLength = arrayJS.length();
            for(int i=0;i<rasterLength;i++)
            {
                JSONObject obj1 = arrayJS.getJSONObject(i);
                writableArray.pushString(obj1.getString("tilename"));
            }
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
        gr.closeGeoPackage();
        return writableArray;
    }

    public WritableMap parseGeopackageFile(String filePath){
        openFile(filePath);
        int featureClassCount = getLayerCount();
        int notesCount = 0;
        WritableArray featureClasses = Arguments.createArray();
        for(int i=0;i<featureClassCount;i++){
            String tableName = selectLayerByIndex(i);
            WritableMap featureClass = Arguments.createMap();
            featureClass.putString("name",tableName);
            featureClass.putString("guid", Utils.randomUUID());
            int currentNotesCount = getSelectedLayerFeatureCount();
            notesCount += currentNotesCount;
            featureClass.putInt("notesCount",currentNotesCount);
            featureClass.putArray("attributes",getColumnNames());
            featureClasses.pushMap(featureClass);
        }

        WritableMap geoPackageContent = Arguments.createMap();
        geoPackageContent.putArray("featureClasses",featureClasses);
        geoPackageContent.putString("gpkgName", FileUtils.getResourceNameNoExt(filePath));
        closeGeoPkg();
        WritableArray rasterLayers = getRasterLayers(filePath);
        boolean isRaster = false;
        if(rasterLayers.size() > 0) {
            isRaster = true;
            geoPackageContent.putArray("rasterLayers", rasterLayers);
        }
        geoPackageContent.putBoolean("isRaster",isRaster);
        return geoPackageContent;
    }

    public int getNoteTypeColumnIndex(){
        String[] columnNames = featureDao.getTable().getColumnNames();
        int size = columnNames.length;
        for(int i=0;i<size;i++){
            String columnName = columnNames[i];
            if(columnName.equalsIgnoreCase("Note_Type")){
                return  i;
            }
        }
        return -1;
    }

    public String getSelectedLayerDefinition(){
        String layerDef;
        String []fieldnames = featureDao.getTable().getColumnNames();
        layerDef = getColumnWithType(fieldnames);
        return layerDef;
    }

    private String getColumnWithType(String []fieldnames){
        String result = null;
        if(fieldnames != null)
        {
            int fieldCount = fieldnames.length;
            if(fieldCount > 0){
                StringBuilder bufferLayerDef = new StringBuilder();
                int geomFieldIndex = -1;

                bufferLayerDef.append("[");
                FeatureTable featureTable = featureDao.getTable();

                if(featureTable != null){
                    geomFieldIndex = featureTable.getGeometryColumnIndex();
                    int afieldCount = fieldCount - 2;
                    int jdx = 0;
                    for(int idx=0;idx < fieldCount; idx++){
                        if((geomFieldIndex != idx) && (idx != 0)){
                            FeatureColumn featureColumn = featureTable.getColumn(idx);
                            if(featureColumn != null){
                                String columnName = featureColumn.getName();
                                GeoPackageDataType geoPackageDataType = featureColumn.getDataType();
                                String columnTypeName = getColumnTypeAsString(geoPackageDataType);
                                bufferLayerDef.append("{");
                                bufferLayerDef.append("\"name\":");
                                bufferLayerDef.append("\"");
                                bufferLayerDef.append(columnName);
                                bufferLayerDef.append("\"");

                                bufferLayerDef.append(",");
                                bufferLayerDef.append("\"type\":");
                                bufferLayerDef.append("\"");
                                bufferLayerDef.append(columnTypeName);
                                bufferLayerDef.append("\"");

                                bufferLayerDef.append(",");
                                bufferLayerDef.append("\"width\":");
                                bufferLayerDef.append("\"");
                                bufferLayerDef.append("0");
                                bufferLayerDef.append("\"");

                                bufferLayerDef.append(",");
                                bufferLayerDef.append("\"precision\":");
                                bufferLayerDef.append("\"");
                                bufferLayerDef.append("0.0");
                                bufferLayerDef.append("\"");
                                bufferLayerDef.append("}");
                                if((jdx != (afieldCount - 1)) && ((afieldCount - 1) > 0))
                                {
                                    bufferLayerDef.append(",");
                                }
                                jdx++;
                            }
                        }
                    }//end for
                }//end table
                bufferLayerDef.append("]");
                result = bufferLayerDef.toString();
            }
        }
        return result;
    }

    private String getColumnTypeAsString(GeoPackageDataType  geoPackageDataType){
        String result = "";
        if(geoPackageDataType == GeoPackageDataType.BLOB)
        {
            result = "BLOB";
        }
        if(geoPackageDataType == GeoPackageDataType.BOOLEAN)
        {
            result = "BOOLEAN";
        }
        if(geoPackageDataType == GeoPackageDataType.DATE)
        {
            result = "DATE";
        }
        if(geoPackageDataType == GeoPackageDataType.DATETIME)
        {
            result = "DATETIME";
        }
        if(geoPackageDataType == GeoPackageDataType.DOUBLE)
        {
            result = "DOUBLE";
        }
        if(geoPackageDataType == GeoPackageDataType.FLOAT)
        {
            result = "FLOAT";
        }
        if(geoPackageDataType == GeoPackageDataType.INT)
        {
            result = "INT";
        }
        if(geoPackageDataType == GeoPackageDataType.INTEGER)
        {
            result = "INTEGER";
        }
        if(geoPackageDataType == GeoPackageDataType.MEDIUMINT)
        {
            result = "MEDIUMINT";
        }
        if(geoPackageDataType == GeoPackageDataType.REAL)
        {
            result = "REAL";
        }
        if(geoPackageDataType == GeoPackageDataType.SMALLINT)
        {
            result = "SMALLINT";
        }
        if(geoPackageDataType == GeoPackageDataType.TEXT)
        {
            result = "TEXT";
        }
        if(geoPackageDataType == GeoPackageDataType.TINYINT)
        {
            result = "TINYINT";
        }
        return result;
    }
    public boolean hasNextFeatureInSelectedLayer(){
        return featureCursor.moveToNext();
    }
    public void getNextRow(){
        featureRow = featureCursor.getRow();
    }
    public String getCurrentFeatureGeom(){
        String geoJSON = null;
        if(geomTypeFound == GeoPackageUtil.GEOM_TYPE_POINT ||
                geomTypeFound == GeoPackageUtil.GEOM_TYPE_LINESTRING ||
                geomTypeFound == GeoPackageUtil.GEOM_TYPE_POLYGON ||
                geomTypeFound == GeoPackageUtil.GEOM_TYPE_MULTILINESTRING ||
                geomTypeFound == GeoPackageUtil.GEOM_TYPE_MULTIPOLYGON)
        {
            GeoPackageGeometryData geometryData = featureRow.getGeometry();
            if(geometryData != null) {
                Geometry geometry = geometryData.getGeometry();
                if (geomState == GeoPackageUtil.PROJ_STATUS_RE_PROJ_REQUIRED) {
                    geometry = projectionTransform.transform(geometry);
                } else if (geomState != GeoPackageUtil.PROJ_STATUS_WGS_84) {
                    geometry = null;
                }

                geoJSON = GeoPackageUtil.exportGeomTogeoJSON(geometry);
            }
        }
        return geoJSON;
    }
    public String getNoteType(int noteTypeColumnIndex){
        String noteType = featureCursor.getString(noteTypeColumnIndex);
        switch (noteType){
            case "none":
                return NotesType.none.name();
            case "image":
                return NotesType.image.name();
            case "audio":
                return NotesType.audio.name();
            case "video":
                return NotesType.video.name();
            case "attachment":
                return NotesType.attachment.name();
            case "file":
                return NotesType.file.name();
            case "forms":
                return NotesType.forms.name();
            case "multiupload":
                return NotesType.multiupload.name();
        }
        return null;
    }

    public void convertRasterFile(final String selectedLayer, String filePath, Context context, final String notebookGuid) {

        GeoPackageRasterReader gr = new GeoPackageRasterReader();
        String inputGeoPackageFile = filePath;
        String inputGeoPackageFile1 = inputGeoPackageFile;
        String gdalDataPath = context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS)+File.separator+Utils.RASTER_SUPPORTED_FILE_PATH;
        String tmpPath = context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS)+File.separator+Utils.RASTER_MBTILE_PATH;
        File tmpFile = new File(tmpPath);
        tmpFile.mkdirs();
        gr.openGeoPackage(inputGeoPackageFile, gdalDataPath);
        final String fileName = FileUtils.getResourceNameNoExt(filePath) + "_"+selectedLayer;
        com.reactlibrary.UniqueFileNameFilter filenameFilter = new com.reactlibrary.UniqueFileNameFilter(fileName+"_");
        final String convertedPath = context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS)+File.separator+"rasterOutput";
        final File file = new File(convertedPath);
        file.mkdirs();
        System.out.println("terrago check"+file.canWrite());
        File[] files = file.listFiles(filenameFilter);
        final int size = files.length;
        int idx = inputGeoPackageFile.lastIndexOf(".");
        final String progressFile = inputGeoPackageFile.substring(0,idx) + "_" + selectedLayer + ".txt";
        try {
            File f11 = new File(progressFile);
            if (f11.exists()) {
                f11.delete();
            }
        }catch(Exception e)
        {
            System.out.println("terrago progress file error");
            e.printStackTrace();
        }
        System.out.println("terrago progress file created");
        Thread thread = new Thread(new Runnable() {
            @Override
            public void run() {
                File f1  = new File(progressFile);
                boolean blnStopFlag = false;
                while(!blnStopFlag)
                {
                    if(f1.exists())
                    {
                        try {
                            String str ="";
                            BufferedReader br = new BufferedReader(new FileReader(f1));
                            while((str=br.readLine())!=null && str.length()!=0)
                            {
                                System.out.println("raster progress file reading"+str);
                                int idx = str.indexOf("-");
                                String status = str.substring(0,idx);
                                if(status.equals("PROGRESS"))
                                {
                                    int sidx = idx + 1;
                                    int eidx = str.lastIndexOf("#");
                                    String status1 = str.substring(sidx, eidx);
                                    //System.out.println(status1);
                                    double dstatus = Double.parseDouble(status1) * 100;
                                    ///////////////////////////////////////////////////////////////////////////////////////
                                    if(dstatus >= 100.0)
                                    {
                                        System.out.println("terrago successs raster file");
                                        WritableMap writableMap1 = Arguments.createMap();
                                        writableMap1.putString("notebookGuid",notebookGuid);
                                        writableMap1.putString("importGuid",RNGeoPackageLibraryModule.importGuid);
                                        writableMap1.putString("convertedPath", convertedPath+File.separator+fileName+"_"+size+".mbtiles");
                                        writableMap1.putString("rasterName", selectedLayer);
                                        Utils.sendEvent(RNGeoPackageLibraryModule.reactContext,Utils.SEND_RASTER_PROGRESS_EVENT,"0");
                                        Utils.sendEvent(RNGeoPackageLibraryModule.reactContext,Utils.SEND_RASTER_EVENT,writableMap1);
                                        blnStopFlag = true;
                                    }else{
                                        ///////////////////////////////////////////////////////////////////////////////////////
                                        //TODO: need to send progress
                                        Utils.sendEvent(RNGeoPackageLibraryModule.reactContext,Utils.SEND_RASTER_PROGRESS_EVENT,String.valueOf((int) dstatus));
                                    }
                                }
                                else
                                {//error
                                    blnStopFlag = true;
                                    //TODO: need to send error
                                }
                            }
                            if(br != null)
                            {
                                br.close();
                            }
                            try {
                                Thread.sleep(5000);
                            }catch (Exception e){
                                System.out.println("terrago progress file error while getting progress");
                                e.printStackTrace();
                            }
                        }catch (Exception e)
                        {
                            System.out.println("terrago progress file error interrupt");
                            e.printStackTrace();
                            blnStopFlag = true;
                        }

                    }
                    else
                    {
                        try {
                            Thread.sleep(1000);
                        }catch (Exception e){
                            e.printStackTrace();
                        }
                    }
                }
            }
        });
        thread.start();
        System.out.println("Input file :" + inputGeoPackageFile1);
        try {
            System.out.println("terrago raster file conversion started");
            gr.convertGeoPackage(inputGeoPackageFile1,convertedPath+File.separator+fileName+"_"+size+".mbtiles", selectedLayer, tmpPath );
        }catch (Exception e){
            System.out.println("terrago raster file creattion error");
            e.printStackTrace();
        }
        gr.closeGeoPackage();
    }

    public void createNonformNote(String geometry, ReadableMap featureClass, String noteType,String notebookGuid){
        if(featureRow != null){
            String []fieldNames = featureRow.getColumnNames();
            String resourceName = "";
            if(fieldNames != null){
                int fieldCount = fieldNames.length;
                if(fieldCount > 0 ){
                    int geomFieldIdx = featureRow.getGeometryColumnIndex();
                    HashMap<String,String> featureRows = new HashMap<>();
                    for(int idx=0;idx < fieldCount; idx++){
                        if((idx != 0) && (idx != geomFieldIdx)){
                            String columnName = featureRow.getColumnName(idx);
                            if(columnName.equals("Resource_Path") || columnName.equals("ResourceRef")){
                                resourceName = featureCursor.getString(idx);
                            }
                            String value = null;
                            List<String> options  = new ArrayList<>(2);
                            String dataType = getColumnTypeAsString(featureRow.getColumn(idx).getDataType());

                            switch (dataType) {
                                case "TEXT":
                                    value = featureCursor.getString(idx);
                                    break;
                                case "TINYINT":
                                    value = Integer.toString(featureCursor.getInt(idx));
                                    break;
                                case "SMALLINT":
                                    value = Integer.toString(featureCursor.getInt(idx));
                                    break;
                                case "REAL":
                                    value = Float.toString(featureCursor.getFloat(idx));
                                    break;
                                case "MEDIUMINT":
                                    value = Integer.toString(featureCursor.getInt(idx));
                                    break;
                                case "INTEGER":
                                    value = Integer.toString(featureCursor.getInt(idx));
                                    break;
                                case "INT":
                                    value = Integer.toString(featureCursor.getInt(idx));
                                    break;
                                case "FLOAT":
                                    value = Float.toString(featureCursor.getFloat(idx));
                                    break;
                                case "DOUBLE":
                                    value = Double.toString(featureCursor.getDouble(idx));
                                    break;
                                case "DATETIME":
                                    value = Long.toString(featureCursor.getLong(idx));
                                    break;
                                case "DATE":
                                    value = Long.toString(featureCursor.getLong(idx));
                                    break;
                                case "BOOLEAN":
                                    options.add("yes");
                                    options.add("no");
                                    value = Integer.toString(featureCursor.getInt(idx));
                                    break;
                            }
                            featureRows.put(columnName, value);
                        }

                    }//end for
                    WritableMap writableMap = createGeopackageNote(geometry, featureClass, featureRows, noteType,resourceName);//save geopackage note
                    writableMap.putString("formTemplateGuid",featureClass.getString("guid"));
                    writableMap.putString("importGuid",RNGeoPackageLibraryModule.importGuid);
                    writableMap.putString("notebookGuid",notebookGuid);
                    WritableMap noteMap = Arguments.createMap();
                    noteMap.putMap("note",writableMap);
                    Utils.sendEvent(RNGeoPackageLibraryModule.reactContext,Utils.SEND_NOTE_EVENT,noteMap);

                }
            }
        }
    }
    private WritableMap createGeopackageNote(String geometry,ReadableMap featureClass,HashMap<String,String> featureRows,String noteType,String resourceName){
        WritableMap edgeNote = Arguments.createMap();
        edgeNote.putString("geometry",getGeometryDistance(geometry));
        edgeNote.putString("title",getNoteTitle(featureClass, featureRows));
        edgeNote.putString("noteType",noteType);
        edgeNote.putString("formGuid",Utils.randomUUID());
        //get resource file from geofiles foler
        File file = FileUtils.getFileFromFolder(new File("geoFilePath"),resourceName);
        if (file != null) {
            try {//copy resource file to resource path
                File resourceFile = FileUtils.writeFileInputStream(new FileInputStream(file), new File("resourcepath"));
                if(resourceFile != null) {
                    edgeNote.putString("resourcePath", resourceFile.getAbsolutePath());
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return edgeNote;
    }
    private String getGeometryDistance(String geometry){
        if(geometry != null && !geometry.equals("null")) {//get geomentry distance while saving geopackage note
            try {
                Location geometryLocation = gson.fromJson(geometry, Location.class);
                Properties properties = new Properties();
                com.reactlibrary.json.Geometry geometry1 = geometryLocation.getGeometry();
                String type = geometry1.getType();
                List<String> distances = properties.getDistance();
                if((type.equals("LineString") || type.equals("Polygon")) && distances.size() == 0){
                    boolean isPolygon = type.equals("Polygon");
                    List<LatLng> latLngs = new ArrayList<>();
                    List coOrdinates = (List) geometry1.getCoordinates();
                    if(isPolygon){
                        List polygonObj = (List) coOrdinates.get(0);
                        latLngs.addAll(FileUtils.getLatlngListFromObj(polygonObj));

                    }else{
                        latLngs.addAll(FileUtils.getLatlngListFromObj(coOrdinates));
                    }
                    double totalDistance = FileUtils.getDistanceList(latLngs, properties);
                    FileUtils.calculateArea(isPolygon, properties, totalDistance, latLngs);
                    geometryLocation.setProperties(properties);
                    geometry = gson.toJson(geometryLocation);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return geometry;
    }
    private long getFID(){
        return featureRow.getId();
    }
    private String getNoteTitle(ReadableMap featureClass,HashMap<String,String> featureRows){
        String title = "";
        String attributeName = featureClass.hasKey("attributeName") ? featureClass.getString("attributeName") : null;
        String defaultName = featureClass.hasKey("defaultName") ? featureClass.getString("defaultName") : null;
        if(defaultName != null){
            title = defaultName;
        }else if(attributeName != null){
            for(String key : featureRows.keySet()){
                if(key.equals(featureClass.getString("attributeName"))){
                    title = featureRows.get(key);
                    if(title == null || title.equals("")) {
                    title = "Forms";
                    }
                }
            }
        }
        return title;
    }

    public void getCurrentFeatureFields(String tableName, String geometry,ReadableMap featureClass,String notebookGuid){
        WritableMap edgeNote = Arguments.createMap();
        if(featureRow != null){
            String []fieldNames = featureRow.getColumnNames();
            if(fieldNames != null){
                int fieldCount = fieldNames.length;
                if(fieldCount > 0 ){
                    WritableArray formTemplates = Arguments.createArray();
                    WritableArray formValues = Arguments.createArray();
                    int geomFieldIdx = featureRow.getGeometryColumnIndex();
                    HashMap<String,String> featureRows = new HashMap<>();
                    for(int idx=0;idx < fieldCount; idx++){
                        if((idx != 0) && (idx != geomFieldIdx)){
                            WritableMap formTemplate = Arguments.createMap();
                            String columnName = featureRow.getColumnName(idx);
                            if(columnName.equals("TGT_Image_Column_") || columnName.equals("TGT_Video_Column_") || columnName.equals("TGT_Audio_Column_") || columnName.equals("TGT_Signature_Column_")){
                                String resourceValue = featureCursor.getString(idx);
                                String[] resourceNames = resourceValue.split(",");
                                for(String resourceName : resourceNames){
                                    File file = FileUtils.getFileFromFolder(new File("input resource path"),resourceName);
                                    if(file != null){
                                        try{
                                            FileUtils.writeFileInputStream(new FileInputStream(file),new File("resuorcepath"));
                                        }catch (Exception e){
                                            e.printStackTrace();
                                        }
                                    }
                                }

                            }else{
                                String value = null;
                                WritableArray options  = Arguments.createArray();
                                String dataType = getColumnTypeAsString(featureRow.getColumn(idx).getDataType());

                                switch (dataType) {
                                    case "TEXT":
                                        formTemplate.putString("componentType", FormComponentType.textInput.toString());
                                        value = featureCursor.getString(idx);
                                        break;
                                    case "TINYINT":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Integer.toString(featureCursor.getInt(idx));
                                        break;
                                    case "SMALLINT":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Integer.toString(featureCursor.getInt(idx));
                                        break;
                                    case "REAL":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Float.toString(featureCursor.getFloat(idx));
                                        break;
                                    case "MEDIUMINT":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Integer.toString(featureCursor.getInt(idx));
                                        break;
                                    case "INTEGER":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Integer.toString(featureCursor.getInt(idx));
                                        break;
                                    case "INT":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Integer.toString(featureCursor.getInt(idx));
                                        break;
                                    case "FLOAT":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Float.toString(featureCursor.getFloat(idx));
                                        break;
                                    case "DOUBLE":
                                        formTemplate.putString("componentType",FormComponentType.numberInput.toString());
                                        value = Double.toString(featureCursor.getDouble(idx));
                                        break;
                                    case "DATETIME":
                                        formTemplate.putString("componentType",FormComponentType.time.toString());
                                        value = Long.toString(featureCursor.getLong(idx));
                                        break;
                                    case "DATE":
                                        formTemplate.putString("componentType",FormComponentType.date.toString());
                                        value = Long.toString(featureCursor.getLong(idx));
                                        break;
                                    case "BOOLEAN":
                                        options.pushString("yes");
                                        options.pushString("no");
                                        formTemplate.putString("componentType",FormComponentType.radio.toString());
                                        value = Integer.toString(featureCursor.getInt(idx));
                                        break;
                                }
                                System.out.println("form value" + value);
                                System.out.println("form components"+ formTemplates);
                                createGeopackageFormTemplate(formTemplate, idx, options, formTemplates, columnName);//save geopackage form template
                                createGeoFormValues(idx, columnName, value, formValues);
                                featureRows.put(columnName, value);
                            }
                        }
                    }//end for
                    WritableMap edgeFormTemplate = createEdgeFormTemplate(tableName,formTemplates);
                    edgeNote = createGeopackageNote(geometry, featureClass, featureRows, NotesType.forms.name(),"");//save geopackage note
                    edgeNote.putMap("edgeformTemplate",edgeFormTemplate);
                    edgeNote.putArray("formValues",formValues);
                    edgeNote.putString("formTemplateGuid",featureClass.getString("guid"));
                    edgeNote.putString("importGuid",RNGeoPackageLibraryModule.importGuid);
                    edgeNote.putString("notebookGuid",notebookGuid);
                    WritableMap noteMap = Arguments.createMap();
                    noteMap.putMap("note",edgeNote);
                    Utils.sendEvent(RNGeoPackageLibraryModule.reactContext,Utils.SEND_NOTE_EVENT,noteMap);
                }
            }
        }
    }

    private void createGeopackageFormTemplate(WritableMap formTemplate,int idx,WritableArray options,WritableArray formTemplates,String columnName){
        formTemplate.putInt("id",idx);
        formTemplate.putBoolean("isEditable",true);
        formTemplate.putInt("index",idx);
        formTemplate.putString("label",columnName);
        formTemplate.putString("description","");
        formTemplate.putString("placeHolder","");
        formTemplate.putBoolean("isRequired",false);
        formTemplate.putBoolean("isRepeatable",false);
        formTemplate.putString("validation","");
        formTemplate.putString("currency","");
        formTemplate.putArray("options",options);
        WritableMap occurences = Arguments.createMap();
        occurences.putInt("max",1);
        occurences.putInt("min",1);
        formTemplate.putMap("occurences",occurences);
        formTemplates.pushMap(formTemplate);
    }
    private void createGeoFormValues(int idx,String columnName,String value,WritableArray formValues){
        WritableMap formValue = Arguments.createMap();
        formValue.putInt("id",idx);
        formValue.putInt("index",idx);
        formValue.putString("label",columnName);
        formValue.putBoolean("isAttachment",false);
        formValue.putString("value",formValue.getString("label") + "#" + value);
        formValues.pushMap(formValue);
    }

    private WritableMap createEdgeFormTemplate(String tableName,WritableArray formTemplates){
        WritableMap edgeFormTemplate = Arguments.createMap();
        edgeFormTemplate.putString("name",tableName);
        edgeFormTemplate.putArray("formComponents",formTemplates);
        return edgeFormTemplate;
    }

    private WritableMap createGeoPackageForm(WritableArray formValues){
        WritableMap form = Arguments.createMap();
        form.putString("formValues",gson.toJson(formValues));
        return form;
    }

    public void closeGeoPkg(){
        if(geoPackage != null) {
            geoPackage.close();
            geoPackage = null;
        }
    }
}