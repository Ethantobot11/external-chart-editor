package;

#if android
import android.content.Context;
#end

#if (!haxe3ds)
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
#end

#if haxe3ds
import haxe3ds.Console;
import haxe3ds.services.APT;
import haxe3ds.services.GFX;
import haxe3ds.services.HID;
import haxe3ds.services.RomFS;
import haxe3ds.services.News;
#end

#if haxe3ds
@:headerInclude("3ds.h")
#end
class Main 
#if (!haxe3ds) extends Sprite #end
{
	#if (!haxe3ds)
	public var fpsVar:FPSCounter;
	#end

	public static final game = {
		width: #if haxe3ds 400 #else 1280 #end,
		height: #if haxe3ds 240 #else 720 #end,
		initialState: #if !haxe3ds UploadState #else TestState3DS #end,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static function main():Void
	{
		#if haxe3ds
		RomFS.init();
		GFX.init();
		News.init();
		Console.init(TOP);

		Sys.println("1. Services initialized.");

		var statusSuccess = true;

		try {
			if (!sys.FileSystem.exists("sdmc:/Chart-Editor/Logs")) {
				sys.FileSystem.createDirectory("sdmc:/Chart-Editor/Logs");
				Sys.println("2. Created directory: sdmc:/Chart-Editor/Logs");
			} else {
				Sys.println("2. Log directory already exists.");
			}
		} catch(e:Dynamic) {
			Sys.println("2. Warning/Error creating dir: " + e);
			statusSuccess = false;
			try {
				News.flashLEDPattern(NewsLampPattern.FRIEND_ONLINE);
			} catch(err:Dynamic) {}
		}

		if (statusSuccess) {
			Sys.println("3. Boot test successful!");
			try {
				News.flashLEDPattern(NewsLampPattern.CEC);
			} catch(err:Dynamic) {}
		} else {
			Sys.println("3. Boot completed with warnings.");
			try {
				News.flashLEDPattern(NewsLampPattern.BOSS);
			} catch(err:Dynamic) {}
		}

		Sys.println("Press [START] to exit application.");

		while (APT.mainLoop()) {
			if (HID.keyPressed(HIDKey.START)) {
				break;
			}
		}

		News.exit();
		GFX.exit();
		#else
		Lib.current.addChild(new Main());
		#end
	}

	#if (!haxe3ds)
	public function new()
	{
		super();
		CrashHandler.init();
		
		#if android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(android.content.Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.documentsDirectory);
		#end
			
		FlxAssets.FONT_DEFAULT = FlxAssets.FONT_DEBUGGER = AssetPaths.vcr__ttf;
		FlxSprite.defaultAntialiasing = true;

		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);

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
	#end
}
