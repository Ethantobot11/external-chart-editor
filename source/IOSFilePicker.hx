package;

@:keep
class IOSFilePicker {
	public static function open():Void {
		#if ios
		untyped __cpp__("openFilePicker()");
		#end
	}
}
