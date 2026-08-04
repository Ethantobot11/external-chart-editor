package;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if haxe3ds
import haxe3ds.services.HID;
import haxe3ds.services.GFX;
import citro.state.CitroState;
import citro.object.CitroText;
import citro.object.CitroSprite;
typedef BaseState = CitroState;
#else
import openfl.utils.ByteArray;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.net.FileFilter;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.addons.display.FlxGridOverlay;
typedef BaseState = FlxState;
#end

#if haxe3ds
@:headerInclude("3ds.h")
#end
class UploadState extends BaseState
{
	// Data Containers
	#if !haxe3ds
	var instData:ByteArray;
	var voicesData:ByteArray;
	var voicesOppData:ByteArray;
	#else
	var instData:String;
	var voicesData:String;
	var voicesOppData:String;
	#end
	var chartData:String;
	var eventsData:String;
	var customNotePath:String = "";

	// UI
	#if haxe3ds
	var statusText:CitroText;
	var browseListText:CitroText;
	#else
	var statusText:FlxText;
	var browseListText:FlxText;
	#end

	var btnContinue:Dynamic; // Handled per platform wrapper or conditional type
	
	// Logic
	#if !haxe3ds
	var _fileRef:FileReference;
	#end
	var _loadingType:String;

	// Directory Browsing State
	var isBrowsing:Bool = false;
	var filesList:Array<String> = [];
	var browseIndex:Int = 0;

