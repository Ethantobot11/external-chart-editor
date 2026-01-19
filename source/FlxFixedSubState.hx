package;

class FlxFixedSubState extends FlxSubState {
	override function add(basic:FlxBasic):FlxBasic {
		super.add(basic);
		if (defaultCamera != null) basic.cameras = [defaultCamera];
		return basic;
	}
	function new() {
		super();
	}
}