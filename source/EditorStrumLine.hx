package;

#if haxe3ds
import citro.object.CitroSprite;
import citro.object.CitroObject;
import citro.CitroG;
typedef BaseSpriteGroup = CitroObject;
#else
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
typedef BaseSpriteGroup = FlxSpriteGroup;
#end

class EditorStrumLine extends BaseSpriteGroup
{
	#if haxe3ds
	public var gridBG:CitroSprite;
	public var separator:CitroSprite;
	public var strums:Array<Dynamic> = [];
	public var icon:CitroSprite;
	public var members:Array<CitroObject> = [];
	
	public var x(default, set):Float = 0;
	public var y(default, set):Float = 0;

	function set_x(v:Float):Float {
		var diff = v - x;
		x = v;
		for (m in members) if (m != null) m.x += diff;
		return x;
	}

	function set_y(v:Float):Float {
		var diff = v - y;
		y = v;
		for (m in members) if (m != null) m.y += diff;
		return y;
	}

	override public function add(obj:CitroObject):CitroObject {
		if (obj != null && members.indexOf(obj) == -1) {
			obj.x += x;
			obj.y += y;
			members.push(obj);
		}
		return obj;
	}
	#else
	public var gridBG:FlxBackdrop;
	public var separator:FlxSprite;
	public var strums:FlxTypedGroup<ChartEditorHelpers.EditorStrum>;
	public var icon:FlxSprite;
	#end

	// Data
	public var laneCount:Int;
	public var isEvent:Bool;
	public var startColumn:Int; 
	public var laneIndex:Int;

	public function new(x:Float, y:Float, laneCount:Int, startColumn:Int, isEvent:Bool = false, laneIndex:Int = 0)
	{
		#if !haxe3ds
		super(x, y);
		#else
		this.x = x;
		this.y = y;
		#end

		this.laneCount = laneCount;
		this.startColumn = startColumn;
		this.isEvent = isEvent;
		this.laneIndex = laneIndex;

		#if haxe3ds
		var gridSize = 32;
		var totalWidth = gridSize * laneCount;

		// 1. Grid Background
		gridBG = new CitroSprite(this.x, this.y - y);
		gridBG.makeGraphic(totalWidth, 240 * 3, 0xFF1F1F1F);
		add(gridBG);

		// 2. Separator
		var sepColor = 0xFFFFFFFF;
		if (isEvent) {
			if (startColumn == -1) sepColor = 0xFFFF00FF;
			else sepColor = 0xFF00FFFF;
		}
		
		separator = new CitroSprite(this.x + (startColumn == -2 ? 0 : totalWidth) - 1, this.y - CitroG.HEIGHT);
		separator.makeGraphic(2, CitroG.HEIGHT * 3, sepColor);
		separator.alpha = 0.5;
		add(separator);

		// 3. Strums (3DS Native Array implementation)
		strums = [];
		for (i in 0...laneCount)
		{
			var noteID = isEvent ? startColumn : (startColumn + i);
			var globalX = this.x + (i * gridSize);
			var globalY = this.y - (gridSize / 2);
			
			var strum = new ChartEditorHelpers.EditorStrum(globalX, globalY, noteID, gridSize, isEvent);
			strum.alpha = 0.8;
			if (isEvent && startColumn == -2) strum.color = 0xFF00FFFF;
			
			strums.push(strum);
			add(strum);
		}

		// 4. Icon
		if (!isEvent)
		{
			icon = new CitroSprite();
			var charName = (startColumn < 4) ? "dad" : "bf";
			var iconPath = "romfs:/assets/images/icons/icon-" + charName + ".png";

			if (openfl.utils.Assets.exists(iconPath)) {
				icon.loadGraphic(iconPath, true, 150, 150);
				icon.scale.set(0.5, 0.5); 
				icon.updateHitbox();
				icon.x = this.x + (totalWidth - icon.width) / 2;
				icon.y = this.y - gridSize - icon.height - 10;
				if (startColumn < 4) icon.color = 0xFFCCCCCC;
				add(icon);
			}
		}

		#else
		var gridSize = ChartEditor.GRID_SIZE;
		var totalWidth = gridSize * laneCount;
		var height = FlxG.height * 3; 

		// 1. Grid Background
		var color1 = 0xFF2A2A2A;
		var color2 = 0xFF1F1F1F;
		var gridTile = FlxGridOverlay.create(gridSize, gridSize, totalWidth, gridSize * 2, true, color1, color2);
		gridBG = new FlxBackdrop(gridTile.graphic, Y);
		gridBG.x = 0;
		gridBG.y = -y;
		add(gridBG);

		// 2. Separator
		var sepColor = 0xFFFFFFFF;
		if (isEvent) {
			if (startColumn == -1) sepColor = 0xFFFF00FF;
			else sepColor = 0xFF00FFFF;
		}
		
		separator = new FlxSprite((startColumn == -2 ? 0 : totalWidth) - 1, -FlxG.height).makeGraphic(2, height, sepColor);
		separator.alpha = 0.5;
		separator.scrollFactor.set(0, 0);
		add(separator);

		strums = new FlxTypedGroup<ChartEditorHelpers.EditorStrum>();
		for (i in 0...laneCount)
		{
			var noteID = isEvent ? startColumn : (startColumn + i);
			
			var globalX = x + (i * gridSize);
			var globalY = y - (gridSize / 2);
			
			var strum = new ChartEditorHelpers.EditorStrum(globalX, globalY, noteID, gridSize, isEvent);
			strum.scrollFactor.set(0, 0);
			strum.alpha = 0.8;
			if (isEvent && startColumn == -2) strum.color = 0xFF00FFFF;
			
			strums.add(strum);
		}
		add(strums);

		if (!isEvent)
		{
			icon = new FlxSprite();
			var charName = (startColumn < 4) ? "dad" : "bf";
			var iconPath = "assets/images/icons/icon-" + charName + ".png";
			if (!openfl.utils.Assets.exists(iconPath)) iconPath = "assets/images/icons/icon-face.png";

			if (openfl.utils.Assets.exists(iconPath)) {
				icon.loadGraphic(iconPath, true, 150, 150);
				icon.animation.add('neutral', [0], 0, false);
				icon.animation.play('neutral');
				icon.scale.set(0.5, 0.5); 
				icon.updateHitbox();
				icon.x = x + (totalWidth - icon.width) / 2;
				icon.y = y - (gridSize) - icon.height - 10;
				
				if (startColumn < 4) icon.color = 0xFFCCCCCC;
			}
			add(icon);
		}
		#end
	}
	
	public function updateGridPosition(strumLineY:Float, gridY:Float)
	{
		#if haxe3ds
		gridBG.y = this.y + (strumLineY % 32);
		#else
		gridBG.y = strumLineY % ChartEditor.GRID_SIZE;
		#end
	}
}
