package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import sys.io.File;

#if ios
import IOSFilePicker;
import FilePickerCallback;
#end

class UploadState extends FlxState
{
	var instData:ByteArray;
	var voicesData:ByteArray;
	var voicesOppData:ByteArray;
	var chartData:String;
	var eventsData:String;
	var customNotePath:String = "";

	var statusText:FlxText;
	var btnContinue:ModernButton;
	var _loadingType:String;

	override function create()
	{
		super.create();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1A1A1A);
		add(bg);

		var title = new FlxText(0, 40, FlxG.width, "Chart Editor Setup", 32);
		title.setFormat(null, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		title.borderSize = 2;
		add(title);

		var startY = 120;
		var btnGap = 70;
		var centerX = FlxG.width / 2;

		add(new ModernButton(centerX - 150, startY, "Load Inst (Required)", 0xFF4488FF, function() { loadFile("inst"); }));
		add(new ModernButton(centerX - 150, startY + btnGap, "Load Voices (Player)", 0xFF44FF88, function() { loadFile("voices"); }));
		add(new ModernButton(centerX - 150, startY + (btnGap * 2), "Load Voices (Opponent)", 0xFFFF8844, function() { loadFile("voices_opp"); }));
		add(new ModernButton(centerX - 150, startY + (btnGap * 3), "Load Psych Chart (.json)", 0xFFFFFF44, function() { loadFile("chart"); }));
		add(new ModernButton(centerX - 150, startY + (btnGap * 4), "Load Events (Optional)", 0xFFDD44DD, function() { loadFile("events"); }));

		add(new ModernButton(centerX - 150, startY + (btnGap * 5), "Custom Notes (iOS unsupported)", 0xFFAA44AA, function() {
			statusText.text = "Folder picking not supported on iOS";
		}));

		statusText = new FlxText(0, startY + (btnGap * 6), FlxG.width, "Waiting for Inst...", 16);
		statusText.alignment = CENTER;
		add(statusText);

		btnContinue = new ModernButton(centerX - 150, FlxG.height - 80, "START EDITOR", 0xFF00CC00, function() {
			FlxG.switchState(new ChartEditor(instData, voicesData, voicesOppData, chartData, eventsData, customNotePath));
		});
		btnContinue.alpha = 0.5;
		btnContinue.active = false;
		add(btnContinue);
	}

	function loadFile(type:String)
	{
		_loadingType = type;

		#if ios
		FilePickerCallback.onPicked = handlePickedFile;
		IOSFilePicker.open();
		#end
	}

	function handlePickedFile(path:String)
	{
		statusText.text = "Loaded: " + path;

		if (StringTools.endsWith(path, ".json"))
		{
			var content = File.getContent(path);

			switch (_loadingType)
			{
				case "chart": chartData = content;
				case "events": eventsData = content;
			}
		}
		else
		{
			var bytes = File.getBytes(path);
			switch (_loadingType)
			{
				case "inst":
					instData = bytes;
					statusText.text = "Instrumental Loaded!";
					statusText.color = FlxColor.CYAN;
				case "voices":
					voicesData = bytes;
					statusText.text = "Player Voices Loaded.";
				case "voices_opp":
					voicesOppData = bytes;
					statusText.text = "Opponent Voices Loaded.";
			}
		}

		if (instData != null)
		{
			btnContinue.active = true;
			btnContinue.alpha = 1;
		}
	}
}

class ModernButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var label:FlxText;
	var onClick:Void->Void;
	var baseColor:Int;

	public function new(x:Float, y:Float, text:String, color:Int, onClick:Void->Void)
	{
		super(x, y);
		this.onClick = onClick;
		this.baseColor = color;

		bg = new FlxSprite().makeGraphic(300, 50, 0xFFFFFFFF);
		bg.color = color;
		bg.alpha = 0.8;
		add(bg);

		var border = new FlxSprite(0, 0).makeGraphic(300, 4, 0x44000000);
		border.y = 46;
		add(border);

		label = new FlxText(0, 0, 300, text, 16);
		label.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		label.y = (50 - label.height) / 2;
		add(label);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.overlaps(bg))
		{
			bg.alpha = 1;
			if (FlxG.mouse.justPressed && active)
				if (onClick != null) onClick();
		}
		else
			bg.alpha = 0.8;
	}
}
