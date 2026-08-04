package;

#if haxe3ds
import citro.object.CitroSprite;
import citro.object.CitroAnimate;
#end

typedef SongData = {
	var song:String;
	var bpm:Float;
	var speed:Float;
	var notes:Array<SectionData>;
	var events:Array<Dynamic>;
	var needsVoices:Bool;
	var player1:String;
	var player2:String;
	@:optional var gfVersion:String;
	@:optional var beatsPerSection:Int;
}

typedef SectionData = {
	var sectionNotes:Array<Array<Dynamic>>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
}

class EditorNoteData {
	public var time:Float;
	public var column:Int;
	public var length:Float;
	public var noteType:String;
	public var eventVal1:String = "";
	public var eventVal2:String = "";

	public function new(t:Float, c:Int, l:Float, type:String = "Normal") {
		time = t;
		column = c;
		length = l;
		noteType = type;
	}
}

class EditorStrum extends #if !haxe3ds FlxSprite #else CitroAnimate #end {
	public var resetTimer:Float = 0;
	public var colIdx:Int = 0;
	public var isEventStrum:Bool = false;

	public function new(x:Float, y:Float, colIdx:Int, gridSize:Int, isEvent:Bool = false) {
		#if haxe3ds
		// 3DS uses CitroAnimate passing the .t3x sheet and .cea map generated from xml
		super("romfs:/assets/images/NOTE_assets.t3x", "static", "romfs:/assets/images/NOTE_assets.cea");
		#else
		super(x, y);
		#end

		this.x = x;
		this.y = y;
		this.colIdx = colIdx;
		this.isEventStrum = isEvent;

		if (isEventStrum) {
			#if haxe3ds
			loadGraphic("romfs:/assets/images/eventArrow.t3x");
			#else
			loadGraphic("assets/images/eventArrow.png");
			#end
			setGraphicSize(gridSize, gridSize);
			updateHitbox();
		} else {
			#if !haxe3ds
			var atlas = FlxAtlasFrames.fromSparrow("assets/images/NOTE_assets.png", "assets/images/NOTE_assets.xml");
			frames = atlas;
			antialiasing = true;
			switch (colIdx % 4) {
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
			setGraphicSize(gridSize, gridSize);
			updateHitbox();
			playAnim('static');
			#else
			var animPrefix = switch (colIdx % 4) {
				case 0: "arrowLEFT";
				case 1: "arrowDOWN";
				case 2: "arrowUP";
				case _: "arrowRIGHT";
			};
			play(animPrefix);
			scale.set(gridSize / width, gridSize / height);
			updateHitbox();
			#end
		}
	}

	public function playAnim(animName:String, force:Bool = false) {
		if (isEventStrum) return;
		#if !haxe3ds
		animation.play(animName, force);
		centerOffsets();
		centerOrigin();
		#else
		play(animName);
		#end
		if (animName == 'confirm') resetTimer = 0.15;
		else resetTimer = 0;
	}

	override function update(#if haxe3ds delta:Int #else elapsed:Float #end) {
		super.update(#if !haxe3ds elapsed #end);
		if (resetTimer > 0) {
			resetTimer -= elapsed;
			if (resetTimer <= 0) playAnim('static');
		}
	}
}

class EditorNote extends #if !haxe3ds FlxSprite #else CitroAnimate #end {
	public var data:EditorNoteData;
	#if !haxe3ds
	public var sustainPiece:FlxSprite;
	public var sustainEnd:FlxSprite;
	#else
	public var sustainPiece:CitroAnimate;
	public var sustainEnd:CitroAnimate;
	#end
	var gridSize:Int;
	public var isEvent:Bool = false;

	public function new(x:Float, y:Float, data:EditorNoteData, gridSize:Int, ?customNotePath:String) {
		#if haxe3ds
		super("romfs:/assets/images/NOTE_assets.t3x", "scroll", "romfs:/assets/images/NOTE_assets.cea");
		#else
		super(x, y);
		sustainPiece = new FlxSprite();
		sustainEnd = new FlxSprite();
		#end
		this.x = x;
		this.y = y;
	}
	
	public function reload(x:Float, y:Float, data:EditorNoteData, gridSize:Int, 
						   cachedFrames:Dynamic, cachedHurtFrames:Dynamic, 
						   ?customNotePath:String) {
		this.x = x;
		this.y = y;
		this.data = data;
		this.gridSize = gridSize;
		this.alpha = 1;
		this.visible = true;

		this.isEvent = (data.column == -1 || data.column == -2 || data.column == 8);

		this.color = 0xFFFFFFFF;
		this.scale.set(1,1);
		
		if (isEvent) {
			#if haxe3ds
			loadGraphic("romfs:/assets/images/eventArrow.t3x");
			#else
			loadGraphic("assets/images/eventArrow.png");
			#end
			setGraphicSize(gridSize, gridSize);
			updateHitbox();
			if(data.column == -2) color = 0xFF00FFFF;
			else color = 0xFFCCCCCC;
		} else {
			var colIdx = data.column % 4;
			var loadedCustom:Bool = false;

			if (customNotePath != null && data.noteType != "Normal" && data.noteType != "Hurt Note") {
				#if !haxe3ds
				var path = haxe.io.Path.join([customNotePath, data.noteType + ".png"]);
				if (sys.FileSystem.exists(path)) {
					loadGraphic(path);
					setGraphicSize(gridSize, gridSize);
					updateHitbox();
					loadedCustom = true;
				}
				#end
			}

			if (!loadedCustom) {
				#if !haxe3ds
				if (data.noteType == "Hurt Note") 
					this.frames = cachedHurtFrames;
				else 
					this.frames = cachedFrames;

				this.antialiasing = true;
				var colorPrefix = "";
				switch(colIdx) {
					case 0: colorPrefix = "purple";
					case 1: colorPrefix = "blue";
					case 2: colorPrefix = "green";
					case 3: colorPrefix = "red";
				}

				animation.addByPrefix('scroll', colorPrefix + "0", 24, true);
				animation.play('scroll');
				setGraphicSize(gridSize, gridSize);
				updateHitbox();
				#else
				// 3DS Note loading via CitroAnimate
				var colorPrefix = switch(colIdx) {
					case 0: "purple";
					case 1: "blue";
					case 2: "green";
					case _: "red";
				};
				play(colorPrefix);
				scale.set(gridSize / width, gridSize / height);
				updateHitbox();
				#end
			}

			// Sustains
			if (data.length > 0) {
				#if !haxe3ds
				if (sustainPiece != null) sustainPiece.visible = true;
				if (sustainEnd != null) sustainEnd.visible = true;
				sustainPiece.alpha = 0.6;
				sustainEnd.alpha = 0.6;

				sustainPiece.frames = cachedFrames;
				sustainEnd.frames = cachedFrames;

				sustainPiece.antialiasing = true;
				sustainEnd.antialiasing = true;
				var colorPrefix = ["purple", "blue", "green", "red"][colIdx];
				
				if (colIdx == 0 && data.noteType != "Hurt Note") { 
					sustainPiece.animation.addByPrefix('hold', 'purple hold piece');
					sustainEnd.animation.addByPrefix('hold', 'pruple end hold');
				} else {
					sustainPiece.animation.addByPrefix('hold', colorPrefix + ' hold piece');
					var endAnimName = colorPrefix + " hold end";
					if (colIdx == 0) endAnimName = "pruple end hold"; 
					sustainEnd.animation.addByPrefix('hold', endAnimName);
				}

				sustainPiece.animation.play('hold');
				sustainEnd.animation.play('hold');
				#end
			} else {
				if(sustainPiece != null) sustainPiece.visible = false;
				if(sustainEnd != null) sustainEnd.visible = false;
			}
		}
	}
	
	public function updateTail(stepMs:Float, scrollSpeed:Float = 1) {
		#if !haxe3ds
		if (sustainPiece != null && sustainEnd != null && data.length > 0) {
			var visualWidth = gridSize * 0.4;
			var centerX = x + (width / 2);
			sustainEnd.setGraphicSize(Std.int(visualWidth));
			sustainEnd.updateHitbox();

			var totalVisualHeight = (data.length / stepMs) * gridSize;
			var pieceHeight = totalVisualHeight - sustainEnd.height;
			if (pieceHeight < 0) pieceHeight = 0;

			sustainPiece.scale.set(1, 1);
			sustainPiece.setGraphicSize(Std.int(visualWidth));
			sustainPiece.updateHitbox();
			sustainPiece.scale.y = pieceHeight / sustainPiece.frameHeight;
			sustainPiece.updateHitbox();

			sustainPiece.x = centerX - (sustainPiece.width / 2);
			sustainPiece.y = y + (gridSize / 2);
			sustainEnd.x = centerX - (sustainEnd.width / 2);
			sustainEnd.y = sustainPiece.y + pieceHeight;
		}
		#end
	}

	override function draw() {
		#if !haxe3ds
		if (sustainPiece != null && sustainEnd != null && data.length > 0 && sustainPiece.visible) {
			sustainPiece.draw();
			sustainEnd.draw();
		}
		if (visible) super.draw();
		#else
		super.update();
		#end
	}
}
