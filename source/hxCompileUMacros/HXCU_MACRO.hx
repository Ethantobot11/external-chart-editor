package hxCompileUMacros;

#if macro
import haxe.macro.Compiler;
#end

class HXCU_MACRO {
    public static function macroInit():Void {
        #if (wiiu || cafe)
        Compiler.define("no-thread");
        #end
    }
}
