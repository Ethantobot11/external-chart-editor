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
import citro.state.CitroCamera;
#end

class ArkButton extends #if !haxe3ds FlxSpriteGroup #else CitroObject #end
{
	public var bg: #if !haxe3ds FlxSprite #else CitroSprite #end;
	public var label: #if !haxe3ds FlxText # else CitroText #end;
	
	public var onClick:Void->Void;
	public var isHovered:Bool = false;
	
	public var baseColor:CitroColor = 0xFF444444;
	public var hoverColor:CitroColor = 0xFF666666;
	public var clickColor:CitroColor = 0xFF222222;
	
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
		
		// Setup label for Citro if you have CitroText/CitroSprite text equivalents here
		#end
	}

	override function update(#if !haxe3ds elapsed:Float #else delta:Int #end)
	{
		#if !haxe3ds
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
		#else
		super.update(delta);
		// Add Citro touch coordinate overlap detection for 3DS bottom screen here if required
		#end
	}
	
	public function setBaseColor(col:CitroColor) {
		this.baseColor = col;
		this.bg.color = col;
	}
}
