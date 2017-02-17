
import { NativeModules } from 'react-native';
const { RNGeoPackageLibrary } = NativeModules;
var promisify = require("es6-promisify");
var _libsample = promisify(RNGeoPackageLibrary.LibrarySampleCall);
var ZipArchive = {
  LibrarySampleCall(testString) {
    return _libsample(testString)
      .catch(_error)
  }
}

export default RNGeoPackageLibrary;