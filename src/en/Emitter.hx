package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import flash.display.Sprite;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Emitter extends Entity {
	public static var ALL : Array<Emitter> = [];

	public var receiver		: Null<Receiver>;
	var cable				: Null<Sprite>;
	public var cableEnd		: Null<Entity>;
	var cableOffsetX		: Float;
	var cableOffsetDx		: Float;
	var cableOffsetY		: Float;
	var cableOffsetDy		: Float;
	public var reach		: Float;
	public var active		: Bool;

	public function new(x,y) {
		super();
		active = true;
		ALL.push(this);
		reach = Const.GRID*7;
		setPosCase(x,y);
		cableOffsetX = 0;
		cableOffsetDx = 0;
		cableOffsetY = 0;
		cableOffsetDy = 0;
		gravity = 0;
		setDepth(Const.DP_MECHANISM);

		cable = new Sprite();
		Game.ME.sdm.add(cable, Const.DP_CABLE);
		cable.filters = [
			new flash.filters.DropShadowFilter(1,-45, 0xCE3E00,0.8, 0,0,1, 1,true),
			new flash.filters.DropShadowFilter(4,90, 0x0,0.4, 2,2),
		];
		cable.visible = false;

		spr.set("power");
	}

	public function onCableGrab(e:Entity) {
		if( receiver!=null )
			receiver.setPower(false);
		receiver = null;
		cableEnd = e;
		cable.visible = true;
		Game.SBANK.plug04(1);
	}

	public function onPlugToReceiver(r:Receiver) {
		onCableGrab(r);
		receiver = r;
		Game.SBANK.plug01(1);
		for(e in ALL)
			if( e!=this && e.receiver==r )
				e.unplug();
	}

	public function unplug() {
		Fx.ME.cableCancel(this, cableEnd);
		cableOffsetDx = cableOffsetDy = 0;
		cableOffsetX = cableOffsetY = 0;
		cable.visible = false;
		if( receiver!=null )
			receiver.setPower(false);
		cableEnd = null;
		receiver = null;
		if( Game.ME.hero.curEmitter==this )
			Game.ME.hero.curEmitter = null;
	}

	override function unregister() {
		super.unregister();
		if( cable!=null )
			cable.parent.removeChild(cable);
		ALL.remove(this);
	}

	override function update() {
		super.update();


		cable.graphics.clear();
		if( cableEnd!=null && (isOnScreen() || cableEnd.isOnScreen()) ) {
			var dist = Lib.distance(xx,yy, cableEnd.xx, cableEnd.yy);
			var tension = dist/reach;

			if( cableEnd!=Game.ME.hero )
				cableOffsetX += Math.cos((uid+Game.ME.time)*0.06)*2;
			cableOffsetDx += -cableEnd.dx*20;
			cableOffsetDx += -cableOffsetX*0.07;
			cableOffsetX+=cableOffsetDx;
			cableOffsetDx*=0.7;

			if( cableOffsetY<30 )
				cableOffsetDy+=1.5;
			cableOffsetDy += cableEnd.dy*10;
			cableOffsetDy += -cableOffsetY*0.07;
			cableOffsetY+=cableOffsetDy;
			cableOffsetDy*=0.7;

			var col = tension<=0.8 || Game.ME.time%2==0 || cableEnd!=Game.ME.hero ? 0xF2BC00 : 0xF22400;
			cable.graphics.lineStyle(2, col, 1);
			cable.graphics.moveTo(xx-1,yy-5);

			var ctrlX = xx+(cableEnd.xx-xx)*0.5+cableOffsetX;
			var ctrlY = yy+(cableEnd.yy-yy)*0.3+cableOffsetY;
			var tenseX = xx+(cableEnd.xx-xx)*0.5;
			var tenseY = yy+(cableEnd.yy-yy)*0.5;
			var heroGrab = cableEnd==Game.ME.hero;
			ctrlX += (tenseX-ctrlX)*(tension*(heroGrab?rnd(0.98,1.04):1));
			ctrlY += (tenseY-ctrlY)*(tension*(heroGrab?rnd(0.98,1.04):1));

			cable.graphics.curveTo(
				ctrlX,
				ctrlY,
				cableEnd.xx,
				cableEnd.yy-3
			);

			// Lose
			if( dist>reach ) {
				Game.SBANK.cable(1);
				unplug();
			}
		}


		if( Game.ME.lowq )
			cable.filters = [];

		if( receiver!=null )
			receiver.setPower(active);

		if( isOnScreen() && Game.ME.time%4==0 && receiver==null )
			Fx.ME.powered(this);
	}
}
