package;

class FlxFixedSubState extends FlxSubState {
	override function add(basic:FlxBasic):FlxBasic {
		super.add(basic);
		if (cameras != null) basic.cameras = cameras;
		return basic;
	}
	function new() {
		super();
	}
}