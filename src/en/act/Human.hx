package en.act;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Human extends en.Activable {
	public static var ALL : Array<Human> = [];
	var alreadyPowered		: Bool;
	var human				: BSprite;

	public function new(x,y, init:Bool) {
		alreadyPowered = init;
		super(x,y);
		ALL.push(this);
		human = Game.ME.tiles.get("humanIdle");
		spr.addChild(human);
		human.setCenter(0.5,1);
		human.blendMode = OVERLAY;
		human.a.registerStateAnim("humanAwaken", 1, function() return cd.has("sleepLag") || !powered);
		human.a.registerStateAnim("humanIdle", 0);
		redraw();

		cd.set("init", 2);

		var r = new en.HumanReceiver(cx,cy-2);

		if( alreadyPowered ) {
			var e = new en.EmitterHuman(cx-1, cy-2, r);
			e.reach = Const.GRID*rnd(2, 2.2);
			e.onPlugToReceiver(r);
		}
		else
			Game.ME.tiles.drawIntoBitmap( Game.ME.level.bg.bitmapData, (cx-1)*Const.GRID, (cy-2)*Const.GRID, "emitterHuman", 1);
	}

	override function setPower(p:Bool) {
		var old = powered;
		super.setPower(p);
		//super.setPower(alreadyPowered || p);
		redraw();
		if( !cd.has("init") && !old && powered )
			Game.SBANK.power02(0.2);

		if( !cd.has("init") && powered && !old ) {
			if( cx==74 && cy==11 && Game.ME.doOnce("nooo") )
				say("Nooo...", true);
			cd.set("sleepLag", Const.seconds(rnd(1.5, 2.5)));
			if( Game.ME.doOnce("replug") ) {
				Game.ME.delayer.add( function() Game.ME.hero.say("Human happy again."), 500 );
			}
		}
	}

	public static function getStats() {
		var p = 0;
		var pTotal = 0;
		var up = 0;
		var upTotal = 0;
		for(e in ALL) {
			if( !e.alreadyPowered ) {
				pTotal++;
				if( e.powered )
					p++;
			}
			else {
				upTotal++;
				if( !e.powered )
					up++;
			}
		}

		return {
			toPlugDone		: p,
			toPlugTotal		: pTotal,
			toUnplugDone	: up,
			toUnplugTotal	: upTotal,
		}
	}

	public function redraw() {
		spr.set("humanPod", powered ? 1 : 0);
		if( human!=null )
			human.alpha = powered ? 0.4 : 0.7;
	}

	override function unregister() {
		super.unregister();
		human.destroy();
		ALL.remove(this);
	}

	override function update() {
		super.update();
		spr.y-=1;
		if( isOnScreen() ) {
			if( !alreadyPowered && !powered && Game.ME.time%15==0 )
				Fx.ME.alert(xx,yy-16);
			human.y = -1 + Math.cos((uid*100+Game.ME.time)*0.1) * 1;
		}
	}
}
