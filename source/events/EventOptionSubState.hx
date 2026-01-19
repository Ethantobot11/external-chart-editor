package events;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class EventOptionSubState extends FlxFixedSubState
{
	var note:EditorNoteData;
	var onEdit:Void->Void;
	var onDelete:Void->Void;

	var targetX:Float;
	var targetY:Float;

	var bg:FlxSprite;
	var box:FlxSprite;
	var title:FlxText;
	var btnEdit:FlxButton;
	var btnDelete:FlxButton;
	var border:FlxSprite;

	public function new(note:EditorNoteData, x:Float, y:Float, onEdit:Void->Void, onDelete:Void->Void)
	{
		super();
		defaultCamera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		this.note = note;
		this.targetX = x;
		this.targetY = y;
		this.onEdit = onEdit;
		this.onDelete = onDelete;
	}

	override function create()
	{
		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set(0,0);
		add(bg);
		FlxTween.tween(bg, {alpha: 0.4}, 0.2);

		var boxWidth = 260;
		var boxHeight = 180;

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
	}

	function styleButton(btn:FlxButton, color:Int) {
		btn.makeGraphic(140, 30, color);
		btn.label.setFormat(null, 14, FlxColor.WHITE, CENTER);
		btn.scrollFactor.set(0,0);
	}

	function closeAnim(onComplete:Void->Void) {
		FlxTween.tween(box, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.2, {ease: FlxEase.backIn});
		FlxTween.tween(border, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.2, {ease: FlxEase.backIn});
		FlxTween.tween(bg, {alpha: 0}, 0.2, {onComplete: function(t:FlxTween) {
			close();
			onComplete();
		}});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		// Tıklama ile kapatma (Menü dışına)
		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			if (touch.justPressed) {
				var touch = FlxG.touches.getFirst();
				if (!touch.overlaps(box)) closeAnim(function(){});
			}
		}
		#end

		if(FlxG.mouse.justPressed && !FlxG.mouse.overlaps(box)) {
			closeAnim(function(){});
		}

		if(FlxG.keys.justPressed.ESCAPE) closeAnim(function(){});
	}
}
