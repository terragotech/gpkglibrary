using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Com.Reactlibrary.RNGeoPackageLibrary
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNGeoPackageLibraryModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNGeoPackageLibraryModule"/>.
        /// </summary>
        internal RNGeoPackageLibraryModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNGeoPackageLibrary";
            }
        }
    }
}
