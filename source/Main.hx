package;

#if android
import android.content.Context;
#end

import flixel.FlxG;
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

#if haxe3ds
import haxe3ds.Console;
import haxe3ds.services.GFX;
import haxe3ds.services.HID;
import haxe3ds.services.RomFS;
#end

class Main extends Sprite
{
	public var fpsVar:FPSCounter;
	public static final game = {
		width: #if haxe3ds 400 #else 1280 #end,
		height: #if haxe3ds 240 #else 720 #end,
		initialState: UploadState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static function main():Void
	{
		#if haxe3ds
		RomFS.init();
		GFX.init();
		Console.init(BOTTOM);
		#end
			
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
		#elseif haxe3ds
		try {
			if (!sys.FileSystem.exists("sdmc:/Chart-Editor/Logs")) {
				sys.FileSystem.createDirectory("sdmc:/Chart-Editor/Logs");
			}
		} catch(e:Dynamic) {}
		#end

		// Sets the default font ;)
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
