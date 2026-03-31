package;

@:cppFileCode('extern "C" void openFilePicker();')
extern class IOSFilePicker {
	public static function open():Void {
		untyped __cpp__("openFilePicker()");
	}
}
