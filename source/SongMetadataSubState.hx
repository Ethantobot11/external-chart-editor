package;

class SongMetadataSubState extends FlxFixedSubState
{
	var _song:SongData;
	var _editor:ChartEditor;
	var bg:FlxSprite;
	var container:FlxSprite;
	var typingText:FlxText = null;
	var typingVar:String = "";

	// Page System
	var currentPage:String = "Meta"; // "Meta" or "Editor"
	var tabMeta:ArkButton;
	var tabEditor:ArkButton;
	var uiGroup:FlxTypedGroup<FlxSprite>; 

	public function new(songData:SongData, editor:ChartEditor)
	{
		super();
		defaultCamera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		this._song = songData;
		this._editor = editor;
	}

	override function create()
	{
		super.create();

		FlxG.stage.window.onTextInput.add(onTextInput);
		FlxG.stage.window.onKeyDown.add(onKeyDown);

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var bgWidth = 650;
		var bgHeight = 550;
		container = new FlxSprite((FlxG.width - bgWidth) / 2, (FlxG.height - bgHeight) / 2).makeGraphic(bgWidth, bgHeight, 0xFF222222);
		add(container);

		var title = new FlxText(container.x, container.y + 10, bgWidth, "Settings / Metadata", 24);
		title.alignment = CENTER;
		add(title);

		var tabY = container.y + 40;
		// ArkButton(x, y, width, height, scale, label, callback, camera)
		tabMeta = new ArkButton(container.x + 20, tabY, 100, 30, 1.0, "Metadata", function() { changePage("Meta"); });
		tabEditor = new ArkButton(container.x + 130, tabY, 100, 30, 1.0, "Editor", function() { changePage("Editor"); });
		add(tabMeta);
		add(tabEditor);

		uiGroup = new FlxTypedGroup<FlxSprite>();
		add(uiGroup);
		uiGroup.defaultCamera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		changePage("Meta");

		var xBtn = new ArkButton(container.x + 615, container.y + 5, 25, 25, 1.0, "X", function() {
			close();
		});
		add(xBtn);
	}

	function changePage(page:String) {
		currentPage = page;
		uiGroup.clear(); 

		var startY = container.y + 80;
		var padding = 40;

		switch(page) {
			case "Meta":
				addOptionString(container.x + 20, startY, "Song Name:", "song");
				addOptionNumber(container.x + 20, startY + padding, "BPM:", "bpm", 1, 1, 999);
				addOptionNumber(container.x + 20, startY + (padding * 2), "Scroll Speed:", "speed", 0.1, 0.1, 10);
				addOptionString(container.x + 20, startY + (padding * 3), "Player 1:", "player1");
				addOptionString(container.x + 20, startY + (padding * 4), "Player 2:", "player2");
				addOptionString(container.x + 20, startY + (padding * 5), "Girlfriend:", "gfVersion");
				addOptionBool(container.x + 20, startY + (padding * 6), "Needs Voices:", "needsVoices");

				if (!Reflect.hasField(_song, "beatsPerSection")) Reflect.setField(_song, "beatsPerSection", 4);
				addOptionNumber(container.x + 20, startY + (padding * 7), "Beats/Section:", "beatsPerSection", 1, 1, 16);
			case "Editor":
				addOptionBool(container.x + 20, startY, "Show Section Lines:", "showSectionLines", true);
				addOptionBool(container.x + 20, startY + padding, "Ghost Note:", "ghostModeEnabled", true);
				addOptionBool(container.x + 20, startY + (padding * 2), "Static Strums:", "showStaticStrums", true);
				addOptionBool(container.x + 20, startY + (padding * 3), "Hit Sound:", "hitSound", true);

				addOptionNumberEditor(container.x + 20, startY + (padding * 4), "Despawn Offset:", "noteDespawnOffset", 100, 1000, 5000);
		}
	}

	override function close() {
		FlxG.stage.window.onTextInput.remove(onTextInput);
		FlxG.stage.window.onKeyDown.remove(onKeyDown);
		_editor.changeStaticStrumVisibilty(EditorPrefs.showStaticStrums);
		super.close();
	}

	function addOptionString(x:Float, y:Float, label:String, varName:String) {
		var lbl = new FlxText(x, y + 5, 200, label, 16);
		uiGroup.add(lbl);
		
		if(Reflect.field(_song, varName) == null) Reflect.setField(_song, varName, "");
		var currentVal = Std.string(Reflect.field(_song, varName));

		var btn = new ArkButton(x + 220, y, 300, 25, 1.0, currentVal, null);

		btn.onClick = function() {
			if(typingText != null) return;
			FlxG.stage.window.textInputEnabled = true;
			typingText = btn.label;
			typingVar = varName;
			typingText.text = "";
		};
		
		uiGroup.add(btn);
	}

	function addOptionNumber(x:Float, y:Float, label:String, varName:String, change:Float, min:Float, max:Float) {
		var lbl = new FlxText(x, y + 5, 200, label, 16);
		uiGroup.add(lbl);
		
		var valDisplay = new FlxText(x + 250, y + 5, 100, Std.string(Reflect.field(_song, varName)), 16);
		uiGroup.add(valDisplay);

		var leftBtn = new ArkButton(x + 220, y, 25, 25, 1.0, "<", function() {
			var val:Float = Reflect.field(_song, varName);
			val -= change;
			if(val < min) val = min;
			val = Math.round(val * 100) / 100;
			Reflect.setField(_song, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(leftBtn);

		var rightBtn = new ArkButton(x + 350, y, 25, 25, 1.0, ">", function() {
			var val:Float = Reflect.field(_song, varName);
			val += change;
			if(val > max) val = max;
			val = Math.round(val * 100) / 100;
			Reflect.setField(_song, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(rightBtn);
	}

	function addOptionNumberEditor(x:Float, y:Float, label:String, varName:String, change:Float, min:Float, max:Float) {
		var lbl = new FlxText(x, y + 5, 200, label, 16);
		uiGroup.add(lbl);
		
		var valDisplay = new FlxText(x + 250, y + 5, 100, Std.string(Reflect.getProperty(EditorPrefs, varName)), 16);
		uiGroup.add(valDisplay);
		
		var leftBtn = new ArkButton(x + 220, y, 25, 25, 1.0, "<", function() {
			var val:Float = Reflect.getProperty(EditorPrefs, varName);
			val -= change;
			if(val < min) val = min;
			Reflect.setProperty(EditorPrefs, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(leftBtn);
		
		var rightBtn = new ArkButton(x + 350, y, 25, 25, 1.0, ">", function() {
			var val:Float = Reflect.getProperty(EditorPrefs, varName);
			val += change;
			if(val > max) val = max;
			Reflect.setProperty(EditorPrefs, varName, val);
			valDisplay.text = Std.string(val);
		});
		uiGroup.add(rightBtn);
	}

	function addOptionBool(x:Float, y:Float, label:String, varName:String, ?varTypeIsAlter:Bool) {
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
	}
	
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
				FlxG.stage.window.textInputEnabled = false;

				changePage(currentPage);
			} 
			else if (key == 8) { // Backspace
				if (typingText.text.length > 0)
					typingText.text = typingText.text.substr(0, typingText.text.length - 1);
			}
		}
	}
}
