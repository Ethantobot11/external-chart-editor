package;

#if haxe3ds
import citro.state.CitroSubState;
import citro.object.CitroText;
import citro.object.CitroSprite;
typedef BaseSubState = CitroSubState;
#else
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
typedef BaseSubState = FlxFixedSubState;
#end

#if haxe3ds
import haxe3ds.services.HID;
@:cppFileCode('#include <3ds.h>')
#end

class SongMetadataSubState extends BaseSubState
{
	var _song:SongData;
	var _editor:ChartEditor;
	
	#if haxe3ds
	var bg:CitroSprite;
	var box:CitroSprite;
	var typingText:CitroText = null;
	var uiGroup:Array<Dynamic> = []; 
	#else
	var bg:FlxSprite;
	var box:FlxSprite;
	var typingText:FlxText = null;
	var uiGroup:FlxTypedGroup<FlxSprite>;
	#end

	var typingVar:String = "";

	// Page System
	var currentPage:String = "Meta"; // "Meta" or "Editor"
	var tabMeta:Dynamic;
	var tabEditor:Dynamic;

	public function new(songData:SongData, editor:ChartEditor)
	{
		super();
		#if !haxe3ds
		if (FlxG.cameras.list.length > 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		#end
		this._song = songData;
		this._editor = editor;
	}

	override function create()
	{
		super.create();

		#if (!haxe3ds && !cafe)
		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			FlxG.stage.window.onTextInput.add(onTextInput);
			FlxG.stage.window.onKeyDown.add(onKeyDown);
		}
		#end

		#if haxe3ds
		bg = new CitroSprite(0, 0);
		bg.makeGraphic(400, 240, 0xFF000000);
		bg.alpha = 0.6;
		add(bg);

		var bgWidth = 360;
		var bgHeight = 220;
		box = new CitroSprite((400 - bgWidth) / 2, (240 - bgHeight) / 2);
		box.makeGraphic(bgWidth, bgHeight, 0xFF222222);
		add(box);

		var title = new CitroText(box.x, box.y + 5, "Settings / Metadata");
		title.screenCenterX();
		add(title);

		var tabY = box.y + 25;
		tabMeta = new CitroButton(box.x + 10, tabY, "Metadata", 0xFF4488FF, function() { changePage("Meta"); });
		tabEditor = new CitroButton(box.x + 120, tabY, "Editor", 0xFF44FF88, function() { changePage("Editor"); });
		add(tabMeta);
		add(tabEditor);

		changePage("Meta");

		var xBtn = new CitroButton(box.x + bgWidth - 30, box.y + 5, "X", 0xFFFF4444, function() {
			close();
		});
		add(xBtn);

		#else
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var bgWidth = 650;
		var bgHeight = 550;
		box = new FlxSprite((FlxG.width - bgWidth) / 2, (FlxG.height - bgHeight) / 2).makeGraphic(bgWidth, bgHeight, 0xFF222222);
		add(box);

		var title = new FlxText(box.x, box.y + 10, bgWidth, "Settings / Metadata", 24);
		title.alignment = CENTER;
		add(title);

		var tabY = box.y + 40;
		tabMeta = new ArkButton(box.x + 20, tabY, 100, 30, 1.0, "Metadata", function() { changePage("Meta"); });
		tabEditor = new ArkButton(box.x + 130, tabY, 100, 30, 1.0, "Editor", function() { changePage("Editor"); });
		add(tabMeta);
		add(tabEditor);

		uiGroup = new FlxTypedGroup<FlxSprite>();
		add(uiGroup);
		if (FlxG.cameras.list.length > 0)
			uiGroup.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		changePage("Meta");

		var xBtn = new ArkButton(box.x + 615, box.y + 5, 25, 25, 1.0, "X", function() {
			close();
		});
		add(xBtn);
		#end
	}

	function changePage(page:String) {
		currentPage = page;
		
		#if haxe3ds
		// Clear previously generated elements for 3DS page swap
		// (Assuming a simple clearing loop or handling uiGroup via Citro)
		#else
		uiGroup.clear();
		#end

		var startY = box.y + (#if haxe3ds 60 #else 80 #end);
		var padding = #if haxe3ds 24 #else 40 #end;

		switch(page) {
			case "Meta":
				addOptionString(box.x + 20, startY, "Song Name:", "song");
				addOptionNumber(box.x + 20, startY + padding, "BPM:", "bpm", 1, 1, 999);
				addOptionNumber(box.x + 20, startY + (padding * 2), "Scroll Speed:", "speed", 0.1, 0.1, 10);
				addOptionString(box.x + 20, startY + (padding * 3), "Player 1:", "player1");
				addOptionString(box.x + 20, startY + (padding * 4), "Player 2:", "player2");
				addOptionString(box.x + 20, startY + (padding * 5), "Girlfriend:", "gfVersion");
				addOptionBool(box.x + 20, startY + (padding * 6), "Needs Voices:", "needsVoices");

				if (!Reflect.hasField(_song, "beatsPerSection")) Reflect.setField(_song, "beatsPerSection", 4);
				addOptionNumber(box.x + 20, startY + (padding * 7), "Beats/Section:", "beatsPerSection", 1, 1, 16);
			case "Editor":
				addOptionBool(box.x + 20, startY, "Show Section Lines:", "showSectionLines", true);
				addOptionBool(box.x + 20, startY + padding, "Ghost Note:", "ghostModeEnabled", true);
				addOptionBool(box.x + 20, startY + (padding * 2), "Static Strums:", "showStaticStrums", true);
				addOptionBool(box.x + 20, startY + (padding * 3), "Hit Sound:", "hitSound", true);

				addOptionNumberEditor(box.x + 20, startY + (padding * 4), "Despawn Offset:", "noteDespawnOffset", 100, 1000, 5000);
		}
	}

	override function close() {
		#if (!haxe3ds && !cafe)
		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			FlxG.stage.window.onTextInput.remove(onTextInput);
			FlxG.stage.window.onKeyDown.remove(onKeyDown);
			FlxG.stage.window.textInputEnabled = false;
		}
		#end
		if (_editor != null && Reflect.hasField(_editor, "changeStaticStrumVisibilty")) {
			_editor.changeStaticStrumVisibilty(EditorPrefs.showStaticStrums);
		}
		super.close();
	}

