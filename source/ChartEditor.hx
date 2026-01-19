package;

typedef InitialPsychChartData = {
	var inst:ByteArray;
	var voicesPlayer:ByteArray;
	var voicesOpp:ByteArray;
	var chartData:String;
	var eventsData:String;
	var ?customNotePath:String;
}

typedef ToolbarButtonConfig = {
	var label:String;
	var callback:Void->Void;
	var ?color:FlxColor;
	var ?width:Float;
}

class ChartEditor extends FlxState
{
	public static var defaultNoteTypes:Array<String> = [
		'Normal',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];--
	var _song:SongData;
	var _psychChartData:InitialPsychChartData; 
	var _allNotes:Array<EditorNoteData> = [];
	var _fileRef:FileReference;
	var _loadingType:String = "";
	var audioTracks:Map<String, FlxSound> = new Map();
	var songLength:Float = 0;
	// Grid Settings
	public static var GRID_SIZE:Int = 40;
	var GRID_WIDTH_COLS:Int = 8; 
	var gridX:Float;
	var STRUM_LINE_Y:Float;
	
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	// Strum Lines
	public var strumLines:Array<EditorStrumLine> = [];
	public var eventStrums:Array<EditorStrumLine> = [];

	var curRenderedNotes:FlxTypedGroup<EditorNote>;
	var noteLabelsGroup:FlxTypedGroup<FlxText>;
	var sectionLinesGroup:FlxTypedGroup<FlxText>;
	var sectionSeparatorsGroup:FlxTypedGroup<FlxSprite>;
	public var uiScale:Float = 1.0;
	var topBarBG:FlxSprite;
	var infoTxt:FlxText;
	var playBtn:ArkButton;
	var scrollKnob:FlxSprite;
	var scrollBarBg:FlxSprite;
	var leftSideTxt:FlxText;
	var rightSideTxt:FlxText;

	var sectionInfoTxt:FlxText;
	var btnMustHit:ArkButton;
	var btnNoteType:ArkDropDown;
	var customNotesList:Array<String> = [];
	public var currentSnap:Int = 16;

	var curTime:Float = 0;
	var curSection:Int = 0;
	var stepMs:Float = 0;
	var isPlaying:Bool = false;
	var isDraggingBar:Bool = false;
	
	var ghostNote:FlxSprite;
	public var selectedNoteType:String = "Normal";
	var isHoldingNote:Bool = false;
	var targetNote:EditorNoteData = null;
	var initialTouchY:Float = 0;
	var initialNoteLength:Float = 0;
	var eventHoldTimer:Float = 0;
	var isHoldingEvent:Bool = false;

	public var bg:FlxSprite;
	public function new(inst:ByteArray, ?voices:ByteArray, ?voicesOpp:ByteArray, ?chart:String, ?events:String, ?customNotePath:String)
	{
		super();
		_psychChartData = {
			inst: inst,
			voicesPlayer: voices,
			voicesOpp: voicesOpp,
			chartData: chart,
			eventsData: events,
			customNotePath: customNotePath
		};
	}

	var noteFrames:FlxAtlasFrames;
	var hurtFrames:FlxAtlasFrames;

	override function create()
	{
		super.create();
		#if mobile
		uiScale = 1.4;
		#else
		uiScale = 1.0;
		#end

		FlxG.mouse.visible = true;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		_song = {
			song: "Test", bpm: 150, speed: 1.0,
			notes: [], events: [], needsVoices: true,
			player1: "bf", player2: "dad", gfVersion: "gf",
			beatsPerSection: 4
		};

		curRenderedNotes = new FlxTypedGroup<EditorNote>();
		noteLabelsGroup = new FlxTypedGroup<FlxText>(); 
		sectionLinesGroup = new FlxTypedGroup<FlxText>();
		sectionSeparatorsGroup = new FlxTypedGroup<FlxSprite>();

		setupAudio();
		loadCustomPsychNoteTypes();
		calculateStepMs();

		noteFrames = FlxAtlasFrames.fromSparrow("assets/images/NOTE_assets.png", "assets/images/NOTE_assets.xml");
		hurtFrames = FlxAtlasFrames.fromSparrow("assets/images/HURTNOTE_assets.png", "assets/images/HURTNOTE_assets.xml");

		bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, 0xFF111111);
		bg.scrollFactor.set(0, 0);
		add(bg);

		var totalGridWidth = GRID_SIZE * GRID_WIDTH_COLS;
		gridX = (FlxG.width - totalGridWidth) / 2;
		STRUM_LINE_Y = FlxG.height * 0.4;

		strumLines = [];
		eventStrums = [];

