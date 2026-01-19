package;

class EditorStrumLine extends FlxSpriteGroup
{
	// Grid and Visuals
	public var gridBG:FlxBackdrop;
	public var separator:FlxSprite;
	public var strums:FlxTypedGroup<ChartEditorHelpers.EditorStrum>;
	public var icon:FlxSprite;
	// Data
	public var laneCount:Int;
	public var isEvent:Bool;
	public var startColumn:Int; 
	public var laneIndex:Int;
	public function new(x:Float, y:Float, laneCount:Int, startColumn:Int, isEvent:Bool = false, laneIndex:Int = 0)
	{
		super(x, y);
		this.laneCount = laneCount;
		this.startColumn = startColumn;
		this.isEvent = isEvent;
		this.laneIndex = laneIndex;

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

		// 3. Strums (Gray Notes)
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

		// 4. Icon
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
		}
	}
	
	public function updateGridPosition(strumLineY:Float, gridY:Float)
	{
		gridBG.y = strumLineY % ChartEditor.GRID_SIZE;
	}
}
