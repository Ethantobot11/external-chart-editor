package objects;

#if !haxe3ds
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
#else
import citro.backend.CitroColor;
import citro.object.CitroObject;
import citro.object.CitroCamera;
#end

class ArkDropDown extends #if !haxe3ds FlxSpriteGroup #else CitroObject #end {
	public var headerBtn:ArkButton;
	public var isOpen:Bool = false;
	
	#if !haxe3ds
	var bgOptions:FlxTypedGroup<ArkButton>;
	var cam:FlxCamera;
	#else
	var bgOptions:Array<ArkButton>;
	var cam:CitroCamera;
	#end

	var optionLabels:Array<String>;
	var onSelect:String->Void;
	var uiScale:Float;
	var _height:Int;
	var autoClose:Bool;

	public function new(x:Float, y:Float, width:Int, height:Int, scale:Float, label:String, options:Array<String>, onSelect:String->Void, #if !haxe3ds cam:FlxCamera #else cam:CitroCamera #end, autoClose:Bool = true) {
		#if !haxe3ds
		super(x, y);
		#else
		super();
		this.x = x;
		this.y = y;
		#end

		this.width = width;
		this.height = height;
		this.uiScale = scale;
		this.optionLabels = options;
		this.onSelect = onSelect;
		this.cam = cam;
		this._height = height;
		this.autoClose = autoClose;

		#if !haxe3ds
		bgOptions = new FlxTypedGroup<ArkButton>();
		#else
		bgOptions = [];
		#end

		headerBtn = new ArkButton(0, 0, width, height, scale, label + ": " + (options.length > 0 ? options[0] : "None"), toggleOpen, cam);
		
		#if !haxe3ds
		add(headerBtn);
		this.cameras = [cam];
		#end
	}

	function toggleOpen() {
		isOpen = !isOpen;
		refreshOptions();
	}

	function refreshOptions() {
		#if !haxe3ds
		for (btn in bgOptions) {
			remove(btn);
			btn.destroy();
		}
		bgOptions.clear();
		#else
		for (btn in bgOptions) {
			btn.destroy();
		}
		bgOptions = [];
		#end

		if (isOpen) {
			var currentY = _height;
			for (i in 0...optionLabels.length) {
				var opt = optionLabels[i];
				var btnLabel = i + ": " + opt;
				var btn = new ArkButton(0, currentY, Std.int(width), _height, uiScale, btnLabel, function() {
					if (onSelect != null) onSelect(opt);
					headerBtn.label.text = "ꜜ Type: " + opt + " ꜜ";
					if (autoClose) toggleOpen();
				}, cam);
				
				btn.bg.color = (i % 2 == 0) ? 0xFF555555 : 0xFF666666;
				
				#if !haxe3ds
				add(btn);
				bgOptions.add(btn);
				#else
				bgOptions.push(btn);
				#end

				currentY += _height;
			}
		}
	}

	override function update(#if haxe3ds delta:Int #else elapsed:Float #end) {
		super.update(#if !haxe3ds elapsed #else delta #end);
		headerBtn.update(#if !haxe3ds elapsed #else delta #end);
		if(isOpen) {
			#if !haxe3ds
			bgOptions.update(#if !haxe3ds elapsed #else delta #end);
			#else
			for (btn in bgOptions) {
				btn.update(#if !haxe3ds elapsed #else delta #end);
			}
			#end
		}
	}
}