		var leftEvt = new EditorStrumLine(gridX - GRID_SIZE, STRUM_LINE_Y + 12.5, 1, -1, true, 0);
		eventStrums.push(leftEvt);
		var oppStrum = new EditorStrumLine(gridX, STRUM_LINE_Y + 12.5, 4, 0, false, 0);
		strumLines.push(oppStrum);
		var plrStrum = new EditorStrumLine(gridX + (GRID_SIZE * 4), STRUM_LINE_Y + 12.5, 4, 4, false, 1);
		strumLines.push(plrStrum);
		var rightEvt = new EditorStrumLine(gridX + totalGridWidth, STRUM_LINE_Y + 12.5, 1, -2, true, 1);
		eventStrums.push(rightEvt);

		add(rightEvt);
		add(plrStrum);
		add(oppStrum);
		add(leftEvt);

		add(sectionSeparatorsGroup);
		add(sectionLinesGroup);
		add(curRenderedNotes);
		add(noteLabelsGroup); 

		ghostNote = new FlxSprite();
		ghostNote.frames = noteFrames;
		ghostNote.animation.addByPrefix('purple', 'arrowLEFT');
		ghostNote.animation.addByPrefix('blue', 'arrowDOWN');
		ghostNote.animation.addByPrefix('green', 'arrowUP');
		ghostNote.animation.addByPrefix('red', 'arrowRIGHT');
		ghostNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
		ghostNote.updateHitbox();
		ghostNote.alpha = 0.6;
		add(ghostNote);
		FlxTween.tween(ghostNote, {alpha: 0.3}, 0.8, {type: PINGPONG});

		for (thing in strumLines) {
			thing.icon.scrollFactor.set(0, 0);
			thing.separator.scrollFactor.set(0, 0);
			for (curStrum in thing.strums) curStrum.scrollFactor.set(0, 0);
		}
		for (thing in eventStrums) {
			thing.separator.scrollFactor.set(0, 0);
			for (curStrum in thing.strums) curStrum.scrollFactor.set(0, 0);
		}

		var dimOverlay:FlxSprite = new FlxSprite(gridX - GRID_SIZE, Std.int(-STRUM_LINE_Y) - 2.5).makeGraphic(totalGridWidth + (GRID_SIZE * 2), Std.int(STRUM_LINE_Y) * 2, 0xFF000000);
		dimOverlay.alpha = 0.5;
		dimOverlay.scrollFactor.set(0, 0);
		add(dimOverlay);

		add(leftEvt.strums);
		add(leftEvt.icon);
		add(oppStrum.strums);
		add(oppStrum.icon);
		add(plrStrum.strums);
		add(plrStrum.icon);
		add(rightEvt.strums);
		add(rightEvt.icon);

		var strumLineIndicator:FlxSprite = new FlxSprite(gridX - GRID_SIZE, STRUM_LINE_Y - 9).makeGraphic(totalGridWidth + (GRID_SIZE * 2), 4, 0xFFFFFFFF);
		strumLineIndicator.scrollFactor.set(0,0);
		add(strumLineIndicator);

