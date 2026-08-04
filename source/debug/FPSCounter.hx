package debug;

#if !haxe3ds
import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
#else
import citro.backend.CitroColor;
import citro.object.CitroText;
import haxe3ds.Env;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project or haxe3ds platform
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#elseif (linux || !haxe3ds)
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends #if !haxe3ds TextField #else CitroText #end
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	public static var currentFPSStatic(default, null):Int;

	/**
		The current memory usage
	**/
	public static var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		#if !haxe3ds
		super();

		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';

		positionFPS(x, y);

		currentFPS = 0;
		currentFPSStatic = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		width = FlxG.width;
		multiline = true;
		text = "FPS: ";
		#else
		super(x, y, "FPS: ");
		var modeStr = Env.is3DSX ? "3DSX" : "CIA";
		os = '\nOS: Nintendo 3DS (ARM11) [$modeStr]';
		currentFPS = 0;
		currentFPSStatic = 0;
		this.color = 0xFFFFFFFF;
		setBorderStyle(0xFF000000, 1, OUTLINE);
		#end

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	#if !haxe3ds
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		currentFPSStatic = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout = 0.0;
	}
	#else
	override function update(delta:Int):Void
	{
		super.update(delta);
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		if (deltaTimeout < 50) {
			deltaTimeout += delta;
			return;
		}

		currentFPS = times.length < 60 ? times.length : 60;
		currentFPSStatic = currentFPS;
		updateText();
		deltaTimeout = 0.0;
	}
	#end

	public dynamic function updateText():Void
	{
		#if !haxe3ds
		text = 
		'FPS: $currentFPS' +
		'\nChart Editor v0.0.1' +
		'\nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}' +
		os;

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
		#else
		text = 'FPS: $currentFPS\nChart Editor v0.0.1$os';
		color = (currentFPS < 30) ? 0xFFFF0000 : 0xFFFFFFFF;
		#end
	}

	inline static function get_memoryMegas():Float
	{
		#if (cpp && !haxe3ds)
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else
		return 0.0;
		#end
	}

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		#if !haxe3ds
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
		#else
		x = X;
		y = Y;
		#end
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;
		GetSystemInfo(&osInfo);
		switch(osInfo.wProcessorArchitecture)
		{
			case 9: return ::String("x86_64");
			case 5: return ::String("ARM");
			case 12: return ::String("ARM64");
			case 6: return ::String("IA-64");
			case 0: return ::String("x86");
			default: return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
		return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#elseif nx
	@:functionCode('
		return ::String("ARMv6K");
	')
	#elseif haxe3ds
	@:functionCode('
		return ::String("ARM11");
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}