	function addOptionString(x:Float, y:Float, label:String, varName:String) {
		#if haxe3ds
		var lbl = new CitroText(x, y + 2, label);
		add(lbl);
		
		if(Reflect.field(_song, varName) == null) Reflect.setField(_song, varName, "");
		var currentVal = Std.string(Reflect.field(_song, varName));

		var btn = new CitroButton(x + 140, y, currentVal, 0xFF555555, function() {
			typingText = btn.label;
			typingVar = varName;
			typingText.text = "";
		});
		add(btn);
		#else
		var lbl = new FlxText(x, y + 5, 200, label, 16);
		uiGroup.add(lbl);
		
		if(Reflect.field(_song, varName) == null) Reflect.setField(_song, varName, "");
		var currentVal = Std.string(Reflect.field(_song, varName));

		var btn = new ArkButton(x + 220, y, 300, 25, 1.0, currentVal, null);

		btn.onClick = function() {
			if(typingText != null) return;
			#if (!cafe)
			if (FlxG.stage != null && FlxG.stage.window != null)
			{
				FlxG.stage.window.textInputEnabled = true;
			}
			#end
			typingText = btn.label;
			typingVar = varName;
			typingText.text = "";
		};
		uiGroup.add(btn);
		#end
	}

	function addOptionNumber(x:Float, y:Float, label:String, varName:String, change:Float, min:Float, max:Float) {
		#if haxe3ds
		var lbl = new CitroText(x, y + 2, label);
		add(lbl);
		
		var rawVal = Reflect.field(_song, varName);
		var valDisplay = new CitroText(x + 200, y + 2, Std.string(rawVal != null ? rawVal : 0));
		add(valDisplay);

		var leftBtn = new CitroButton(x + 160, y, "<", 0xFF444444, function() {
			var val:Float = Reflect.field(_song, varName) ?? 0;
			val -= change;
			if(val < min) val = min;
			val = Math.round(val * 100) / 100;
			Reflect.setField(_song, varName, val);
			valDisplay.text = Std.string(val);
		});
		add(leftBtn);

		var rightBtn = new CitroButton(x + 260, y, ">", 0xFF444444, function() {
			var val:Float = Reflect.field(_song, varName) ?? 0;
			val += change;
			if(val > max) val = max;
			val = Math.round(val * 100) / 100;
			Reflect.setField(_song, varName, val);
			valDisplay.text = Std.string(val);
		});
		add(rightBtn);
		#else
		var lbl = new FlxText(x, y + 5, 200, label, 16);
		uiGroup.add(lbl);
		
		var rawVal = Reflect.field(_song, varName);
		var valDisplay = new FlxText(x + 250, y + 5, 100, Std.string(rawVal != null ? rawVal : 0), 16);
		uiGroup.add(valDisplay);

		var leftBtn = new ArkButton(x + 220, y, 25, 25, 1.0, "<", function() {
			var val:Float = Reflect.field(_song, varName) ?? 0;
			val -= change;
			if(val < min) val = min;
			val = Math.round(val * 100) / 100;
			Reflect.setField(_song, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(leftBtn);

		var rightBtn = new ArkButton(x + 350, y, 25, 25, 1.0, ">", function() {
			var val:Float = Reflect.field(_song, varName) ?? 0;
			val += change;
			if(val > max) val = max;
			val = Math.round(val * 100) / 100;
			Reflect.setField(_song, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(rightBtn);
		#end
	}

	function addOptionNumberEditor(x:Float, y:Float, label:String, varName:String, change:Float, min:Float, max:Float) {
		#if haxe3ds
		var lbl = new CitroText(x, y + 2, label);
		add(lbl);
		
		var prefVal = Reflect.getProperty(EditorPrefs, varName);
		var valDisplay = new CitroText(x + 200, y + 2, Std.string(prefVal != null ? prefVal : 0));
		add(valDisplay);
		
		var leftBtn = new CitroButton(x + 160, y, "<", 0xFF444444, function() {
			var val:Float = Reflect.getProperty(EditorPrefs, varName) ?? 0;
			val -= change;
			if(val < min) val = min;
			Reflect.setProperty(EditorPrefs, varName, val);
			valDisplay.text = Std.string(val);
		});
		add(leftBtn);
		
		var rightBtn = new CitroButton(x + 260, y, ">", 0xFF444444, function() {
			var val:Float = Reflect.getProperty(EditorPrefs, varName) ?? 0;
			val += change;
			if(val > max) val = max;
			Reflect.setProperty(EditorPrefs, varName, val);
			valDisplay.text = Std.string(val);
		});
		add(rightBtn);
		#else
		var lbl = new FlxText(x, y + 5, 200, label, 16);
		uiGroup.add(lbl);
		
		var prefVal = Reflect.getProperty(EditorPrefs, varName);
		var valDisplay = new FlxText(x + 250, y + 5, 100, Std.string(prefVal != null ? prefVal : 0), 16);
		uiGroup.add(valDisplay);
		
		var leftBtn = new ArkButton(x + 220, y, 25, 25, 1.0, "<", function() {
			var val:Float = Reflect.getProperty(EditorPrefs, varName) ?? 0;
			val -= change;
			if(val < min) val = min;
			Reflect.setProperty(EditorPrefs, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(leftBtn);
		
		var rightBtn = new ArkButton(x + 350, y, 25, 25, 1.0, ">", function() {
			var val:Float = Reflect.getProperty(EditorPrefs, varName) ?? 0;
			val += change;
			if(val > max) val = max;
			Reflect.setProperty(EditorPrefs, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(rightBtn);
		#end
	}

	function addOptionBool(x:Float, y:Float, label:String, varName:String, ?varTypeIsAlter:Bool) {
		#if haxe3ds
		var lbl = new CitroText(x, y + 2, label);
		add(lbl);

		var val:Bool = false;
		if (varTypeIsAlter) {
			val = Reflect.getProperty(EditorPrefs, varName);
		} else {
			if(!Reflect.hasField(_song, varName)) Reflect.setField(_song, varName, false);
			val = Reflect.field(_song, varName);
		}

		var btn:CitroButton = null;
		btn = new CitroButton(x + 160, y, val ? "TRUE" : "FALSE", 0xFF444444, function() {
			var current:Bool = false;
			if (varTypeIsAlter) {
				current = Reflect.getProperty(EditorPrefs, varName);
				Reflect.setProperty(EditorPrefs, varName, !current);
			} else {
				current = Reflect.field(_song, varName);
				Reflect.setField(_song, varName, !current);
			}

			var newState = !current;
			btn.label.text = newState ? "TRUE" : "FALSE";
		});
		add(btn);
		#else
		var lbl = new FlxText(x, y + 5, 200, label, 16);
		uiGroup.add(lbl);

		var val:Bool = false;
		if (varTypeIsAlter) {
			val = Reflect.getProperty(EditorPrefs, varName);
		} else {
			if(!Reflect.hasField(_song, varName)) Reflect.setField(_song, varName, false);
			val = Reflect.field(_song, varName);
		}

		var btn:ArkButton = null;
		btn = new ArkButton(x + 220, y, 100, 25, 1.0, val ? "TRUE" : "FALSE", function() {
			var current:Bool = false;
			if (varTypeIsAlter) {
				current = Reflect.getProperty(EditorPrefs, varName);
				Reflect.setProperty(EditorPrefs, varName, !current);
			} else {
				current = Reflect.field(_song, varName);
				Reflect.setField(_song, varName, !current);
			}

			var newState = !current;
			btn.label.text = newState ? "TRUE" : "FALSE";
		});
		uiGroup.add(btn);
		#end
	}

	#if haxe3ds
	override function update(delta:Int) {
		super.update(delta);

		if (typingText != null) {
			if (HID.keyPressed(HIDKey.START) || HID.keyPressed(HIDKey.B)) {
				Reflect.setField(_song, typingVar, typingText.text);
				typingText = null;
				typingVar = "";
				changePage(currentPage);
			}
			else if (HID.keyPressed(HIDKey.X)) {
				typingText.text = "";
			}
		}
	}
	#else
	override function update(elapsed:Float) {
		super.update(elapsed);
	}
	#end
	
	function onTextInput(text:String):Void {
		if (typingText != null) {
			typingText.text += text;
		}
	}

	function onKeyDown(key:Int, modifier:Int):Void {
		if (typingText != null) {
			if (key == 13) { // Enter
				Reflect.setField(_song, typingVar, typingText.text);
				typingText = null;
				typingVar = "";
				#if (!cafe)
				if (FlxG.stage != null && FlxG.stage.window != null)
				{
					FlxG.stage.window.textInputEnabled = false;
				}
				#end

				changePage(currentPage);
			} 
			else if (key == 8) { // Backspace
				if (typingText.text.length > 0)
					typingText.text = typingText.text.substr(0, typingText.text.length - 1);
			}
		}
	}
}
