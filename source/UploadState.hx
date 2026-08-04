package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.addons.display.FlxGridOverlay;
import openfl.utils.ByteArray;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.net.FileFilter;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;

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
	// Data Containers
	var instData:ByteArray;
	var voicesData:ByteArray;
	var voicesOppData:ByteArray;
	var chartData:String;
	var eventsData:String;
	var customNotePath:String = "";

	// UI
	var statusText:FlxText;
	var btnContinue:ModernButton;
	
	// Logic
	var _fileRef:FileReference;
	var _loadingType:String;

	// 3DS Directory Browsing State
	var isBrowsing:Bool = false;
	var filesList:Array<String> = [];
	var browseIndex:Int = 0;
	var browseListText:FlxText;

	override function create()
	{
		super.create();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1A1A1A);
		add(bg);
		var grid = FlxGridOverlay.create(40, 40, Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), true, 0x11FFFFFF, 0x00FFFFFF);
		add(grid);
		
		var titleString = "Chart Editor Setup";
		#if haxe3ds
		titleString = "3DS Chart Editor Setup";
		#end

		var title = new FlxText(0, 40, FlxG.width, titleString, 32);
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

		add(new ModernButton(centerX - 150, startY + (btnGap * 5), "Custom Notes (Folder)", 0xFFAA44AA, function() {
			#if ios
			customNotePath = lime.system.System.documentsDirectory + "/CustomNotes";
			if (!FileSystem.exists(customNotePath)) {
				FileSystem.createDirectory(customNotePath);
			}
			statusText.text = "Using App Documents Folder";
			trace("Custom Note Path: " + customNotePath);
			#elseif haxe3ds
			customNotePath = "sdmc:/CustomNotes";
			if (!FileSystem.exists(customNotePath)) {
				FileSystem.createDirectory(customNotePath);
			}
			statusText.text = "Using 3DS CustomNotes Folder";
			#else
			var fileDialog = new FileDialog();
			fileDialog.onSelect.add(function(path:String) { 
				customNotePath = path;
				statusText.text = "Custom Notes Path Set:\n" + path;
			});
			fileDialog.browse(FileDialogType.OPEN_DIRECTORY);
			#end
		}));

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
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		#if haxe3ds
		if (HID.keyPressed(HIDKey.START)) {
			GFX.exit();
		}
		#end
		if (isBrowsing) {
			#if haxe3ds
			if (HID.keyPressed(HIDKey.DUP) || HID.keyPressed(HIDKey.L_UP)) {
				browseIndex--;
				if (browseIndex < 0) browseIndex = filesList.length - 1;
				updateBrowseDisplay();
			}
			if (HID.keyPressed(HIDKey.DDOWN) || HID.keyPressed(HIDKey.L_DOWN)) {
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
			#else
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
			#end
		}
	}

	function loadFile(type:String) {
		_loadingType = type;

		#if haxe3ds
		start3DSBrowsing(type);
		#elseif ios
		var fileDialog = new FileDialog();
		
		fileDialog.onOpen.add(function(data:Dynamic) {
			processFileBytes(data);
		});

		fileDialog.onSelect.add(function(path:String) {
			processFilePath(path);
		});

		fileDialog.onCancel.add(function() {
			statusText.text = "Selection cancelled.";
		});

		var filterStr = (type == "chart" || type == "events") ? "json" : "ogg,mp3";
		fileDialog.open(filterStr, null, "Select " + type);
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
			try {
				FileSystem.createDirectory(targetDir);
			} catch(e:Dynamic) {}
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
			statusText.text = "No matching files found in sdmc:/charts/";
			browseListText.text = "";
		}
		#end
	}

	function updateBrowseDisplay() {
		var fileName = filesList[browseIndex].split("/").pop();
		browseListText.text = "Browsing " + _loadingType + " (" + (browseIndex + 1) + "/" + filesList.length + "):\n< " + fileName + " >\n[A/Enter to Confirm, B/Esc to Cancel]";
		statusText.text = "";
	}

	function confirm3DSSelection() {
		if (filesList.length > 0 && browseIndex >= 0 && browseIndex < filesList.length) {
			var selectedPath = filesList[browseIndex];
			#if sys
			if (_loadingType == "chart" || _loadingType == "events") {
				assignData(File.getContent(selectedPath));
			} else {
				assignData(ByteArray.fromFile(selectedPath));
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

	#if !ios
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

	#if ios
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
			var content = File.getContent(path);
			assignData(content);
		} else {
			var bytes = File.getBytes(path);
			assignData(ByteArray.fromBytes(bytes));
		}
	}
	#end

	function assignData(data:Dynamic) {
		switch(_loadingType) {
			case "inst":
				instData = data;
				statusText.text = "Instrumental Loaded!";
				statusText.color = FlxColor.CYAN;
				btnContinue.active = true;
				btnContinue.alpha = 1;
			case "voices":
				voicesData = data;
				statusText.text = "Player Voices Loaded.";
			case "voices_opp":
				voicesOppData = data;
				statusText.text = "Opponent Voices Loaded.";
			case "chart":
				if (Std.isOfType(data, haxe.io.Bytes))
					chartData = (cast data : ByteArray).toString();
				else
					chartData = Std.string(data);
				statusText.text = "Chart Data Loaded.";
			case "events":
				if (Std.isOfType(data, haxe.io.Bytes))
					eventsData = (cast data : ByteArray).toString();
				else
					eventsData = Std.string(data);
				statusText.text = "Events Data Loaded.";
		}
	}
}

class ModernButton extends flixel.group.FlxSpriteGroup {
	public var bg:FlxSprite;
	public var label:FlxText;
	var onClick:Void->Void;
	var baseColor:Int;

	public function new(x:Float, y:Float, text:String, color:Int, onClick:Void->Void) {
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

	override function update(elapsed:Float) {
		super.update(elapsed);
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
