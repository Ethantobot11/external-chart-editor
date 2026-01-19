package objects;

class ArkDropDown extends FlxSpriteGroup {
	public var headerBtn:ArkButton;
	public var isOpen:Bool = false;
	
	var bgOptions:FlxTypedGroup<ArkButton>;
	var optionLabels:Array<String>;
	var onSelect:String->Void;
	var uiScale:Float;
	var cam:FlxCamera;
	var _height:Int;
	var autoClose:Bool;
	public function new(x:Float, y:Float, width:Int, height:Int, scale:Float, label:String, options:Array<String>, onSelect:String->Void, cam:FlxCamera, autoClose:Bool = true) {
		super(x, y);
		this.width = width;
		this.height = height;
		this.uiScale = scale;
		this.optionLabels = options;
		this.onSelect = onSelect;
		this.cam = cam;
		this._height = height;
		this.autoClose = autoClose;

		bgOptions = new FlxTypedGroup<ArkButton>();
		headerBtn = new ArkButton(0, 0, width, height, scale, label + ": " + (options.length > 0 ? options[0] : "None"), toggleOpen, cam);
		add(headerBtn);
		this.cameras = [cam];
	}

	function toggleOpen() {
		isOpen = !isOpen;
		refreshOptions();
	}

	function refreshOptions() {
		for (btn in bgOptions) {
			remove(btn);
			btn.destroy();
		}
		bgOptions.clear();

		if (isOpen) {
			var currentY = _height;
			for (i in 0...optionLabels.length) {
				var opt = optionLabels[i];
				var btnLabel = i + ": " + opt;
				var btn = new ArkButton(0, currentY, Std.int(width), _height, uiScale, btnLabel, function() {
					if (onSelect != null) onSelect(opt);
					headerBtn.label.text = "ꜜ Type: " + opt + " ꜜ";
					if (autoClose) toggleOpen();
				}, cam);
				btn.bg.color = (i % 2 == 0) ? 0xFF555555 : 0xFF666666;
				
				add(btn);
				bgOptions.add(btn);
				currentY += _height;
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if(isOpen) {
			bgOptions.update(elapsed);
		}
	}
}
