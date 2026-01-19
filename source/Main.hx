package;

#if android
import android.content.Context;
#end

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.system.FlxAssets;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import lime.app.Application;

import debug.FPSCounter;

class Main extends Sprite
{
	public var fpsVar:FPSCounter;
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: UploadState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	// You can pretty much ignore everything from here on - your code should go in your states.
	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		CrashHandler.init();
		#if android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(android.content.Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.documentsDirectory);
		#end
		//Sets tbe default font ;)
		FlxAssets.FONT_DEFAULT = FlxAssets.FONT_DEBUGGER = AssetPaths.vcr__ttf;
		FlxSprite.defaultAntialiasing = true;

		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
			if(fpsVar != null)
				fpsVar.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));

		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}