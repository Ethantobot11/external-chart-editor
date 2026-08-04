package;

import flixel.FlxG;
import flixel.FlxState;

class TestState3DS extends FlxState {
    override public function create():Void {
        super.create();
        FlxG.cameras.bgColor = flixel.util.FlxColor.RED;
    }
}
