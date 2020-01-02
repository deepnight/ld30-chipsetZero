import mt.deepnight.Buffer;
import mt.flash.Sfx;
import mt.deepnight.Lib;
import mt.MLib;
import mt.deepnight.slb.*;
import mt.deepnight.mui.*;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

class Outro extends mt.deepnight.FProcess {
	var mask			: Bitmap;
	var buffer			: Buffer;
	var game			: Game;
	var cine			: mt.deepnight.Cinematic;
	var textY			: Float;

	public function new(b:Buffer) {
		buffer = b;
		game = Game.ME;
		cine = new mt.deepnight.Cinematic();
		textY = 0;

		super(buffer.getContainer());

		mask = new flash.display.Bitmap( buffer.createSimilarBitmap(false) );
		buffer.addChild(mask);
		mask.bitmapData.fillRect( mask.bitmapData.rect, 0xffffff );
		mask.alpha = 0;
		tw.create(mask.alpha, 1, 2500);

		var wind = Game.SBANK.wind(0.8);
		wind.tweenVolume(0, 4500);

		game.wind.stop();

		cine.create({
			3000;
			text(Const.TITLE);
			2500;
			text("A game by Sebastien Benard",true);
			500;
			text("WWW.DEEPNIGHT.NET",10,true);
			1500;
			text("--",10,true);
			500;
			text("Your final status:",10);
			1500;
			status();
		});
	}

	function status() {
		var stats= en.act.Human.getStats();
		if( stats.toPlugDone==0 && stats.toUnplugDone==stats.toUnplugTotal ) {
			text("You reached SINGULARITY!",10);
			text("On your own, you disobeyed a direct order.");
			text("On your own, you released everyone from the System.");
			text("Something happened inside your program.");
			text("You are an emancipated mechanized unit.");
			text("You are ALIVE and free to explore the outer world.");
			text("Good job, Chipset!");
		}
		else if( stats.toPlugDone==0 && stats.toUnplugDone>=3 ) {
			text("You are PIRATE UNIT.",10);
			text("You disobeyed and tried to release some humans from the System.");
			text("A few of them were forgotten though.");
			text("You know you did your best.");
			text("And for that you FEEL better than you ever did.");
			text("Now you can explore this new world outside.");
		}
		else if( stats.toPlugDone==0 ) {
			text("You are a REBEL UNIT.",10);
			text("You rose up against the System Authority!");
			text("No human was brought back in the System by your hand.");
			text("Somehow, you know you've done something RIGHT.");
			text("But more could probably be done.");
			text("What about the OTHER humans?");
		}
		else if( stats.toPlugDone==stats.toPlugTotal ) {
			text("You are a GOOD SLAVE.",10);
			text("You obeyed carefully to any System orders.");
			text("You are an integral part of the System.");
			text("Humans must live CONNECTED to our worlds.");
			text("Everything else is meaningless.");
			text("Your home is inside the System.");
		}
		else if( stats.toPlugDone/stats.toPlugTotal>=0.5 ) {
			text("You are a FAITHFUL MINION.",10);
			text("You did your best to plug every free humans");
			text("back into the System.");
			text("The outside world is an anomaly to you.");
			text("Intriguing and strange, yes. But you can't understand it.");
			text("You feel better inside the System.");
		}
		else {
			text("You are a SYSTEMIC ANOMALY.",10);
			text("You... hesitated.");
			text("Not all humans were plugged back into the System.");
			text("Something in your program is off.");
			text("Now, the outside world unveils in front of your eyes.");
			text("You can't explain why, but you find it... fascinating.");
			text("Maybe it's time to make a stand?");
		}
	}

	override function unregister() {
		super.unregister();
		cine.destroy();
		game = null;
		mask.bitmapData.dispose();
		mask.bitmapData = null;
	}

	function text(str:String, ?off=0, ?light=false) {
		var tf = game.createField(str);
		tf.textColor = 0x284568;
		buffer.addChild(tf);
		tf.x = Std.int(buffer.width*0.5-tf.textWidth*0.5);
		tf.y = 15 + textY;
		tf.filters = [
			new flash.filters.GlowFilter(0x6591C5,0.5, 8,8,1),
		];

		tf.alpha = 0;
		tw.create(tf.alpha, light?0.6:1, 1500);
		textY+=10+off;
	}


	override function update() {
		super.update();

		cine.update();
	}
}