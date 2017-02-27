
package com.reactlibrary;

import android.content.Context;
import android.content.SharedPreferences;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.gson.Gson;
import com.reactlibrary.enums.FormComponentType;
import com.reactlibrary.enums.NotesType;
import com.reactlibrary.json.LatLng;
import com.reactlibrary.json.Location;
import com.reactlibrary.json.Properties;
import com.reactlibrary.gpkgimport.GeoPackageRasterReader;
import com.reactlibrary.gpkgimport.PDFAttachmentExtractor;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import mil.nga.geopackage.GeoPackage;
import mil.nga.geopackage.GeoPackageManager;
import mil.nga.geopackage.core.contents.Contents;
import mil.nga.geopackage.core.contents.ContentsDao;
import mil.nga.geopackage.core.contents.ContentsDataType;
import mil.nga.geopackage.core.srs.SpatialReferenceSystem;
import mil.nga.geopackage.db.GeoPackageDataType;
import mil.nga.geopackage.factory.GeoPackageFactory;
import mil.nga.geopackage.features.columns.GeometryColumns;
import mil.nga.geopackage.features.columns.GeometryColumnsDao;
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
import mil.nga.geopackage.schema.TableColumnKey;
import mil.nga.wkb.geom.Geometry;
import mil.nga.wkb.geom.GeometryType;
import mil.nga.wkb.geom.LineString;
import mil.nga.wkb.geom.Point;
import mil.nga.wkb.geom.Polygon;

public class RNGeoPackageLibraryModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private GeoPackage geoPackage = null;
  private SpatialReferenceSystem srs = null;
  private ContentsDao contentsDao;
  private GeometryColumnsDao geomColumnsDao;
  private FeatureDao currentFeatureClassFeatureDAO;
  private FeatureTable currentFeatureTable;
  private int geomState,geomTypeFound;
  private ProjectionTransform projectionTransform = null;
  private List<String> features = new ArrayList<>();
  private FeatureDao featureDao = null;
  private FeatureCursor featureCursor = null;
  private FeatureRow featureRow = null;
  private Gson gson = new Gson();

  public RNGeoPackageLibraryModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNGeoPackageLibrary";
  }

  @ReactMethod
  public void initGeoPackageatPath(String dbPath,String dbName,Callback callback){
    try {
      srs = new SpatialReferenceSystem();
      srs.setId(4326);
      File dbFolder = new File(dbPath);
      GeoPackageManager geoPackageManager = GeoPackageFactory.getManager(reactContext);
      File dbFile = new File(dbPath+File.separator+dbName+".gpkg");
      if(dbFile.exists()){// delete db if already exist
        dbFile.delete();
      }
      geoPackageManager.createAtPath(dbName,dbFolder);// create db
      geoPackage = geoPackageManager.open(dbName);
    }catch (Exception e){
      e.printStackTrace();
    }
    callback.invoke("true");
  }

  @ReactMethod
  public void LibrarySampleCall(String testString, Callback completionCallback) {
    completionCallback.invoke(testString);
  }
  @ReactMethod
  public void createFeatureclass(ReadableMap readableMap,int geometryType,Callback callback){
    if (geoPackage != null) {
      createDefaultFeatureClass();
      List<FeatureColumn> lstFeatureColumns = new ArrayList<>();
      lstFeatureColumns.add(FeatureColumn.createPrimaryKeyColumn(0, "fid"));
      addGeometryColumn(geometryType,lstFeatureColumns);
      ReadableArray columnsArray = readableMap.getArray("Columns");
      String tableName = readableMap.getString("FeatureName");
      if(columnsArray != null){
        int size = columnsArray.size();
        for(int i=0;i<size;i++){
          ReadableMap readableMap1 = columnsArray.getMap(i);
          addField(readableMap1.getString("columnName"), lstFeatureColumns);
        }
      }
      currentFeatureTable = new FeatureTable(tableName, lstFeatureColumns);
      geoPackage.createFeatureTable(currentFeatureTable);
    }
    callback.invoke("true");
  }

  @ReactMethod
  public void insertFeatureclassRecord(ReadableMap readableMap,int geometryType,Callback callback){
    try {
      String tableName = readableMap.getString("FeatureName");
      String geometry = readableMap.getString("Location");
      insertDefaultTableValue(tableName, geometryType);
      FeatureRow featureRow = currentFeatureClassFeatureDAO.newRow();
      addGeometryValuefromJson(geometry,featureRow);
      ReadableArray columnsArray = readableMap.getArray("values");
      if(columnsArray != null){
        int size = columnsArray.size();
        for(int i=0;i<size;i++){
          ReadableMap readableMap1 = columnsArray.getMap(i);
          String fieldName = readableMap1.getString("columnName");
          String fieldValue = readableMap1.getString("columnValue");
          insertValue(fieldName, fieldValue,featureRow);
        }
      }
      currentFeatureClassFeatureDAO.create(featureRow);
    }catch (Exception e){
      e.printStackTrace();
    }
    callback.invoke("true");
  }

  @ReactMethod
  public void closeGeoPackage(Callback callback){
    if(geoPackage != null){
      geoPackage.close();
    }
    callback.invoke("true");
  }

  /**
   * To get all details from gpkg file import
   * @param filePath
   * @param callback
     */
  @ReactMethod
  public void getgpkgFileDetails(String filePath,Callback callback){
    WritableMap writableMap = Arguments.createMap();
    try{
      File file = new File(filePath);
      String fileName = file.getName();
      String extension = com.reactlibrary.FileUtils.getFileExt(fileName);
      if(extension.equals("pdf")){//if file is pdf
        WritableArray geoPackageNames = Arguments.createArray();
        PDFAttachmentExtractor.extractAttachedFiles(file.getPath(), "output target path need to give", geoPackageNames);
        PDFAttachmentExtractor.extractEmbeddedFiles(file.getPath(), "output target path need to give", geoPackageNames);
        if(geoPackageNames.size() > 0){
          writableMap = parseGeopackageFile(filePath);
        }
        writableMap.putArray("geopackageNames",geoPackageNames);
      }else if(extension.equals("gpkg")){//if file is gpkg
        writableMap = parseGeopackageFile(filePath);
      }
    }catch (Exception e){
      e.printStackTrace();
    }
    callback.invoke(writableMap);
  }

  /**
   * process geopackage and convert geopackage data to edge data
   * @param geoPackageContent
   * @param filePath
   * @param userName
     */
  @ReactMethod
  public void processGeopackage(final WritableMap geoPackageContent,final String filePath,String userName){
    openFile(filePath);
    ReadableArray featureClasses = geoPackageContent.getArray("featureClasses");
    int featureClassCount = getLayerCount();
    if(geoPackageContent.getBoolean("isRaster")){
      Thread thread = new Thread(new Runnable() {
        @Override
        public void run() {
          convertRasterFile(geoPackageContent.getString("selectedRasterLayer"), filePath);
        }
      });
      thread.start();
    }
    ReadableMap notesObject = geoPackageContent.getMap("notes");
    if(notesObject != null && notesObject.getBoolean("state")) {
      for (int i = 0; i < featureClassCount; i++) {
        int currentRow = 0;
        ReadableMap featureClass = featureClasses.getMap(i);
        if (featureClass.getBoolean("state")) {
          String tableName = selectLayerByIndex(i);
          int noteTypeColumnIndex = getNoteTypeColumnIndex();
          getSelectedLayerDefinition();
          while (hasNextFeatureInSelectedLayer()) {
            currentRow++;
            getNextRow();
            String geometry = getCurrentFeatureGeom();
            if (noteTypeColumnIndex == -1) {//create form note
              getCurrentFeatureFields(tableName, geometry, userName, geoPackageContent, currentRow, featureClass);
            } else {//create form note
              String noteType = getNoteType(noteTypeColumnIndex);
              if (noteType.equals(NotesType.forms.name()) || noteType.equals(NotesType.multiupload.name())) {
                getCurrentFeatureFields(tableName, geometry, userName, geoPackageContent, currentRow, featureClass);
              } else {//create non form notes
                createNonformNote(tableName, geometry, userName, geoPackageContent, currentRow, featureClass, noteType);
              }
            }
          }
        }

      }
    }
    closeGeoPkg();
  }

  private void createDefaultFeatureClass(){
    //Must create the gpkg_geometry_column table, as this is not created by default
    geoPackage.createGeometryColumnsTable();
    contentsDao = geoPackage.getContentsDao();
    geomColumnsDao = geoPackage.getGeometryColumnsDao();
  }

  private void addGeometryColumn(int geometryType,List<FeatureColumn> lstFeatureColumns){
    if (geometryType == 1) {
      lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.POINT, false, null));
    } else if (geometryType == 2) {
      lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.LINESTRING, false, null));
    } else if (geometryType == 3) {
      lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.POLYGON, false, null));
    }
  }

  private void addField(String fieldName,List<FeatureColumn> lstFeatureColumns) {
    int size = lstFeatureColumns.size();
    //Note:- Current implementation supports only text
    lstFeatureColumns.add(FeatureColumn.createColumn(size, fieldName, GeoPackageDataType.TEXT, false, ""));
  }

  private void insertDefaultTableValue(String currentFeatureClassName, int geometryType){
    try {
      //Create entry in the gpkg_geom_columns
      GeometryColumns currentFeatureClassGeomColums = new GeometryColumns();
      TableColumnKey id = new TableColumnKey(currentFeatureClassName, "geom");
      currentFeatureClassGeomColums.setId(id);

      currentFeatureClassGeomColums.setColumnName("geom");
      switch (geometryType) {
        case 0:
          currentFeatureClassGeomColums.setGeometryType(GeometryType.POINT);
          break;
        case 1:
          currentFeatureClassGeomColums.setGeometryType(GeometryType.LINESTRING);
          break;
        case 2:
          currentFeatureClassGeomColums.setGeometryType(GeometryType.POLYGON);
          break;
      }
      currentFeatureClassGeomColums.setSrs(srs);
      currentFeatureClassGeomColums.setM((byte) 0);
      currentFeatureClassGeomColums.setZ((byte) 0);

      Contents geomContent = new Contents();
      geomContent.setTableName(currentFeatureClassName);
      geomContent.setDataType(ContentsDataType.FEATURES);
      currentFeatureClassGeomColums.setContents(geomContent);
      geomColumnsDao.create(currentFeatureClassGeomColums);

      //Now add entry in the contents table gpkg_contents
      Contents content = new Contents();
      content.setTableName(currentFeatureClassName);
      content.setDataType(ContentsDataType.FEATURES);
      content.setIdentifier(currentFeatureClassName);
      content.setDescription("");
      //Sets the current date i.e. the last modified
      content.setLastChange(new Date());

      content.setMinX(0.0);
      content.setMinY(0.0);
      content.setMaxX(0.0);
      content.setMaxY(0.0);

      content.setSrs(srs);
      contentsDao.create(content);
      currentFeatureClassFeatureDAO = geoPackage.getFeatureDao(currentFeatureClassGeomColums);
    }catch (Exception e){
      e.printStackTrace();

    }
  }
  private void addGeometryValuefromJson(String geoJsonString,FeatureRow featureRow) {
    for (FeatureColumn column : currentFeatureTable.getColumns()) {
      if (!column.isPrimaryKey()) {
        if (!column.isGeometry()) {
          Geometry geometry = getGeometryType(geoJsonString);
          if (geometry != null) {
            long srsid = currentFeatureClassFeatureDAO.getGeometryColumns().getSrsId();
            GeoPackageGeometryData geometryData = new GeoPackageGeometryData(
                    srsid);
            geometryData.setGeometry(geometry);
            featureRow.setGeometry(geometryData);
          }
        }
      }
    }
  }

  private Geometry getGeometryType(String geoJson) {
    if (geoJson != null) {
      Gson gson = new Gson();
      Location location = gson.fromJson(geoJson, Location.class);
      if (location != null) {
        String geometryType = location.getGeometry().getType();
        switch (geometryType) {
          case "LineString":
            List<List<Double>> coOrdinates = (List) location.getGeometry().getCoordinates();
            LineString lineString = new LineString(false, false);
            Point point;
            for (List<Double> doubleList : coOrdinates) {
              point = new Point(doubleList.get(0), doubleList.get(1));
              lineString.addPoint(point);
            }
            return lineString;
          case "Point":
            List<Double> pointList = (List) location.getGeometry().getCoordinates();
            return new Point(pointList.get(1), pointList.get(0));
          case "Polygon":
            List<List<List<Double>>> polygonCoordinates = (List) location.getGeometry().getCoordinates();
            Point polygonPoint;
            Polygon polygon = new Polygon(false, false);
            for (List<Double> doubleList : polygonCoordinates.get(0)) {
              polygonPoint = new Point(doubleList.get(0), doubleList.get(1));
              LineString lineString1=new LineString(false,false);
              lineString1.addPoint(polygonPoint);
              polygon.addRing(lineString1);
            }
            return polygon;
          default:
            return null;
        }
      }
    }
    return null;
  }

  private void insertValue(String fieldName, String fieldValue,FeatureRow featureRow) throws Exception {
    boolean fieldFound = false;
    for (FeatureColumn column : currentFeatureTable.getColumns()) {
      if (!column.isPrimaryKey()) {
        if (!column.isGeometry()) {
          if (column.getName().equals(fieldName)) {
            fieldFound = true;
            featureRow.setValue(column.getName(), fieldValue);
            break;
          }
        }
      }
    }
    if (!fieldFound) {
      throw new Exception("Unknow field name");
    }
  }
  public void closeGeoPkg(){
    if(geoPackage != null) {
      geoPackage.close();
      geoPackage = null;
    }
  }

  private void openFile(String fileName){

    File geoPkgFile = new File(fileName);
    GeoPackageManager geoPackageManager = GeoPackageFactory.getManager(reactContext);

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
  private int getLayerCount(){
    int featureClassCount = 0;
    if(geoPackage != null){
      features = geoPackage.getFeatureTables();
      if(features != null){
        featureClassCount = features.size();
      }
    }
    return featureClassCount;
  }
  private String selectLayerByIndex(int layerIndex){
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
      if(i != 0 && i != featureDao.getTable().getGeometryColumnIndex()){
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

  private WritableMap parseGeopackageFile(String filePath){
    openFile(filePath);
    int featureClassCount = getLayerCount();
    int notesCount = 0;
    WritableArray featureClasses = Arguments.createArray();
    for(int i=0;i<featureClassCount;i++){
      String tableName = selectLayerByIndex(i);
      WritableMap featureClass = Arguments.createMap();
      featureClass.putString("name",tableName);
      featureClass.putBoolean("state",true);
      int currentNotesCount = getSelectedLayerFeatureCount();
      notesCount += currentNotesCount;
      featureClass.putInt("notesCount",currentNotesCount);
      featureClass.putArray("attributes",getColumnNames());
      featureClasses.pushMap(featureClass);
    }

    WritableMap geoPackageContent = Arguments.createMap();
    WritableMap notesContent = Arguments.createMap();
    notesContent.putInt("size",notesCount);
    notesContent.putBoolean("state",true);
    geoPackageContent.putMap("notes",notesContent);
    geoPackageContent.putArray("featureClasses",featureClasses);
    closeGeoPkg();
    WritableArray rasterLayers = getRasterLayers(filePath);
    geoPackageContent.putArray("rasterLayers",rasterLayers);
    if(rasterLayers.size() > 0){
      geoPackageContent.putBoolean("isRaster",true);
    }
    return geoPackageContent;
  }

  private int getNoteTypeColumnIndex(){
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

  private String getSelectedLayerDefinition(){
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
                GeoPackageDataType  geoPackageDataType = featureColumn.getDataType();
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
  private boolean hasNextFeatureInSelectedLayer(){
    return featureCursor.moveToNext();
  }
  private void getNextRow(){
    featureRow = featureCursor.getRow();
  }
  private String getCurrentFeatureGeom(){
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
  private String getNoteType(int noteTypeColumnIndex){
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

  private void convertRasterFile(String selectedLayer, String filePath) {

    GeoPackageRasterReader gr = new GeoPackageRasterReader();
    String inputGeoPackageFile = filePath;
    String inputGeoPackageFile1 = inputGeoPackageFile;
    String gdalDataPath = "";//TODO: gdal path for raster
    String tmpPath = "";//TODO: raster file output folder path
    gr.openGeoPackage(inputGeoPackageFile, gdalDataPath);
    String fileName = FileUtils.getResourceNameNoExt(filePath) + "_"+selectedLayer;
    UniqueFileNameFilter filenameFilter = new UniqueFileNameFilter(fileName+"_");
    File file = new File("");//TODO: need to give mbtile output path
    File[] files = file.listFiles(filenameFilter);
    int size = files.length;
    final String mapName = fileName+"_"+size;
    int idx = inputGeoPackageFile.lastIndexOf(".");
    final String progressFile = inputGeoPackageFile.substring(0,idx) + "_" + selectedLayer + ".txt";
    try {
      File f11 = new File(progressFile);

      if (f11.exists()) {
        f11.delete();
      }
    }catch(Exception e)
    {
      e.printStackTrace();
    }
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
                  final String sdStatus = dstatus + " %";
                  System.out.println(sdStatus);
                  ///////////////////////////////////////////////////////////////////////////////////////
                  if(dstatus >= 100.0)
                  {
                    // TODO: need to save map to db
                  }else{
                    ///////////////////////////////////////////////////////////////////////////////////////
                    //TODO: need to send progress
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
                e.printStackTrace();
              }
            }catch (Exception e)
            {
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
      gr.convertGeoPackage(inputGeoPackageFile1,"map path"+File.separator+fileName+"_"+size+".mbtiles", selectedLayer, tmpPath );
    }catch (Exception e){
      e.printStackTrace();
    }
    gr.closeGeoPackage();
  }

  private void createNonformNote(String tableName,String geometry,String userName,ReadableMap geoPackageContent,int currentRow,ReadableMap featureClass,String noteType){
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
          createGeopackageNote(geometry, geoPackageContent, currentRow,featureClass, featureRows, tableName, noteType,resourceName);//save geopackage note
        }
      }
    }
  }
  private WritableMap createGeopackageNote(String geometry,ReadableMap geoPackageContent,int currentRow,ReadableMap featureClass,HashMap<String,String> featureRows,String tableName,String noteType,String resourceName){
      WritableMap edgeNote = Arguments.createMap();
      edgeNote.putString("geometry",getGeometryDistance(geometry));
      edgeNote.putString("title",getNoteTitle(geoPackageContent, tableName, currentRow, featureClass, featureRows));
      edgeNote.putString("noteType",noteType);
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
      //TODO: need to send note to RN
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
  private String getNoteTitle(ReadableMap geoPackageContent,String tableName,int currentRow,ReadableMap featureClass,HashMap<String,String> featureRows){
    String title = "";
    String geoPackageNoteType = geoPackageContent.getString("noteType");
    switch (geoPackageNoteType){
      case "Custom name":
        title = geoPackageContent.getString("noteName")+" "+currentRow;
        break;
      case "Feature ID":
        title = String.valueOf(getFID());
        break;
      case "Default from file name":
        title = tableName+" "+currentRow;
        break;
      case "Select from file":
        for(String key : featureRows.keySet()){
          if(key.equals(featureClass.getString("selectedAtribute"))){
            title = featureRows.get(key);
          }
        }
        break;

    }
    return title;
  }

  private void getCurrentFeatureFields(String tableName, String geometry, String userName, ReadableMap geoPackageContent, int currentRow, ReadableMap featureClass){
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
                    formTemplate.putString("componentType",FormComponentType.textInput.toString());
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
                createGeopackageFormTemplate(formTemplate, idx, options, formTemplates, columnName);//save geopackage form template
                createGeoFormValues(idx, columnName, value, formValues);
                featureRows.put(columnName, value);
              }
            }
          }//end for
            WritableMap edgeFormTemplate = createEdgeFormTemplate(tableName,formTemplates);
            edgeNote = createGeopackageNote(geometry, geoPackageContent, currentRow, featureClass, featureRows, tableName, NotesType.forms.name(),"");//save geopackage note
            WritableMap form = createGeoPackageForm(formValues);//save geopackage form
          edgeNote.putMap("edgeformTemplate",edgeFormTemplate);
          edgeNote.putMap("form",form);
          //TODO: Need to send edgenote object to insert in db
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
    formValue.putString("label",columnName);
    formValue.putString("value",formValue.getString("label") + "#" + value);
    formValues.pushMap(formValue);
  }

  private WritableMap createEdgeFormTemplate(String tableName,WritableArray formTemplates){
      WritableMap edgeFormTemplate = Arguments.createMap();
      edgeFormTemplate.putString("category","GeoPackage");
      edgeFormTemplate.putString("name",tableName);
      edgeFormTemplate.putString("formComponents",gson.toJson(formTemplates));
    return edgeFormTemplate;
  }

  private WritableMap createGeoPackageForm(WritableArray formValues){
      WritableMap form = Arguments.createMap();
      form.putString("formValues",gson.toJson(formValues));
    return form;
    }
  }
