package;

#if haxe3ds
import citro.state.CitroSubState;
typedef BaseFixedSubState = CitroSubState;
#else
import flixel.FlxSubState;
import flixel.FlxBasic;
typedef BaseFixedSubState = FlxFixedSubState;
#end

class FlxFixedSubState extends BaseFixedSubState {
	#if !haxe3ds
	override function add(basic:FlxBasic):FlxBasic {
		super.add(basic);
		if (cameras != null) basic.cameras = cameras;
		return basic;
	}
	#end

	function new() {
		super();
	}
}