		setupUI();
		if (_psychChartData.chartData != null && _psychChartData.chartData.length > 0) {
			parsePsychChart(_psychChartData.chartData, _psychChartData.eventsData);
		} else {
			_song.notes = [];
			for(i in 0...1) {
				_song.notes.push({
					sectionNotes: [],
					lengthInSteps: 16,
					mustHitSection: false
				});
			}
			updateGrid();
		}
	}
	
	function setupAudio() {
		addAudioTrack("inst", _psychChartData.inst);
		addAudioTrack("voices_player", _psychChartData.voicesPlayer);
		addAudioTrack("voices_opp", _psychChartData.voicesOpp);
		if (audioTracks.exists("inst")) {
			songLength = audioTracks.get("inst").length;
		}
	}

	function addAudioTrack(key:String, bytes:ByteArray) {
		var sound = new FlxSound();
		if (bytes != null) {
			var s = new Sound();
			s.loadCompressedDataFromByteArray(bytes, bytes.length);
			sound.loadEmbedded(s);
		}
		FlxG.sound.list.add(sound);
		audioTracks.set(key, sound);
	}

	function loadCustomPsychNoteTypes() {
		customNotesList = defaultNoteTypes;
		var path = _psychChartData.customNotePath;
		
		if (path != null && path.length > 0) {
			trace("Attempting to load custom notes from: " + path);
			try {
				if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
					var files = FileSystem.readDirectory(path);
					for (file in files) {
						if (StringTools.endsWith(file, ".lua")) {
							var rawName = file.substr(0, file.length - 4);
							if (!customNotesList.contains(rawName)) {
								customNotesList.push(rawName);
								trace("Loaded Custom Note Type: " + rawName);
							}
						}
					}
				} else {
					trace("Custom note path directory does not exist or is invalid.");
				}
			} catch(e:Dynamic) {
				trace("Error loading custom notes: " + e);
			}
		}
	}
	
	public var buttons:Array<ToolbarButtonConfig> = [];
	function cycleSnap() {
		var snaps = [16, 12, 8, 4, 24, 32, 48, 64];
		var idx = snaps.indexOf(currentSnap);
		currentSnap = snaps[(idx + 1) % snaps.length];
	}

	function setupUI() {
		buttons = [
			{
				label: "Exit",
				color: 0xFFFF4444,
				callback: function() { FlxG.switchState(new UploadState());
				}
			},
			{
				label: "Save",
				callback: function() { savePsychChart(false); }
			},
			{
				label: "Meta",
				callback: function() {
					if(isPlaying) togglePlayback();
					openSubState(new SongMetadataSubState(_song, this));
				}
			},
			{
				label: "Play",
				color: FlxColor.GREEN,
				callback: togglePlayback
			},
			{
				label: "Snap",
				callback: cycleSnap
			},
			{
				label: "+", width: 40,
				callback: function() { camGame.zoom = Math.min(3, camGame.zoom + 0.1);
				}
			},
			{
				label: "-", width: 40,
				callback: function() { camGame.zoom = Math.max(0.5, camGame.zoom - 0.1); }
			}
		];
		var topBarHeight = 50 * uiScale;
		topBarBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(topBarHeight), 0xFF000000);
		topBarBG.alpha = 0.8;
		topBarBG.scrollFactor.set(0,0);
		topBarBG.cameras = [camHUD];
		add(topBarBG);
		var uiX:Float = 10 * uiScale;
		var uiY:Float = 14 * uiScale;
		for (btnConfig in buttons) {
			var w:Int = (btnConfig.width != null) ? Std.int(btnConfig.width) : 60;
			var btn = new ArkButton(uiX, uiY, w, 30, uiScale, btnConfig.label, btnConfig.callback, camHUD);
			
			if (btnConfig.color != null) btn.color = btnConfig.color;
			if (btnConfig.label == "Play") this.playBtn = btn;

			add(btn);
			uiX += w * uiScale;
		}

		btnNoteType = new ArkDropDown(uiX, uiY, 140, 30, uiScale, "Type", customNotesList, function(selected:String) {
			selectedNoteType = selected;
		}, camHUD);
		add(btnNoteType);
		uiX += (110 * uiScale);

		btnMustHit = new ArkButton(uiX, uiY, 120, 30, uiScale, "Must Hit: False", function() {
			toggleMustHitSection();
		}, camHUD);
		add(btnMustHit);

		var scrollBarWidth = 300 * uiScale;
		var scrollBarX = FlxG.width - scrollBarWidth - (10 * uiScale);
		scrollBarBg = new FlxSprite(scrollBarX, 15 * uiScale).makeGraphic(Std.int(scrollBarWidth), Std.int(20 * uiScale), FlxColor.GRAY);
		scrollBarBg.cameras = [camHUD]; add(scrollBarBg);
		scrollKnob = new FlxSprite(scrollBarX, 10 * uiScale).makeGraphic(Std.int(10 * uiScale), Std.int(30 * uiScale), FlxColor.WHITE);
		scrollKnob.cameras = [camHUD]; add(scrollKnob);
		infoTxt = new FlxText(FlxG.width - (190 * uiScale), (5 * uiScale) + 60, 180 * uiScale, "", Std.int(12 * uiScale));
		infoTxt.alignment = RIGHT; infoTxt.cameras = [camHUD]; add(infoTxt);

		sectionInfoTxt = new FlxText(gridX + (GRID_SIZE * GRID_WIDTH_COLS) + 60, STRUM_LINE_Y, 200, "Section Info", 16);
		sectionInfoTxt.scrollFactor.set(0,0);
		add(sectionInfoTxt);

		leftSideTxt = new FlxText(gridX - 200, FlxG.height / 2, 150, "Local Events\n(Only this Difficulty)");
		leftSideTxt.alignment = RIGHT; leftSideTxt.scrollFactor.set(0,0);
		add(leftSideTxt);

		rightSideTxt = new FlxText(gridX + (GRID_SIZE * GRID_WIDTH_COLS) + GRID_SIZE + 10, FlxG.height / 2, 150, "Global Events\n(All Difficulties)");
		rightSideTxt.alignment = LEFT; rightSideTxt.scrollFactor.set(0,0); add(rightSideTxt);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		handlePlayback(elapsed);
		var visualOffset:Float = 25;
		var gridOffset = ((curTime + visualOffset) / stepMs) * GRID_SIZE;

		camGame.scroll.set(0, gridOffset);
		
		for (line in strumLines) line.updateGridPosition(STRUM_LINE_Y, gridOffset);
		for (line in eventStrums) line.updateGridPosition(STRUM_LINE_Y, gridOffset);

		#if FLX_TOUCH
		handleTouchInput(elapsed);
		#end
		
		updateCurrentSection();
		updateNoteVisuals();
		updateGrid();
		updateScrollBar();
		updateInfoText();
	}


	function updateCurrentSection() {
		if (_song.notes == null) return;
		var msPerBeat = 60000 / _song.bpm;
		var msPerSection = msPerBeat * 4;
		var newSecIndex = Math.floor(curTime / msPerSection);
		if (newSecIndex < 0) newSecIndex = 0;
		while (newSecIndex >= _song.notes.length) {
			_song.notes.push({
				sectionNotes: [],
				lengthInSteps: 16,
				mustHitSection: false
			});
		}
		
		curSection = newSecIndex;
		if (btnMustHit != null) {
			var isMustHit = _song.notes[curSection].mustHitSection;
			btnMustHit.label.text = "Must Hit: " + (isMustHit ? "TRUE" : "FALSE");
			btnMustHit.bg.color = isMustHit ? 0xFF44FF44 : 0xFFAA4444;
		}

		if (btnNoteType != null) {
			btnNoteType.headerBtn.label.text = "Type: " + selectedNoteType;
		}

		sectionInfoTxt.text = "Section: " + curSection + "\nMust Hit: " + _song.notes[curSection].mustHitSection;
	}

	function toggleMustHitSection() {
		if (_song.notes != null && curSection < _song.notes.length) {
			_song.notes[curSection].mustHitSection = !_song.notes[curSection].mustHitSection;
		}
	}
	
	function handlePlayback(elapsed:Float) {
		if (!isPlaying) return;
		var inst = audioTracks.get("inst");

		if (inst != null && inst.playing) {
			if (inst.time >= inst.length) {
				togglePlayback();
				curTime = inst.length;
				return;
			}
			
			curTime = inst.time;
			syncVocals();
		} else {
			curTime += elapsed * 1000;
			if(curTime > songLength && songLength > 0) togglePlayback();
		}
	}


	#if FLX_TOUCH
	function handleTouchInput(elapsed:Float) {
		if (isPlaying || isDraggingBar) return;
		if (btnNoteType.isOpen) {
			for (touch in FlxG.touches.list) {
				if (touch.justPressed) {
					if (touch.overlaps(btnNoteType, camHUD)) return;
				}
			}
		}

		for (touch in FlxG.touches.list) if (touch.overlaps(topBarBG, camHUD)) return;

		var touchStartTime:Float = 0;
		var moveThreshold = 10;

		var touch = FlxG.touches.getFirst();
		if (touch == null) return;
		var worldPos = touch.getWorldPosition(camGame);
		var worldX = worldPos.x;
		var worldY = worldPos.y;
		var screenPos = touch.getScreenPosition(camHUD);

		updateGhostNoteState(worldX, worldY);
		var buttonAdded:Bool = false;
		
		if (touch.justPressed) {
			targetNote = getNoteAtPos(worldX, worldY);
			if (targetNote != null) {
				if (targetNote.column == -1 || targetNote.column == -2) {
					isHoldingEvent = true;
					eventHoldTimer = 0;
				} else {
					isHoldingNote = true;
					initialTouchY = worldY;
					initialNoteLength = targetNote.length;
				}
			} else {
				buttonAdded = true;
				addNoteAtPos(worldX, worldY);
				isHoldingNote = false;
			}
		}

		if (touch.pressed) {
			if (targetNote != null) touchStartTime += elapsed;

			if (isHoldingEvent) {
				eventHoldTimer += elapsed;
				if (eventHoldTimer > 0.4) {
					isHoldingEvent = false;
					openSubState(new EventOptionSubState(targetNote, screenPos.x, screenPos.y,
					function() { openSubState(new EventEditorSubState(targetNote, function() { updateGrid(); })); },
					function() { _allNotes.remove(targetNote); updateGrid(); }));
				}
			}
			else if (isHoldingNote && targetNote != null && targetNote.column != -1 && targetNote.column != -2) {
				if (Math.abs(worldY - initialTouchY) > moveThreshold || touchStartTime > 0.4) {
					var diffY = worldY - initialTouchY;
					var rawLengthMs = (diffY / GRID_SIZE) * stepMs;
					var snapValue = 16.0 / currentSnap;
					var snapMs = stepMs * snapValue;
					var snappedLength = Math.round((initialNoteLength + rawLengthMs) / snapMs) * snapMs;
					if (snappedLength < 0) snappedLength = 0;
					targetNote.length = snappedLength;
					updateGrid();
				}
			}
		}

		if (touch.justReleased) {
			if (targetNote != null && !(Math.abs(worldY - initialTouchY) > moveThreshold || touchStartTime > 0.4) && touchStartTime < 0.4 && !isHoldingEvent && eventHoldTimer < 0.4 && !buttonAdded) {
				 _allNotes.remove(targetNote);
				updateGrid();
			}
			isHoldingEvent = false;
			eventHoldTimer = 0;
			isHoldingNote = false;
			targetNote = null;
		}
	}
	#end

	var lastGhostCol:Int = -999;
	
	function getColumnFromX(worldX:Float):Int {
		for (line in eventStrums) {
			if (worldX >= line.x && worldX < line.x + (line.laneCount * GRID_SIZE)) {
				var localCol = Math.floor((worldX - line.x) / GRID_SIZE);
				return line.startColumn + localCol;
			}
		}
		for (line in strumLines) {
			if (worldX >= line.x && worldX < line.x + (line.laneCount * GRID_SIZE)) {
				var localCol = Math.floor((worldX - line.x) / GRID_SIZE);
				return line.startColumn + localCol;
			}
		}
		return -999;
	}

	function updateGhostNoteState(worldX:Float, worldY:Float) {
		var col = getColumnFromX(worldX);
		if (EditorPrefs.ghostModeEnabled && !isHoldingNote && col != -999) {
			ghostNote.visible = true;

			var relativeY = worldY - STRUM_LINE_Y;
			var snapRatio = 16.0 / currentSnap;
			var snapHeight = GRID_SIZE / snapRatio;
			var gridRow = Math.floor(relativeY / snapHeight);
			var perfectY = STRUM_LINE_Y + (gridRow * snapHeight);
			
			var targetX:Float = 0;
			if(col == -1) targetX = eventStrums[0].x;
			else if(col == -2) targetX = eventStrums[1].x;
			else if(col < 4) targetX = strumLines[0].x + (col * GRID_SIZE);
			else targetX = strumLines[1].x + ((col - 4) * GRID_SIZE);

			ghostNote.x = targetX;
			ghostNote.y = perfectY;
			if (col == -1 || col == -2) {
				ghostNote.frames = null;
				ghostNote.loadGraphic("assets/images/eventArrow.png");
				if(col == -2) ghostNote.color = 0xFF00FFFF;
				else ghostNote.color = 0xFFFFFFFF;
			} else {
				var atlas = FlxAtlasFrames.fromSparrow("assets/images/NOTE_assets.png", "assets/images/NOTE_assets.xml");
				ghostNote.frames = atlas;
				ghostNote.color = 0xFFFFFFFF;
				ghostNote.animation.addByPrefix('purple', 'arrowLEFT');
				ghostNote.animation.addByPrefix('blue', 'arrowDOWN');
				ghostNote.animation.addByPrefix('green', 'arrowUP');
				ghostNote.animation.addByPrefix('red', 'arrowRIGHT');
			}

			if (col != -1 && col != -2) {
				var dir = col % 4;
				switch(dir) {
					case 0: ghostNote.animation.play('purple');
					case 1: ghostNote.animation.play('blue');
					case 2: ghostNote.animation.play('green');
					case 3: ghostNote.animation.play('red');
				}
			}
			ghostNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
			ghostNote.updateHitbox();
		} else {
			ghostNote.visible = false;
		}
	}

	function calculateStepMs() {
		if (_song.bpm > 0) stepMs = (60000 / _song.bpm) / 4;
		else stepMs = 100;
	}

	function updateInfoText() {
		var curTimeStr = formatTime(curTime);
		var totalTimeStr = formatTime((songLength > 0) ? songLength : 0);
		var curStep = Math.floor(curTime / stepMs);
		var curBeat = Math.floor(curStep / 4);
		infoTxt.text = '${curTimeStr} / ${totalTimeStr}\nStep: ${curStep}\nBeat: ${curBeat}\nBPM: ${_song.bpm}\nSnap: 1/$currentSnap';
	}

	function formatTime(ms:Float):String {
		var totalSeconds = Math.floor(ms / 1000);
		var minutes = Math.floor(totalSeconds / 60);
		var seconds = totalSeconds % 60;
		var milliseconds = Math.floor(ms % 1000);
		return StringTools.lpad(Std.string(minutes), "0", 2) + ":" +
			   StringTools.lpad(Std.string(seconds), "0", 2) + "." +
			   StringTools.lpad(Std.string(milliseconds), "0", 3);
	}

	function updateNoteVisuals() {
		curRenderedNotes.forEachAlive(function(note:EditorNote) {
			if (isPlaying && !note.isEvent) {
				var noteStart = note.data.time;
				var noteEnd = note.data.time + note.data.length;
				var isInsideHold = (note.data.length > 0 && curTime >= noteStart && curTime <= noteEnd);
				var isHitMoment = (Math.abs(noteStart - curTime) < 20);

				if (isHitMoment || isInsideHold) {
					var strumIdx = note.data.column;
					var targetLine:EditorStrumLine = null;
					var localIdx = 0;
					
					if (strumIdx < 4) { targetLine = strumLines[0]; localIdx = strumIdx; }
					else { targetLine = strumLines[1]; localIdx = strumIdx - 4; }

					if (targetLine != null && targetLine.strums.members.length > localIdx) {
						var strum = targetLine.strums.members[localIdx];
						if (strum != null) strum.playAnim('confirm', false);
						if (EditorPrefs.hitSound && !isInsideHold) FlxG.sound.play('assets/sounds/hitsound.ogg').pan = 0.3;
					}
				}
			}
	
			if (note.y + note.height < STRUM_LINE_Y) {
				note.alpha = 0.4;
				if (note.sustainPiece != null) note.sustainPiece.alpha = 0.4;
				if (note.sustainEnd != null) note.sustainEnd.alpha = 0.4;
			} else {
				note.alpha = 1.0;
				if (note.sustainPiece != null) note.sustainPiece.alpha = 0.6;
				if (note.sustainEnd != null) note.sustainEnd.alpha = 0.6;
			}
		});
	}

	function updateScrollBar() {
		var barWidth = scrollBarBg.width;
		var barX = scrollBarBg.x;
		var maxTime = (songLength > 0) ? songLength : 1;
		#if mobile
		for(touch in FlxG.touches.list) {
			if(touch.justPressed && touch.overlaps(scrollBarBg, camHUD)) {
				isDraggingBar = true;
				if(isPlaying) togglePlayback();
			}
		}
		#end
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(scrollBarBg, camHUD)) {
			isDraggingBar = true;
			if(isPlaying) togglePlayback();
		}

		if (FlxG.mouse.released #if mobile || (FlxG.touches.getFirst() != null && FlxG.touches.getFirst().justReleased) #end) isDraggingBar = false;
		
		if (isDraggingBar) {
			var mouseX:Float = 0;
			#if mobile
			var t = FlxG.touches.getFirst();
			if(t != null) mouseX = t.getScreenPosition(camHUD).x;
			else mouseX = FlxG.mouse.getScreenPosition(camHUD).x;
			#else
			mouseX = FlxG.mouse.getScreenPosition(camHUD).x;
			#end

			var percent = (mouseX - barX) / barWidth;
			percent = FlxMath.bound(percent, 0, 1);
			curTime = percent * maxTime;
			var inst = audioTracks.get("inst");
			var voices_player = audioTracks.get("voices_player");
			var voices_opp = audioTracks.get("voices_opp");
			if (inst != null && curTime < inst.length) inst.time = curTime;
			if (voices_player != null && curTime < voices_player.length) voices_player.time = curTime;
			if (voices_opp != null && curTime < voices_opp.length) voices_opp.time = curTime;
			updateGrid();
		}

		var percent = curTime / maxTime;
		scrollKnob.x = barX + (percent * (barWidth - scrollKnob.width));
	}
	
	function getNoteAtPos(worldX:Float, worldY:Float):EditorNoteData {
		var col = getColumnFromX(worldX);
		if (col == -999) return null;

		for (n in _allNotes) {
			var noteY = STRUM_LINE_Y + (n.time / stepMs) * GRID_SIZE;
			var visualTop = noteY;
			var tailHeight = (n.length / stepMs) * GRID_SIZE;
			var visualBottom = noteY + GRID_SIZE + tailHeight;
			if (n.column == col && worldY >= visualTop && worldY <= visualBottom) {
				return n;
			}
		}
		return null;
	}

	function addNoteAtPos(worldX:Float, worldY:Float) {
		var col = getColumnFromX(worldX);
		if (col == -999) return;

		var relativeY = worldY - STRUM_LINE_Y;
		var snapRatio = 16.0 / currentSnap;
		var snapHeight = GRID_SIZE / snapRatio;
		var gridRow = Math.floor(relativeY / snapHeight);
		var timePerPixel = stepMs / GRID_SIZE;
		var exactTime = relativeY * timePerPixel;
		var msPerSnap = stepMs / snapRatio;
		var snappedTime = Math.floor(exactTime / msPerSnap) * msPerSnap;

		if (snappedTime < 0) snappedTime = 0;
		var type = (col == -1 || col == -2) ? "Event" : selectedNoteType;
		_allNotes.push(new EditorNoteData(snappedTime, col, 0, type));
		_allNotes.sort(function(a, b) return Std.int(a.time - b.time));
		updateGrid();
	}

	public function savePsychChart(?isGlobalEvents:Bool) {
		var msPerBeat = 60000 / _song.bpm;
		
		var lastNoteTime = 0.0;
		for(n in _allNotes) if(n.time > lastNoteTime) lastNoteTime = n.time;
		var songEndMs = (songLength > 0) ? songLength : lastNoteTime;
		if (songEndMs > lastNoteTime) lastNoteTime = songEndMs;
		
		var savedEvents:Array<Dynamic> = [];
		var savedGlobalEvents:Array<Dynamic> = [];
		for (sec in _song.notes) sec.sectionNotes = [];
		
		var msPerSection = msPerBeat * 4;
		for (n in _allNotes) {
			if (n.column == -1) {
				savedEvents.push([n.time, [[n.noteType, n.eventVal1, n.eventVal2]]]);
			}
			else if (n.column == -2) {
				savedGlobalEvents.push([n.time, [[n.noteType, n.eventVal1, n.eventVal2]]]);
			}
			else {
				var secIdx = Math.floor(n.time / msPerSection);
				while (secIdx >= _song.notes.length) {
					_song.notes.push({sectionNotes:[], lengthInSteps:16, mustHitSection:false});
				}
				
				var saveCol = n.column;
				var mustHit = _song.notes[secIdx].mustHitSection;
				
				var finalDataCol = n.column;
				if (mustHit) {
					if (n.column >= 4) finalDataCol = n.column - 4;
					else finalDataCol = n.column + 4;
				}
				
				var noteArr:Array<Dynamic> = [n.time, finalDataCol, n.length];
				if (n.noteType != "Normal") noteArr.push(n.noteType);
				
				_song.notes[secIdx].sectionNotes.push(noteArr);
			}
		}

		_song.events = savedEvents;
		var songJson = { "song": _song };
		var songDataStr = Json.stringify(songJson, "\t");
		var eventsJson = { "song": { "events": savedGlobalEvents } };
		var eventsDataStr = Json.stringify(eventsJson, "\t");
		if (isGlobalEvents) {
			var fr2 = new FileReference();
			fr2.save(eventsDataStr, "events.json");
		} else {
			var fr = new FileReference();
			fr.save(songDataStr, _song.song.toLowerCase() + ".json");
			try {
				File.saveContent(Sys.getCwd() + 'saves/' + _song.song + '.json', songDataStr);
			} catch(e:Dynamic) {}
		}
	}

	function parsePsychChart(jsonString:String, ?eventsString:String) {
		var raw = Json.parse(jsonString);
		var songObj:Dynamic = Reflect.hasField(raw, "song") ? raw.song : raw;

		_song.song = songObj.song;
		_song.bpm = songObj.bpm;
		if(Reflect.hasField(songObj, "speed")) _song.speed = songObj.speed;
		if(Reflect.hasField(songObj, "player1")) _song.player1 = songObj.player1;
		if(Reflect.hasField(songObj, "player2")) _song.player2 = songObj.player2;
		if(Reflect.hasField(songObj, "gfVersion")) _song.gfVersion = songObj.gfVersion;
		if(Reflect.hasField(songObj, "needsVoices")) _song.needsVoices = songObj.needsVoices;
		if(Reflect.hasField(songObj, "beatsPerSection")) _song.beatsPerSection = songObj.beatsPerSection;
		
		calculateStepMs();
		_allNotes = [];
		var sections:Array<Dynamic> = songObj.notes;
		
		_song.notes = [];
		if (sections != null && jsonString != null) {
			for (sec in sections) {
				var newSec:SectionData = {
					sectionNotes: [],
					lengthInSteps: sec.lengthInSteps != null ?
					sec.lengthInSteps : 16,
					mustHitSection: sec.mustHitSection
				};
				_song.notes.push(newSec);
				
				var mustHit = (sec.mustHitSection == true);
				for (n in (sec.sectionNotes : Array<Dynamic>)) {
					var t:Float = n[0];
					var d:Int = n[1];
					var l:Float = n[2];
					var type:String = "Normal";
					if (n.length > 3 && n[3] != null) type = n[3];

					var finalCol = d;
					if (d > -1) {
						if (mustHit) {
							if (d < 4) finalCol = d + 4;
							else finalCol = d - 4;
						}
					}
					_allNotes.push(new EditorNoteData(t, finalCol, l, type));
				}
			}
		}
		
		if (songObj.events != null) {
			var events:Array<Dynamic> = songObj.events;
			for (e in events) {
				var t:Float = e[0];
				var subEvents:Array<Dynamic> = e[1];
				for (sub in subEvents) {
					var name = sub[0];
					var val1 = sub[1];
					var val2 = sub[2];
					var newNote = new EditorNoteData(t, -1, 0, name);
					newNote.eventVal1 = val1;
					newNote.eventVal2 = val2;
					_allNotes.push(newNote);
				}
			}
		}
		
		if (eventsString != null && eventsString.length > 0) {
			var eJson = Json.parse(eventsString);
			var eventsRaw:Array<Dynamic> = Reflect.hasField(eJson, "song") ? eJson.song.events : eJson.events;
			if (eventsRaw != null) {
				for (e in eventsRaw) {
					var t:Float = e[0];
					var subEvents:Array<Dynamic> = e[1];
					for (sub in subEvents) {
						var name = sub[0];
						var val1 = sub[1];
						var val2 = sub[2];
						var newNote = new EditorNoteData(t, -2, 0, name);
						newNote.eventVal1 = val1;
						newNote.eventVal2 = val2;
						_allNotes.push(newNote);
					}
				}
			}
		}

		_allNotes.sort(function(a, b) return Std.int(a.time - b.time));
		updateGrid();
	}

	function togglePlayback() {
		isPlaying = !isPlaying;
		var inst = audioTracks.get("inst");
		if (inst == null) return;

		if (isPlaying) {
			if (playBtn != null) playBtn.label.text = "Pause";
			inst.time = curTime;
			inst.play();
			for (key in audioTracks.keys()) {
				if (key != "inst") {
					var v = audioTracks.get(key);
					if (v.exists) { v.time = curTime; v.play();
					}
				}
			}
		} else {
			if (playBtn != null) playBtn.label.text = "Play";
			for (snd in audioTracks) snd.pause();
		}
	}

	function syncVocals() {
		var inst = audioTracks.get("inst");
		for (key in audioTracks.keys()) {
			if (key == "inst") continue;
			var v = audioTracks.get(key);
			if (v.exists && v.playing && Math.abs(v.time - inst.time) > 20) {
				v.time = inst.time;
			}
		}
	}
	
	function findStartIndex(time:Float):Int {
		var start = 0;
		var end = _allNotes.length - 1;
		var result = 0;

		while (start <= end) {
			var mid = Math.floor((start + end) / 2);
			if (_allNotes[mid].time + _allNotes[mid].length >= time) {
				result = mid;
				end = mid - 1;
			} else {
				start = mid + 1;
			}
		}
		return result;
	}

	public function changeStaticStrumVisibilty(value:Bool) {
		if (strumLines != null) {
			for (line in strumLines) {
				for (strum in line.strums) {
					if(strum != null) strum.visible = value;
				}
			}
		}
		if (eventStrums != null) {
			for (line in eventStrums) {
				for (strum in line.strums) {
					if(strum != null) strum.visible = value;
				}
			}
		}
	}

	public function updateGrid() {
		curRenderedNotes.forEachAlive(function(note:EditorNote) note.kill());
		noteLabelsGroup.forEachAlive(function(txt:FlxText) txt.kill());
		sectionLinesGroup.forEachAlive(function(txt:FlxText) txt.kill());
		sectionSeparatorsGroup.forEachAlive(function(spr:FlxSprite) spr.kill());

		var renderEndTime = curTime - 200 - EditorPrefs.noteDespawnOffset;
		var renderStartTime = curTime + 2000;

		if (EditorPrefs.showSectionLines != false) {
			var beats = (_song.beatsPerSection != null && _song.beatsPerSection > 0) ? _song.beatsPerSection : 4;
			var beatMs = 60000 / _song.bpm;
			var sectionMs = beatMs * beats;

			var startSectionIdx = Math.floor(renderEndTime / sectionMs);
			if (startSectionIdx < 0) startSectionIdx = 0;
			var endSectionIdx = Math.ceil(renderStartTime / sectionMs);

			for (i in startSectionIdx...endSectionIdx + 1) {
				var secTime = i * sectionMs;
				var secY = STRUM_LINE_Y + (secTime / stepMs) * GRID_SIZE;

				var line:FlxSprite = sectionSeparatorsGroup.recycle(FlxSprite);
				line.makeGraphic((GRID_SIZE * (GRID_WIDTH_COLS + 1)) + GRID_SIZE, 2, 0xFFFFFFFF);
				line.x = gridX - GRID_SIZE;
				line.y = secY;
				line.alpha = 0.5;
				sectionSeparatorsGroup.add(line);
				
				var num:FlxText = sectionLinesGroup.recycle(FlxText);
				num.text = Std.string(i);
				num.size = 12;
				num.x = gridX - GRID_SIZE - 30;
				num.y = secY - 10;
				num.alignment = RIGHT;
				num.alpha = 1;
				sectionLinesGroup.add(num);
			}
		}

		var startIndex = findStartIndex(renderEndTime);

		for (i in startIndex..._allNotes.length) {
			var n = _allNotes[i];

			if (n.time > renderStartTime) break;

			var nX:Float = 0;
			if(n.column == -1) nX = eventStrums[0].x;
			else if(n.column == -2) nX = eventStrums[1].x;
			else if(n.column < 4) nX = strumLines[0].x + (n.column * GRID_SIZE);
			else nX = strumLines[1].x + ((n.column - 4) * GRID_SIZE);

			var nY = STRUM_LINE_Y + (n.time / stepMs) * GRID_SIZE;

			var newNote:EditorNote = curRenderedNotes.recycle(EditorNote);
			
			newNote.reload(nX, nY, n, GRID_SIZE, noteFrames, hurtFrames, _psychChartData.customNotePath);
			
			newNote.updateTail(stepMs);
			curRenderedNotes.add(newNote);

			if (n.noteType != "Normal" && customNotesList.contains(n.noteType)) {
				var idx = customNotesList.indexOf(n.noteType);
				var label = noteLabelsGroup.recycle(FlxText);
				
				label.x = nX;
				label.y = nY + (GRID_SIZE / 2) - 10;
				label.fieldWidth = GRID_SIZE;
				label.text = Std.string(idx);
				label.setFormat(null, 20, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
				label.alpha = 1;
				
				noteLabelsGroup.add(label);
			}
		}
	}
}