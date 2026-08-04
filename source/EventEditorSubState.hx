package;

#if haxe3ds
import citro.state.CitroSubState;
import citro.object.CitroText;
import citro.object.CitroSprite;
typedef FixedSubState = CitroSubState;
#else
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
typedef FixedSubState = FlxFixedSubState;
#end

#if haxe3ds
import haxe3ds.services.HID;
@:cppFileCode('#include <3ds.h>')
#end

class EventEditorSubState extends FixedSubState {
	var note:EditorNoteData;
	var onSave:Void->Void;
	
	#if haxe3ds
	var typingText:CitroText = null;
	var box:CitroSprite;
	var uiGroup:Array<Dynamic> = [];
	#else
	var typingText:FlxText = null;
	var box:FlxSprite;
	var uiGroup:FlxTypedGroup<FlxSprite>;
	#end

	var typingVar:String = '';

	public function new(n:EditorNoteData, onSave:Void->Void) {
		super();
		#if !haxe3ds
		if (FlxG.cameras.list.length > 0)
			camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		#end
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

		#if !haxe3ds
		if (FlxG.cameras.list.length > 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		#end

		#if haxe3ds
		var bg = new CitroSprite(0, 0);
		bg.makeGraphic(400, 240, 0xAA000000);
		add(bg);

		box = new CitroSprite(0, 0);
		box.makeGraphic(340, 200, 0xFF333333);
		box.screenCenter();
		add(box);

		var title = new CitroText(box.x, box.y + 5, "Edit Event");
		title.screenCenterX();
		add(title);

		createOptions();

		var xBtn = new CitroButton(box.x + 310, box.y + 5, "X", 0xFFFF4444, function() {
			onSave();
			close();
		});
		add(xBtn);

		#else
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
			uiGroup.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		createOptions();

		var xBtn = new ArkButton(box.x + 370, box.y + 5, 25, 25, 1.0, "X", function() {
			onSave();
			close();
		});
		add(xBtn);
		#end
	}

	function createOptions() {
		#if haxe3ds
		// 3DS manual clearing or handling for array UI group
		#else
		uiGroup.clear();
		#end

		addOptionString(box.x + 20, box.y + (#if haxe3ds 30 #else 50 #end), "Event Name:", 'noteType');
		addOptionString(box.x + 20, box.y + (#if haxe3ds 75 #else 110 #end), "Value 1:", 'eventVal1');
		addOptionString(box.x + 20, box.y + (#if haxe3ds 120 #else 170 #end), "Value 2:", 'eventVal2');
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
		#if haxe3ds
		var lbl = new CitroText(x, y + 2, label);
		add(lbl);

		var currentVal = Std.string(Reflect.getProperty(note, varName));
		if (currentVal == null) currentVal = '';
		var btn = new CitroButton(x + 100, y, currentVal, 0xFF555555, function() {
			typingText = btn.label;
			typingVar = varName;
			typingText.text = "";
		});
		add(btn);
		#else
		var lbl = new FlxText(x, y + 5, 200, label, 16); 
		uiGroup.add(lbl);

		var currentVal = Std.string(Reflect.getProperty(note, varName));
		if (currentVal == null) currentVal = '';
		var btn = new ArkButton(x + 110, y, 200, 25, 1.0, currentVal, null);

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

	#if haxe3ds
	override function update(delta:Int) {
		super.update(delta);

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
	}
	#else
	override function update(#if haxe3ds delta:Int #else elapsed:Float #end) {
		super.update(#if !haxe3ds elapsed #end);
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
				Reflect.setProperty(note, typingVar, typingText.text);
				typingVar = '';
				typingText = null;
				#if (!cafe)
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
