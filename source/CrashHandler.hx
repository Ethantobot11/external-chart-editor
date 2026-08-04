package;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;

// Conditional imports for FlxG / Desktop vs 3DS environment
#if haxe3ds
import haxe3ds.Console;
#else
import flixel.FlxG;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
#if !haxe3ds
using flixel.util.FlxArrayUtil;
#end

/**
 * Crash Handler adapted for Nintendo 3DS and multiplatform.
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
							stackLabelArr.push('${file.replace(".hx", "")}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace(".hx", "")} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');

		var fullErrorLog = '$m\n$stackLabel';

		#if sys
		saveErrorMessage(fullErrorLog);
		#end

		#if (haxe3ds || cafe)
		#if haxe3ds
		Sys.println("\nCRASH OCCURRED:\n" + fullErrorLog);
		#end
		#else
		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			FlxG.stage.window.alert(fullErrorLog, "Error!");
		}
		#end
		
		#if (!haxe3ds && !cafe)
		lime.system.System.exit(1);
		#end
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		final log:Array<String> = [];

		if (message != null)
			log.push(Std.string(message));

		log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));
		var fullLog = log.join('\n');

		#if sys
		saveErrorMessage(fullLog);
		#end

		#if (haxe3ds || cafe)
		#if haxe3ds
		Sys.println("\nCRITICAL ERROR:\n" + fullLog);
		#end
		#else
		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			FlxG.stage.window.alert(fullLog, "Critical Error!");
		}
		#end
		
		#if (!haxe3ds && !cafe)
		lime.system.System.exit(1);
		#end
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		try
		{
			#if (haxe3ds || cafe)
			var folder:String = "sdmc:/Chart-Editor/Logs/";
			#else
			var cwd:String = "";
			try {
				cwd = Sys.getCwd();
			} catch(e:Dynamic) {
				cwd = "";
			}
			final folder:String = cwd + 'logs/';
			#end

			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			File.saveContent(folder + 'crash_' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', message);
		}
		catch (e:Dynamic)
			trace('Couldn\'t save error message. (${e})');
	}
	#end
}
