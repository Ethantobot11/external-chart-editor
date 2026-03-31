package;

import cpp.Lib;

@:keep
@:cppFileCode('extern "C" void openFilePicker();')
class IOSFilePicker {
	public static function open():Void {
		#if ios
		untyped __cpp__("openFilePicker()");
		#end
	}
}
