package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Turret extends en.Receiver {
	var gunFront		: BSprite;
	var gunBack			: BSprite;

	public function new(x,y) {
		super(x,y);

		allowAutoPlug = false;

		dir = Game.ME.level.hasCollision(cx-1, cy) || Game.ME.level.hasCollision(cx-2, cy) ? 1 :-1;
		setDepth(Const.DP_MOBS);

		gunFront = Game.ME.tiles.get("botGun",0);
		Game.ME.sdm.add(gunFront, Const.DP_MOBS);
		gunFront.setCenter(0.5,0.5);

		gunBack = Game.ME.tiles.get("botGun",1);
		Game.ME.sdm.add(gunBack, Const.DP_MOBS_BG);
		gunBack.setCenter(0.5,0.5);

		var best : en.Emitter = null;
		for(e in en.Emitter.ALL)
			if( best==null || Lib.distanceSqr(best.cx,best.cy,cx,cy)>Lib.distanceSqr(e.cx,e.cy,cx,cy) )
				best = e;
		best.onPlugToReceiver(this);

		spr.set("turret");
	}

	override function activateAround() {
	}

	override function setPower(p:Bool) {
		if( powered && !p ) {
			Game.SBANK.power01(0.3);
			Fx.ME.pop(this, "!!");
		}
		powered = p;
	}

	override function unregister() {
		super.unregister();
		gunFront.destroy();
		gunBack.destroy();
	}

	override function update() {
		super.update();

		gunFront.x = spr.x;
		gunFront.y = spr.y-10;
		gunBack.x = gunFront.x + dir*2;
		gunBack.y = gunFront.y - 1;

		if( !powered || !cd.has("walk") ) {
			var r = dir==-1 ? 180 : 0;
			gunFront.rotation += Lib.angularSubstractionDeg(r,gunFront.rotation)*0.3;
			gunBack.rotation = gunFront.rotation;
		}

		if( powered ) {
			var hero = Game.ME.hero;
			var range = Const.GRID*9;
			if( dir==-1 && hero.cx<cx || dir==1 && hero.cx>cx )
				if( !cd.has("shoot") && distanceSqr(hero)<=range*range && Game.ME.level.sightCheck(cx,cy, hero.cx,hero.cy) ) {
					// Start shooting
					cd.set("shooting", rnd(5,10));
				}

			if( cd.has("shooting") && !cd.has("subShoot") ) {
				// Shoot
				cd.set("shoot", rnd(5,10));
				cd.set("subShoot", rnd(2, 3));
				dx = 0;
				hero.cd.set("stun", Const.seconds(0.9));
				hero.dx+=dir*rnd(0.3, 0.8);
				if( hero.stable || Std.random(100)<40 )
					hero.dy-=rnd(0.2, 0.6);
				Fx.ME.bullet(this, hero);

				var a = MLib.toDeg( Math.atan2(hero.yy-yy, hero.xx-xx) );
				gunFront.rotation = a;
				gunBack.rotation = a;
				gunFront.x += -dir*rnd(3,5);

				Game.ME.glitch(Const.seconds(0.25), true);

				spr.x+=-dir*rnd(0,2);
				spr.y+=-rnd(0,1);

				Game.SBANK.gun01(rnd(0.5, 1));
				hero.onShoot();
			}
		}

		if( !powered && Game.ME.time%30==0 )
			Fx.ME.alert(xx,yy-5, 0.7);
	}
}
