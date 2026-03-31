package;

import sys.io.File;
import lime.system.System;

class FilePickerCallback {
	public static var onPicked: String->Void;

	public static function onFilePicked(path:String):Void {
		trace("Picked: " + path);

		// Copy to safe location (IMPORTANT for iOS)
		var fileName = path.split("/").pop();
		var newPath = System.applicationStorageDirectory + "/" + fileName;

		try {
			File.copy(path, newPath);
		} catch(e) {
			trace("Copy failed: " + e);
		}

		if (onPicked != null) {
			onPicked(newPath);
		}
	}
}
