package objects;

#if !haxe3ds
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
#else
import citro.backend.CitroColor;
import citro.object.CitroObject;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.object.CitroCamera;
#end

class ArkButton extends #if !haxe3ds FlxSpriteGroup #else CitroObject #end
{
	public var bg: #if !haxe3ds FlxSprite #else CitroSprite #end;
	public var label: #if !haxe3ds FlxText #else CitroText #end;
	
	public var onClick:Void->Void;
	public var isHovered:Bool = false;

	#if haxe3ds
	public var baseColor:CitroColor = 0xFF444444;
	public var hoverColor:CitroColor = 0xFF666666;
	public var clickColor:CitroColor = 0xFF222222;
	#else
	public var baseColor:FlxColor = 0xFF444444;
	public var hoverColor:FlxColor = 0xFF666666;
	public var clickColor:FlxColor = 0xFF222222;
	#end
	
	#if !haxe3ds
	var _camera:FlxCamera;
	#else
	var _camera:CitroCamera;
	#end

	public function new(x:Float, y:Float, width:Int, height:Int, scale:Float = 1, text:String, onClick:Void->Void, #if !haxe3ds cam:FlxCamera = null #else cam:CitroCamera = null #end)
	{
		#if !haxe3ds
		super(x, y);
		#else
		super();
		this.x = x;
		this.y = y;
		#end
		
		this.onClick = onClick;
		this._camera = cam;
		
		#if !haxe3ds
		if (cam != null) this.cameras = [_camera];

		bg = new FlxSprite(x, y).makeGraphic(width, height, 0xFFFFFFFF);
		bg.color = baseColor;
		add(bg);

		var borderHeight:Int = 4;
		var border = new FlxSprite(x, y + height - borderHeight).makeGraphic(width, borderHeight, 0xFF000000);
		border.alpha = 0.4;
		add(border);
		
		var textSize:Int = Std.int(12 * scale);
		if (textSize < 8) textSize = 8;
		
		label = new FlxText(x, y, width, text);
		label.setFormat(null, textSize, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		label.borderSize = 1;
		label.y = y + (height - label.height) / 2;
		add(label);
		#else
		bg = new CitroSprite();
		bg.x = x;
		bg.y = y;
		bg.color = baseColor;
		
		var textSize:Float = 12 * scale;
		if (textSize < 8) textSize = 8;

		label = new CitroText(x, y, text);
		label.color = 0xFFFFFFFF;
		label.setBorderStyle(0xFF000000, 1, OUTLINE);
		label.scale.set(textSize / 12, textSize / 12);
		label.y = y + (height - label.height) / 2;
		#end
	}

	override function update(#if !haxe3ds #if haxe3ds delta:Int #else elapsed:Float #end #else delta:Int #end)
	{
		#if !haxe3ds
		super.update(#if !haxe3ds elapsed #else delta #end);
		
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
		#else
		super.update(delta);
		bg.update(delta);
		label.update(delta);
		#end
	}
	
	public function setBaseColor(#if haxe3ds col:CitroColor #else col:FlxColor #end) {
		this.baseColor = col;
		this.bg.color = col;
	}
}
