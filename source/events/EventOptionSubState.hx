package events;

#if !haxe3ds
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#else
import citro.backend.CitroColor;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.state.CitroSubState;
#end

class EventOptionSubState extends #if !haxe3ds FlxFixedSubState #else CitroSubState #end
{
	var note:EditorNoteData;
	var onEdit:Void->Void;
	var onDelete:Void->Void;

	var targetX:Float;
	var targetY:Float;

	#if !haxe3ds
	var bg:FlxSprite;
	var box:FlxSprite;
	var title:FlxText;
	var btnEdit:FlxButton;
	var btnDelete:FlxButton;
	var border:FlxSprite;
	#else
	var bg:CitroSprite;
	var box:CitroSprite;
	var border:CitroSprite;
	var titleText:CitroText;
	var subText:CitroText;
	var btnEdit:ArkButton;
	var btnDelete:ArkButton;
	#end

	public function new(note:EditorNoteData, x:Float, y:Float, onEdit:Void->Void, onDelete:Void->Void)
	{
		super();
		#if !haxe3ds
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		#end
		this.note = note;
		this.targetX = x;
		this.targetY = y;
		this.onEdit = onEdit;
		this.onDelete = onDelete;
	}

	override function create()
	{
		super.create();

		var boxWidth = 260;
		var boxHeight = 180;

		#if !haxe3ds
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set(0,0);
		add(bg);
		FlxTween.tween(bg, {alpha: 0.4}, 0.2);

		if (targetX + boxWidth > FlxG.width) targetX = FlxG.width - boxWidth - 10;
		if (targetX < 0) targetX = 10;
		if (targetY + boxHeight > FlxG.height) targetY = FlxG.height - boxHeight - 10;
		if (targetY < 0) targetY = 10;

		box = new FlxSprite(targetX, targetY).makeGraphic(boxWidth, boxHeight, 0xFF181818);
		border = new FlxSprite(targetX - 2, targetY - 2).makeGraphic(boxWidth + 4, boxHeight + 4, 0xFF4488FF);

		border.scrollFactor.set(0,0);
		box.scrollFactor.set(0,0);

		add(border);
		add(box);

		title = new FlxText(targetX, targetY + 15, boxWidth, "EVENT OPTION", 20);
		title.setFormat(null, 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set(0,0);
		add(title);

		var subText = new FlxText(targetX, title.y + 25, boxWidth, "Selected: " + note.noteType, 12);
		subText.setFormat(null, 12, 0xFFAAAAAA, CENTER);
		subText.scrollFactor.set(0,0);
		add(subText);

		btnEdit = new FlxButton(targetX + (boxWidth/2) - 70, targetY + 70, "Edit Event", function() {
			closeAnim(function() { if(onEdit != null) onEdit(); });
		});
		styleButton(btnEdit, 0xFF4488FF);
		add(btnEdit);

		btnDelete = new FlxButton(targetX + (boxWidth/2) - 70, targetY + 115, "Delete Event", function() {
			closeAnim(function() { if(onDelete != null) onDelete(); });
		});
		styleButton(btnDelete, 0xFFFF4444);
		add(btnDelete);

		box.scale.set(0.1, 0.1);
		border.scale.set(0.1, 0.1);
		box.alpha = 0;
		border.alpha = 0;

		FlxTween.tween(box, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
		FlxTween.tween(border, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
		#else
		bg = new CitroSprite();
		box = new CitroSprite();
		box.x = targetX;
		box.y = targetY;
		box.color = 0xFF181818;

		border = new CitroSprite();
		border.x = targetX - 2;
		border.y = targetY - 2;
		border.color = 0xFF4488FF;

		titleText = new CitroText(targetX, targetY + 15, "EVENT OPTION");
		titleText.color = 0xFFFFFFFF;
		titleText.alignment = CENTER;
		titleText.setBorderStyle(0xFF000000, 1, OUTLINE);

		subText = new CitroText(targetX, targetY + 40, "Selected: " + note.noteType);
		subText.color = 0xFFAAAAAA;
		subText.alignment = CENTER;

		btnEdit = new ArkButton(targetX + (boxWidth/2) - 70, targetY + 70, 140, 30, 1, "Edit Event", function() {
			closeAnim(function() { if(onEdit != null) onEdit(); });
		});
		btnEdit.setBaseColor(0xFF4488FF);

		btnDelete = new ArkButton(targetX + (boxWidth/2) - 70, targetY + 115, 140, 30, 1, "Delete Event", function() {
			closeAnim(function() { if(onDelete != null) onDelete(); });
		});
		btnDelete.setBaseColor(0xFFFF4444);
		#end
	}

	#if !haxe3ds
	function styleButton(btn:FlxButton, color:Int) {
		btn.makeGraphic(140, 30, color);
		btn.label.setFormat(null, 14, FlxColor.WHITE, CENTER);
		btn.scrollFactor.set(0,0);
	}
	#end

	function closeAnim(onComplete:Void->Void) {
		#if !haxe3ds
		FlxTween.tween(box, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.2, {ease: FlxEase.backIn});
		FlxTween.tween(border, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.2, {ease: FlxEase.backIn});
		FlxTween.tween(bg, {alpha: 0}, 0.2, {onComplete: function(t:FlxTween) {
			close();
			onComplete();
		}});
		#else
		close();
		if(onComplete != null) onComplete();
		#end
	}

	override function update(#if haxe3ds delta:Int #else elapsed:Float #end) {
		super.update(#if !haxe3ds elapsed #end);
		
		#if !haxe3ds
		#if (FLX_TOUCH || haxe3ds || cafe)
		for (touch in FlxG.touches.list) {
			if (touch.justPressed) {
				var touch = FlxG.touches.getFirst();
				if (!touch.overlaps(box)) closeAnim(function(){});
			}
		}
		#end

		#if (!FLX_TOUCH && !haxe3ds && !cafe)
		if(FlxG.mouse.justPressed && !FlxG.mouse.overlaps(box)) {
			closeAnim(function(){});
		}

		if(FlxG.keys.justPressed.ESCAPE) closeAnim(function(){});
		#end
		#else
		box.update(#if !haxe3ds elapsed #end);
		border.update(#if !haxe3ds elapsed #end);
		titleText.update(#if !haxe3ds elapsed #end);
		subText.update(#if !haxe3ds elapsed #end);
		btnEdit.update(#if !haxe3ds elapsed #end);
		btnDelete.update(#if !haxe3ds elapsed #end);
		#end
	}
}
