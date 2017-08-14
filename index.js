
//import { NativeModules } from 'react-native';
var React = require('react-native')
var { DeviceEventEmitter, NativeAppEventEmitter, Platform } = React
//const { RNGeoPackageLibrary } = NativeModules;
var RNGeoPackageLibraryNATIVE = React.NativeModules.RNGeoPackageLibrary

var _libsample = RNGeoPackageLibraryNATIVE.LibrarySampleCall;
var _initGeoPackage = RNGeoPackageLibraryNATIVE.initGeoPackageatPath;
var _createFeatureClass = RNGeoPackageLibraryNATIVE.createFeatureclass;
var _insertFeatureRecord = RNGeoPackageLibraryNATIVE.insertFeatureclassRecord;
var _closeGeoPackage = RNGeoPackageLibraryNATIVE.closeGeoPackage;
var _cancelImport = RNGeoPackageLibraryNATIVE.cancelImport;
var _processGeoPDFMbtile = RNGeoPackageLibraryNATIVE.processGeoPDFMbtile;

//import
//var _initImport = RNGeoPackageLibrary.initImportGeoPackageforPath;
var _getgpkgFileDetails = RNGeoPackageLibraryNATIVE.getgpkgFileDetails
var _importGeoPackage = RNGeoPackageLibraryNATIVE.importGeoPackage

var RNGeoPackageLibrary = {
  LibrarySampleCall(testString,callback) {
    return _libsample(testString,callback)
      .catch(_error)
  },
  initGeoPackageatPath(directoryPath,fileName){
    return _initGeoPackage(directoryPath,fileName)
  },
  createFeatureclass(featureDict,geomentry){
    return _createFeatureClass(featureDict,geomentry)
  },
  cancelImport(importID){
    return _cancelImport(importID)
  },
  insertFeatureclassRecord(featureRecordDict,geomentry){
    return _insertFeatureRecord(featureRecordDict,geomentry)
  },
  closeGeoPackage(){
    return _closeGeoPackage()
  },
  initImportGeoPackageforPath(path, callback){
    return _initImport(path, callback)
      .catch(_error)
  },
  processGeoPDFMbtile(pdfFilePath, mbtilePath, tempFolder, progressGuid){
      return _processGeoPDFMbtile(pdfFilePath, mbtilePath, tempFolder, progressGuid)
    },
  getgpkgFileDetails(path){
    return _getgpkgFileDetails(path)
  },
  importGeoPackage(gpkgargument){
  	 return _importGeoPackage(gpkgargument)
  },
  subscribenoteImported(notecallback) {
    var emitter = Platform.OS == 'ios' ? NativeAppEventEmitter : DeviceEventEmitter;
    return emitter.addListener("noteImported", notecallback);
  },
  subscribeRasterImported(callback) {
    var emitter = Platform.OS == 'ios' ? NativeAppEventEmitter : DeviceEventEmitter;
    return emitter.addListener("rasterImported", callback);
  },
  subscribeRasterProgress(callback) {
      var emitter = Platform.OS == 'ios' ? NativeAppEventEmitter : DeviceEventEmitter;
      return emitter.addListener("rasterProgress", callback);
    }
}

module.exports = RNGeoPackageLibrary