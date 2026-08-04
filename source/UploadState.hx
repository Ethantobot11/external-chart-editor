package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.addons.display.FlxGridOverlay;
import openfl.utils.ByteArray;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if haxe3ds
import haxe3ds.services.HID;
import haxe3ds.services.GFX;
@:headerInclude("3ds.h")
#end

class UploadState extends FlxState
{
	var instBytes:ByteArray = null;
	var voicesBytes:ByteArray = null;
	var voicesOppBytes:ByteArray = null;
	var chartData:String = "";
	var eventsData:String = "";
	var customNotePath:String = "";

	// UI
	var statusText:FlxText;
	var btnContinue:ModernButton;
	var listIndex:Int = 0;
	var filesList:Array<String> = [];

	override function create()
	{
		super.create();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1A1A1A);
		add(bg);
		var grid = FlxGridOverlay.create(40, 40, Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), true, 0x11FFFFFF, 0x00FFFFFF);
		add(grid);
		var title = new FlxText(0, 20, FlxG.width, "3DS Chart Editor Setup", 28);
		title.setFormat(null, 28, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		title.borderSize = 2;
		add(title);

		var startY = 80;
		var btnGap = 55;
		var centerX = FlxG.width / 2;

		add(new ModernButton(centerX - 160, startY, "Load Inst from sdmc:/charts/", 0xFF4488FF, function() { scanAndLoad("inst"); }));
		add(new ModernButton(centerX - 160, startY + btnGap, "Load Voices (Player)", 0xFF44FF88, function() { scanAndLoad("voices"); }));
		add(new ModernButton(centerX - 160, startY + (btnGap * 2), "Load Voices (Opponent)", 0xFFFF8844, function() { scanAndLoad("voices_opp"); }));
		add(new ModernButton(centerX - 160, startY + (btnGap * 3), "Load Chart (.json)", 0xFFFFFF44, function() { scanAndLoad("chart"); }));
		add(new ModernButton(centerX - 160, startY + (btnGap * 4), "Load Events (Optional)", 0xFFDD44DD, function() { scanAndLoad("events"); }));

		statusText = new FlxText(10, startY + (btnGap * 5.5), FlxG.width - 20, "Place files in 'sdmc:/charts/' on your SD card.\nPress A or Click to select.", 14);
		statusText.alignment = CENTER;
		add(statusText);

		btnContinue = new ModernButton(centerX - 160, FlxG.height - 60, "START EDITOR", 0xFF00CC00, function() {
			#if haxe3ds
			FlxG.switchState(new ChartEditor(instBytes, voicesBytes, voicesOppBytes, chartData, eventsData, customNotePath));
			#end
		});
		btnContinue.alpha = 0.5;
		btnContinue.active = false;
		add(btnContinue);
	}

	function scanAndLoad(type:String)
	{
		#if (haxe3ds || sys)
		var targetDir = "sdmc:/charts/";
		if (!FileSystem.exists(targetDir)) {
			FileSystem.createDirectory(targetDir);
			statusText.text = "Created 'sdmc:/charts/'. Put files there!";
			return;
		}

		filesList = [];
		for (file in FileSystem.readDirectory(targetDir)) {
			if (type == "chart" || type == "events") {
				if (file.endsWith(".json")) filesList.push(targetDir + file);
			} else {
				if (file.endsWith(".ogg") || file.endsWith(".mp3")) filesList.push(targetDir + file);
			}
		}

		if (filesList.length > 0) {
			var selectedFile = filesList[0];
			assignData(type, selectedFile);
			statusText.text = "Loaded: " + selectedFile.split("/").pop();
		} else {
			statusText.text = "No matching files found in sdmc:/charts/";
		}
		#else
		statusText.text = "SD Card loading only available on console build.";
		#end
	}

	function assignData(type:String, path:String)
	{
		switch(type) {
			case "inst":
				#if sys
				instBytes = ByteArray.fromFile(path);
				btnContinue.active = true;
				btnContinue.alpha = 1;
				#end
			case "voices":
				#if sys
				voicesBytes = ByteArray.fromFile(path);
				#end
			case "voices_opp":
				#if sys
				voicesOppBytes = ByteArray.fromFile(path);
				#end
			case "chart":
				#if sys
				chartData = File.getContent(path);
				#end
			case "events":
				#if sys
				eventsData = File.getContent(path);
				#end
		}
	}
}

class ModernButton extends flixel.group.FlxSpriteGroup {
	public var bg:FlxSprite;
	public var label:FlxText;
	var onClick:Void->Void;

	public function new(x:Float, y:Float, text:String, color:Int, onClick:Void->Void) {
		super(x, y);
		this.onClick = onClick;

		bg = new FlxSprite().makeGraphic(320, 45, 0xFFFFFFFF);
		bg.color = color;
		bg.alpha = 0.8;
		add(bg);
		
		label = new FlxText(0, 0, 320, text, 14);
		label.setFormat(null, 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		label.y = (45 - label.height) / 2;
		add(label);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		#if haxe3ds
		if (HID.keyPressed(HIDKey.START)) {
			GFX.exit();
		}
		#end

		if (FlxG.mouse.overlaps(bg)) {
			bg.alpha = 1;
			if (FlxG.mouse.justPressed && active) {
				if (onClick != null) onClick();
			}
		} else {
			bg.alpha = 0.8;
		}
	}
}
