package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Bot extends en.Receiver {
	public static var ALL : Array<Bot> = [];

	var speed			: Float;
	public var min		: Int;
	public var max		: Int;
	var gunFront		: BSprite;
	var gunBack			: BSprite;

	public function new(x,y) {
		super(x,y);

		canGoInCollisions = false;
		ALL.push(this);
		speed = 0.02;
		allowAutoPlug = false;

		// Patrol range
		min = cx;
		max = cx;
		var level = Game.ME.level;
		var range = 5;
		var d = range;
		while( d>0 && level.hasCollision(min-1,cy+1) && !level.hasCollision(min-1,cy) && !level.hasMarker("onWall", min-1,cy+1) && !level.hasMarker("offWall", min-1,cy+1) ) {
			min--;
			d--;
		}
		var d = range;
		while( d>0 && level.hasCollision(max+1,cy+1) && !level.hasCollision(max+1,cy) && !level.hasMarker("onWall", max+1,cy+1) && !level.hasMarker("offWall", max+1,cy+1) ) {
			max++;
			d--;
		}


		dir = Std.random(2)*2-1;
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

		spr.a.registerStateAnim("botOff", 2, function() return !powered);
		spr.a.registerStateAnim("botMove", 1, function() return dx!=0);
		spr.a.registerStateAnim("botIdle", 0);
	}

	override function activateAround() {
	}

	override function setPower(p:Bool) {
		if( powered && !p ) {
			Game.SBANK.power01(0.3);
			spr.a.play("botDeactivate");
			Fx.ME.pop(this, "!!");
		}
		powered = p;
		//super.setPower(p);
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
		gunFront.destroy();
		gunBack.destroy();
	}

	override function update() {
		super.update();

		//gunBack.visible = gunFront.visible = powered;
		gunFront.x = spr.x+dir*5;
		gunFront.y = spr.y-10;
		gunBack.x = gunFront.x + dir*2;
		gunBack.y = gunFront.y - 1;

		if( !powered || !cd.has("walk") ) {
			var r = dir==-1 ? 180 : 0;
			gunFront.rotation += Lib.angularSubstractionDeg(r,gunFront.rotation)*0.3;
			gunBack.rotation = gunFront.rotation;
		}

		if( powered ) {
			if( !cd.has("walk") ) {
				if( dir==-1 && cx<=min && xr<=0.5 ) {
					cd.set("walk", 20);
					cd.onComplete("walk", function() {
						if( powered )
							dir = 1;
					});
				}
				if( dir==1 && cx>=max && xr>=0.5 ) {
					cd.set("walk", 20);
					cd.onComplete("walk", function() {
						if( powered )
							dir = -1;
					});
				}
				dx+=dir*speed;
			}

			var hero = Game.ME.hero;
			if( dir==-1 && hero.cx<cx || dir==1 && hero.cx>cx )
				if( !cd.has("shoot") && distanceSqr(hero)<=Const.GRID*7*Const.GRID*7 && Game.ME.level.sightCheck(cx,cy, hero.cx,hero.cy) ) {
					// Start shooting
					cd.set("shooting", rnd(5,10));
				}

			if( cd.has("shooting") && !cd.has("subShoot") ) {
				// Shoot
				Game.SBANK.gun01(rnd(0.5, 1));
				cd.set("walk", rnd(10,20));
				cd.set("shoot", cd.get("walk"));
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

				hero.onShoot();
				if( Game.ME.doOnce("shot") )
					hero.say("Not enemy! Don't shoot!");
			}
		}
	}
}
