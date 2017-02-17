
# react-native-geo-package-library

## Getting started

`$ npm install react-native-geo-package-library --save`

### Mostly automatic installation

`$ react-native link react-native-geo-package-library`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-geo-package-library` and add `RNGeoPackageLibrary.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNGeoPackageLibrary.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNGeoPackageLibraryPackage;` to the imports at the top of the file
  - Add `new RNGeoPackageLibraryPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-geo-package-library'
  	project(':react-native-geo-package-library').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-geo-package-library/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-geo-package-library')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNGeoPackageLibrary.sln` in `node_modules/react-native-geo-package-library/windows/RNGeoPackageLibrary.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Cl.Json.RNGeoPackageLibrary;` to the usings at the top of the file
  - Add `new RNGeoPackageLibraryPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNGeoPackageLibrary from 'react-native-geo-package-library';

// TODO: What do with the module?
RNGeoPackageLibrary;
```
  