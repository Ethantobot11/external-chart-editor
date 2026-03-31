package;

import cpp.Lib;

@:keep
class IOSFilePicker {
	static var _open = Lib.load("", "openFilePicker", 0);

	public static function open():Void {
		#if ios
		_open();
		#end
	}
}
