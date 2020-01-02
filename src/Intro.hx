import mt.deepnight.Buffer;
import mt.flash.Sfx;
import mt.deepnight.Lib;
import mt.MLib;
import mt.deepnight.slb.*;
import mt.deepnight.mui.*;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

@:bitmap("assets/logo.png") class GfxLogo extends flash.display.BitmapData {}

class Intro extends mt.deepnight.FProcess {
	var mask			: Bitmap;
	var buffer			: Buffer;
	var game			: Game;
	var cine			: mt.deepnight.Cinematic;
	var textY			: Float;
	var all				: Array<flash.text.TextField>;
	var logo			: Bitmap;

	public function new(b:Buffer) {
		buffer = b;
		game = Game.ME;
		cine = new mt.deepnight.Cinematic();
		textY = 0;
		all = [];

		super(buffer.getContainer());

		mask = new flash.display.Bitmap( buffer.createSimilarBitmap(false) );
		buffer.addChild(mask);
		mask.bitmapData.fillRect( mask.bitmapData.rect, 0x0F171A );

		logo = new flash.display.Bitmap( new GfxLogo(0,0) );
		buffer.addChild(logo);
		logo.x = Std.int(buffer.width*0.5-logo.width*0.5);
		logo.y = Std.int(buffer.height*0.5-logo.height*0.5);
		logo.alpha = 0;

		cine.create({
			600;
			tw.create(logo.alpha, 1, 1500);
			1000;
			text("A 48h game by", 0.5);
			500;
			text("Sebastien Benard / www.deepnight.net", 0.5);
			800;
			tw.create(logo.alpha, 0, 1500);
			400;
			game.start();
			fadeTexts();
			tw.create(mask.alpha, 0, 2500);
			10000;
			destroy();
		});
	}

	function fadeTexts() {
		for(tf in all )
			tw.create(tf.alpha, 0).onEnd = function() {
				tf.parent.removeChild(tf);
			}
	}

	override function unregister() {
		super.unregister();
		cine.destroy();
		game = null;
		mask.bitmapData.dispose();
		mask.bitmapData = null;
		logo.bitmapData.dispose();
		logo.bitmapData = null;
		logo.parent.removeChild(logo);
	}


	function text(str:String, ?alpha=1.) {
		var tf = game.createField(str);
		tf.textColor = 0xffffff;
		buffer.addChild(tf);
		tf.x = Std.int(buffer.width*0.5-tf.textWidth*0.5);
		tf.y = 130 + textY;
		tf.filters = [
			new flash.filters.GlowFilter(0x6591C5,0.5, 8,8,1),
		];

		tf.alpha = 0;
		tw.create(tf.alpha, alpha, 1500);
		textY+=10;
		all.push(tf);
	}


	override function update() {
		super.update();

		cine.update();
	}
}