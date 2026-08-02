package;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import flixel.FlxG;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using flixel.util.FlxArrayUtil;

/**
 * Crash Handler.
 * @author YoshiCrafter29, Ne_Eo, MAJigsaw77 and Homura Akemi (HomuHomu833)
 */
class CrashHandler
{
	public static function init():Void
	{
		if (openfl.Lib.current != null && openfl.Lib.current.loaderInfo != null)
		{
			openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		}
		
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = Std.string(e.error);
		if (Std.isOfType(e.error, Error))
		{
			var err = cast(e.error, Error);
			m = '${err.message}';
		}
		else if (Std.isOfType(e.error, ErrorEvent))
		{
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		
		var stack = haxe.CallStack.exceptionStack();
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		
		for (item in stack)
		{
			switch (item)
			{
				case CFunction:
					stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c):
					stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');

		#if sys
		saveErrorMessage('$m\n$stackLabel');
		#end

		#if (!haxe3ds && !cafe)
		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			FlxG.stage.window.alert('$m\n$stackLabel', "Error!");
		}
		#end
		
		lime.system.System.exit(1);
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		final log:Array<String> = [];

		if (message != null)
			log.push(Std.string(message));

		log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));

		#if sys
		saveErrorMessage(log.join('\n'));
		#end

		#if (!haxe3ds && !cafe)
		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			FlxG.stage.window.alert(log.join('\n'), "Critical Error!");
		}
		#end
		
		lime.system.System.exit(1);
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		#if (haxe3ds || cafe)
		return;
		#else
		var cwd:String = "";
		try {
			cwd = Sys.getCwd();
		} catch(e:Dynamic) {
			cwd = "";
		}
		
		final folder:String = cwd + 'logs/';

		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			File.saveContent(folder + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', message);
		}
		catch (e:Dynamic)
			trace('Couldn\'t save error message. (${e})');
		#end
	}
	#end
}
