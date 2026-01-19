package objects;

class ArkButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var label:FlxText;
	
	public var onClick:Void->Void;
	public var isHovered:Bool = false;
	
	public var baseColor:FlxColor = 0xFF444444;
	public var hoverColor:FlxColor = 0xFF666666;
	public var clickColor:FlxColor = 0xFF222222;
	
	var _camera:FlxCamera;

	/**
	 * @param x         X Pozisyonu
	 * @param y         Y Pozisyonu
	 * @param width     Genişlik
	 * @param height    Yükseklik
	 * @param scale     Metin boyutu çarpanı (varsayılan 1)
	 * @param text      Buton metni
	 * @param onClick   Tıklanınca çalışacak fonksiyon
	 * @param cam       Hangi kamerada görüneceği (Genelde camHUD)
	 */
	public function new(x:Float, y:Float, width:Int, height:Int, scale:Float = 1, text:String, onClick:Void->Void, cam:FlxCamera = null)
	{
		super(x, y);
		
		this.onClick = onClick;
		this._camera = cam;
		
		if (cam != null) _camera = cam;
		
		if (cam != null) this.cameras = [_camera];

		bg = new FlxSprite().makeGraphic(width, height, FlxColor.WHITE);
		bg.color = baseColor;
		add(bg);

		var borderHeight:Int = 4;
		var border = new FlxSprite(0, height - borderHeight).makeGraphic(width, borderHeight, 0xFF000000);
		border.alpha = 0.4;
		add(border);
		
		var textSize:Int = Std.int(12 * scale);
		if (textSize < 8) textSize = 8;
		
		label = new FlxText(0, 0, width, text);
		label.setFormat(null, textSize, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		label.borderSize = 1;
		
		label.y = (height - label.height) / 2;
		add(label);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.mouse.overlaps(bg, cameras[0]))
		{
			isHovered = true;
			
			if (FlxG.mouse.pressed)
			{
				bg.color = clickColor;
			}
			else
			{
				bg.color = hoverColor;
			}
			
			if (FlxG.mouse.justReleased)
			{
				if (onClick != null) onClick();
			}
		}
		else
		{
			isHovered = false;
			bg.color = baseColor;
		}
	}
	
	public function setBaseColor(col:FlxColor) {
		this.baseColor = col;
		this.bg.color = col;
	}
}
