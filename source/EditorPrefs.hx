package;

class EditorPrefs {
	public static var hitSound:Bool = false;
	public static var showStaticStrums:Bool = true;
	public static var ghostModeEnabled:Bool = true;
	public static var showSectionLines:Bool = true;
	public static var noteDespawnOffset:Float = 2000;
	
	public static function reset() {
		hitSound = false;
		showStaticStrums = true;
		ghostModeEnabled = true;
		showSectionLines = true;
		noteDespawnOffset = 2000;
	}
}