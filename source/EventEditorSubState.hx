package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

#if (haxe3ds || cafe)
import haxe3ds.services.HID;
#end

class EventEditorSubState extends FlxFixedSubState {
	var note:EditorNoteData;
	var onSave:Void->Void;
	var typingText:FlxText = null;
	var typingVar:String = '';
	var box:FlxSprite;
	var uiGroup:FlxTypedGroup<FlxSprite>; 

	public function new(n:EditorNoteData, onSave:Void->Void) {
		super();
		if (FlxG.cameras.list.length > 0)
			defaultCamera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		this.note = n;
		this.onSave = onSave;
	}

	override function create() {
		super.create();
		
		#if (!haxe3ds && !cafe)
		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			FlxG.stage.window.onTextInput.add(onTextInput);
			FlxG.stage.window.onKeyDown.add(onKeyDown);
		}
		#end

		if (FlxG.cameras.list.length > 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		add(bg);

		box = new FlxSprite(0, 0).makeGraphic(400, 300, 0xFF333333);
		box.screenCenter();
		add(box);

		var title = new FlxText(box.x, box.y + 10, 400, "Edit Event", 20);
		title.alignment = CENTER;
		add(title);

		uiGroup = new FlxTypedGroup<FlxSprite>();
		add(uiGroup);
		if (FlxG.cameras.list.length > 0)
			uiGroup.defaultCamera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		createOptions();

		var xBtn = new ArkButton(box.x + 370, box.y + 5, 25, 25, 1.0, "X", function() {
			onSave();
			close();
		});
		add(xBtn);
	}

	function createOptions() {
		uiGroup.clear();
		addOptionString(box.x + 20, box.y + 50, "Event Name:", 'noteType');
		addOptionString(box.x + 20, box.y + 110, "Value 1:", 'eventVal1');
		addOptionString(box.x + 20, box.y + 170, "Value 2:", 'eventVal2');
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
		super.close();
	}
	
	function addOptionString(x:Float, y:Float, label:String, varName:String) {
		var lbl = new FlxText(x, y + 5, 200, label, 16); 
		uiGroup.add(lbl);

		var currentVal = Std.string(Reflect.getProperty(note, varName));
		if (currentVal == null) currentVal = '';
		var btn = new ArkButton(x + 110, y, 200, 25, 1.0, currentVal, null);

		btn.onClick = function() {
			if(typingText != null) return;
			
			#if (!haxe3ds && !cafe)
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
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		#if (haxe3ds || cafe)
		if (typingText != null) {
			if (HID.keyPressed(HIDKey.START) || HID.keyPressed(HIDKey.B)) {
				Reflect.setProperty(note, typingVar, typingText.text);
				typingVar = '';
				typingText = null;
				createOptions();
			}
			else if (HID.keyPressed(HIDKey.X)) {
				typingText.text = "";
			}
		}
		#end
	}

	function onTextInput(text:String):Void {
		if (typingText != null) {
			typingText.text += text;
		}
	}

	function onKeyDown(key:Int, modifier:Int):Void {
		if (typingText != null) {
			if (key == 13) { // Enter
				Reflect.setProperty(note, typingVar, typingText.text);
				typingVar = '';
				typingText = null;
				#if (!haxe3ds && !cafe)
				if (FlxG.stage != null && FlxG.stage.window != null)
				{
					FlxG.stage.window.textInputEnabled = false;
				}
				#end
				createOptions();
			}
			else if (key == 8) { // Backspace
				if (typingText.text.length > 0)
					typingText.text = typingText.text.substr(0, typingText.text.length - 1);
			}
		}
	}
}