	override function create()
	{
		super.create();

		#if haxe3ds
		// Citro 3DS Setup Initialization
		var bg = new CitroSprite(0, 0);
		bg.makeGraphic(400, 240, 0xFF1A1A1A);
		add(bg);

		var title = new CitroText(0, 10, "3DS Chart Editor Setup");
		title.screenCenterX();
		add(title);

		var startY = 45;
		var btnGap = 32;

		add(new CitroButton(50, startY, "Load Inst (.ogg)", 0xFF4488FF, function() { start3DSBrowsing("inst"); }));
		add(new CitroButton(50, startY + btnGap, "Load Voices (.ogg)", 0xFF44FF88, function() { start3DSBrowsing("voices"); }));
		add(new CitroButton(50, startY + (btnGap * 2), "Load Chart (.json)", 0xFFFFFF44, function() { start3DSBrowsing("chart"); }));
		add(new CitroButton(50, startY + (btnGap * 3), "Load Events (.json)", 0xFFDD44DD, function() { start3DSBrowsing("events"); }));

		statusText = new CitroText(0, 205, "Waiting for Inst...");
		statusText.screenCenterX();
		add(statusText);

		browseListText = new CitroText(0, 160, "");
		browseListText.screenCenterX();
		add(browseListText);

		btnContinue = new CitroButton(50, 210, "START EDITOR", 0xFF00CC00, function() {
			trace("Launching Editor on 3DS...");
		});
		btnContinue.active = false;
		btnContinue.alpha = 0.5;
		add(btnContinue);

		#else
		// PC / Mobile Flixel Setup Initialization
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1A1A1A);
		add(bg);
		var grid = FlxGridOverlay.create(40, 40, Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), true, 0x11FFFFFF, 0x00FFFFFF);
		add(grid);

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

		statusText = new FlxText(0, startY + (btnGap * 6), FlxG.width, "Waiting for Inst...", 16);
		statusText.alignment = CENTER;
		add(statusText);

		browseListText = new FlxText(0, startY + (btnGap * 5.7), FlxG.width, "", 14);
		browseListText.alignment = CENTER;
		browseListText.color = FlxColor.YELLOW;
		add(browseListText);

		btnContinue = new ModernButton(centerX - 150, FlxG.height - 80, "START EDITOR", 0xFF00CC00, function() {
			FlxG.switchState(new ChartEditor(instData, voicesData, voicesOppData, chartData, eventsData, customNotePath));
		});
		btnContinue.alpha = 0.5;
		btnContinue.active = false;
		add(btnContinue);
		#end
	}

	#if haxe3ds
	override function update(delta:Int) {
		super.update(delta);

		if (HID.keyPressed(HIDKey.START)) {
			GFX.exit();
		}

		if (isBrowsing) {
			if (HID.keyPressed(HIDKey.DUP) || HID.keyPressed(HIDKey.UP)) {
				browseIndex--;
				if (browseIndex < 0) browseIndex = filesList.length - 1;
				updateBrowseDisplay();
			}
			if (HID.keyPressed(HIDKey.DDOWN) || HID.keyPressed(HIDKey.DOWN)) {
				browseIndex++;
				if (browseIndex >= filesList.length) browseIndex = 0;
				updateBrowseDisplay();
			}
			if (HID.keyPressed(HIDKey.A)) {
				confirm3DSSelection();
			}
			if (HID.keyPressed(HIDKey.B)) {
				cancel3DSBrowsing();
			}
		}
	}
	#else
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (isBrowsing) {
			if (FlxG.keys.justPressed.UP) {
				browseIndex--;
				if (browseIndex < 0) browseIndex = filesList.length - 1;
				updateBrowseDisplay();
			}
			if (FlxG.keys.justPressed.DOWN) {
				browseIndex++;
				if (browseIndex >= filesList.length) browseIndex = 0;
				updateBrowseDisplay();
			}
			if (FlxG.keys.justPressed.ENTER) {
				confirm3DSSelection();
			}
			if (FlxG.keys.justPressed.ESCAPE) {
				cancel3DSBrowsing();
			}
		}
	}
	#end

	function loadFile(type:String) {
		_loadingType = type;

		#if haxe3ds
		start3DSBrowsing(type);
		#elseif ios
		var fileDialog = new FileDialog();
		fileDialog.onOpen.add(function(data:Dynamic) { processFileBytes(data); });
		fileDialog.onSelect.add(function(path:String) { processFilePath(path); });
		fileDialog.open((type == "chart" || type == "events") ? "json" : "ogg,mp3", null, "Select " + type);
		#elseif android
		var fileDialog = new FileDialog();
		fileDialog.onOpen.add(function(data:Dynamic) { processFileBytes(data); });
		fileDialog.onSelect.add(function(path:String) { processFilePath(path); });
		fileDialog.open((type == "chart" || type == "events") ? "json" : "ogg,mp3", null, "Select " + type);
		#else
		_fileRef = new FileReference();
		_fileRef.addEventListener(Event.SELECT, onFileSelect);
		var filterStr = (type == "chart" || type == "events") ? "*.json" : "*.ogg;*.mp3";
		_fileRef.browse([new FileFilter(type.toUpperCase(), filterStr)]);
		#end
	}

	function start3DSBrowsing(type:String) {
		#if sys
		var targetDir = "sdmc:/charts/";
		if (!FileSystem.exists(targetDir)) {
			try { FileSystem.createDirectory(targetDir); } catch(e:Dynamic) {}
			statusText.text = "Created 'sdmc:/charts/'. Put files there!";
			return;
		}

		filesList = [];
		for (file in FileSystem.readDirectory(targetDir)) {
			var lower = file.toLowerCase();
			if (type == "chart" || type == "events") {
				if (lower.endsWith(".json")) filesList.push(targetDir + file);
			} else {
				if (lower.endsWith(".ogg") || lower.endsWith(".mp3")) filesList.push(targetDir + file);
			}
		}

		if (filesList.length > 0) {
			isBrowsing = true;
			browseIndex = 0;
			updateBrowseDisplay();
		} else {
			statusText.text = "No files found in sdmc:/charts/";
			browseListText.text = "";
		}
		#end
	}

	function updateBrowseDisplay() {
		var fileName = filesList[browseIndex].split("/").pop();
		browseListText.text = "Browse " + _loadingType + " (" + (browseIndex + 1) + "/" + filesList.length + "):\n< " + fileName + " >";
		statusText.text = "";
	}

	function confirm3DSSelection() {
		if (filesList.length > 0 && browseIndex >= 0 && browseIndex < filesList.length) {
			var selectedPath = filesList[browseIndex];
			#if sys
			if (_loadingType == "chart" || _loadingType == "events") {
				assignData(File.getContent(selectedPath));
			} else {
				#if haxe3ds
				assignData(selectedPath);
				#else
				assignData(ByteArray.fromBytes(sys.io.File.getBytes(selectedPath)));
				#end
			}
			#end
		}
		isBrowsing = false;
		browseListText.text = "";
	}

	function cancel3DSBrowsing() {
		isBrowsing = false;
		browseListText.text = "";
		statusText.text = "Selection cancelled.";
	}

	#if (!ios && !android && !haxe3ds)
	function onFileSelect(e:Event) {
		_fileRef.removeEventListener(Event.SELECT, onFileSelect);
		_fileRef.addEventListener(Event.COMPLETE, onFileLoaded);
		_fileRef.load();
		statusText.text = "Loading " + _loadingType + "...";
	}

	function onFileLoaded(e:Event) {
		_fileRef.removeEventListener(Event.COMPLETE, onFileLoaded);
		assignData(_fileRef.data);
	}
	#end

	#if (ios || android)
	function processFileBytes(data:Dynamic) {
		var bytes:ByteArray = null;
		if (Std.isOfType(data, haxe.io.Bytes)) {
			bytes = ByteArray.fromBytes(cast data);
		}
		if (bytes != null) {
			if (_loadingType == "chart" || _loadingType == "events") {
				assignData(bytes.toString());
			} else {
				assignData(bytes);
			}
		}
	}

	function processFilePath(path:String) {
		if (_loadingType == "chart" || _loadingType == "events") {
			assignData(File.getContent(path));
		} else {
			assignData(ByteArray.fromBytes(File.getBytes(path)));
		}
	}
	#end

	function assignData(data:Dynamic) {
		switch(_loadingType) {
			case "inst":
				instData = data;
				statusText.text = "Instrumental Loaded!";
				btnContinue.active = true;
				btnContinue.alpha = 1;
			case "voices":
				voicesData = data;
				statusText.text = "Player Voices Loaded.";
			case "voices_opp":
				voicesOppData = data;
				statusText.text = "Opponent Voices Loaded.";
			case "chart":
				chartData = Std.string(data);
				statusText.text = "Chart Data Loaded.";
			case "events":
				eventsData = Std.string(data);
				statusText.text = "Events Data Loaded.";
		}
	}
}
