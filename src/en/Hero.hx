package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Hero extends Entity {
	var speedX				: Float;
	var speedY				: Float;
	public var curEmitter	: Null<Emitter>;

	public function new(x,y) {
		super();
		setPosCase(x,y);
		speedX = 0.08;
		speedY = speedX*0.6;
		canGoInCollisions = false;

		setDepth(Const.DP_HERO);

		spr.a.registerStateAnim("run", 6, function() return grabbing && MLib.fabs(dy)>=speedY*0.5);
		spr.a.registerStateAnim("jumpUp", 5, function() return !stable && dy<=0.);
		spr.a.registerStateAnim("jumpDown", 4, function() return !stable && dy>0.);
		spr.a.registerStateAnim("run", 3, function() return stable && MLib.fabs(dx)>=speedX*0.5);
		spr.a.registerStateAnim("idleCompact2", 2, function() return !Game.ME.level.hasCollision(cx-1,cy+1) || !Game.ME.level.hasCollision(cx+1,cy+1));
		spr.a.registerStateAnim("idleCompact1", 1, function() return Game.ME.level.hasCollision(cx-1,cy) || Game.ME.level.hasCollision(cx+1,cy));
		spr.a.registerStateAnim("idle", 0);
	}


	override function unregister() {
		super.unregister();
	}


	override function onLand() {
		super.onLand();
		spr.a.play("land",1);
		if( dy>=0.5 ) {
			Game.SBANK.land01(rnd(0.3, 0.4));
			Fx.ME.land(this);
		}
		else if( dy>=0.12 )
			Game.SBANK.land04(rnd(0.2, 0.5));
	}


	public function onShoot() {
		Game.SBANK.hit01(1);
		if( !cd.has("pain") ) {
			cd.set("pain", Const.seconds(rnd(2,4)));
			mt.flash.Sfx.playOne([ Game.SBANK.pain01, Game.SBANK.pain02, Game.SBANK.pain03 ]);
		}
	}

	function tryToPlug(auto:Bool) {
		for(e in en.Receiver.ALL)
			if( distanceSqr(e)<=10*10 ) {
				if( !auto || e.getEmitter()==null && e.allowAutoPlug ) {
					curEmitter.onPlugToReceiver(e);
					Fx.ME.hit(e.xx, e.yy, 0x0193FE);
					curEmitter = null;
					//if( !cd.hasSet("comment", Const.seconds(10)) )
						//say(Const.RESTORE_POWER[Std.random(Const.RESTORE_POWER.length)]);
					break;
				}
			}
	}


	override function say(str, ?above) {
		super.say(str, above);
		mt.flash.Sfx.playOne([ Game.SBANK.talk01, Game.SBANK.talk02, Game.SBANK.talk03 ]);
	}


	override function update() {
		var level = Game.ME.level;
		var left = Key.isDown(Keyboard.Q) || Key.isDown(Keyboard.A) || Key.isDown(Keyboard.LEFT);
		var right = Key.isDown(Keyboard.D) || Key.isDown(Keyboard.RIGHT);
		var up = Key.isDown(Keyboard.Z) || Key.isDown(Keyboard.W) || Key.isDown(Keyboard.UP);
		var down = Key.isDown(Keyboard.S) || Key.isDown(Keyboard.DOWN);

		if( !cd.has("lock") && !cd.has("shoot") ) {
			// Walk
			if( left )
				dx-=speedX;

			if( right )
				dx+=speedX;

			// Climb right
			var diagEmpty = level.hasCollision(cx+grabX,cy) && !level.hasCollision(cx+grabX,cy-1);
			if( up && !left || right ) {
				var limit = diagEmpty ? 0.6 + 0.1*(1-yr) : 0.6;

				if( level.hasCollision(cx+1,cy) && xr>=limit ) {
					dir = 1;
					grabX = 1;
					jumpPow = 0;
					xr = limit;
					dx = diagEmpty ? 0.1 : 0;
					dy-=speedY;
					cd.set("jump", 7);
					if( diagEmpty && yr<=0.3 ) {
						dx = 0.3;
						jumpPow = 0.2;
						yr = 0.8;
						cy--;
					}
				}
			}

			// Climb left
			if( up && !right || left ) {
				var limit = diagEmpty ? 0.4 - 0.2*(1-yr) : 0.4;

				if( level.hasCollision(cx-1,cy) && xr<=limit ) {
					dir = -1;
					grabX = -1;
					jumpPow = 0;
					xr = limit;
					dx = diagEmpty ? -0.1 :0;
					dy-=speedY;
					cd.set("jump", 7);
					if( diagEmpty && yr<=0.3 ) {
						dx = -0.3;
						jumpPow = 0.2;
						yr = 0.8;
						cy--;
					}
				}
			}

			// Climb down
			if( down && grabbing ) {
				dy+=speedY;
			}

			if( !cd.has("jump") && up && stable && !grabbing )
				jumpPow = 0.41;

			if( grabbing && dy>=0 ) {
				Fx.ME.sparks(this);
				dy+=0.02;
			}

			if( grabbing )
				gravityInc = 0;

			// Leave grab
			if( grabbing ) {
				if( grabX>0 && !(level.hasCollision(cx+1,cy) && xr>=0.6) ) {
					if( left ) {
						dx = -0.2;
						jumpPow = 0.15;
						Fx.ME.wallJump(this);
					}
					else
						dx = 0.2;
					grabX = 0;
				}
				if( grabX<0 && !(level.hasCollision(cx-1,cy) && xr<=0.4) ) {
					if( right ) {
						dx = 0.2;
						jumpPow = 0.15;
						Fx.ME.wallJump(this);
					}
					else
						dx = -0.2;
					grabX = 0;
				}
			}
		}

		// Emitter management
		if( curEmitter!=null && !cd.has("autoPlug") )
			tryToPlug(true);

		if( !Key.isDown(Keyboard.SPACE) )
			cd.unset("use");

		if( !cd.has("use") && Key.isDown(Keyboard.SPACE) ) {
			cd.set("use", 30);
			if( curEmitter!=null ) {
				// Plug to a receiver
				tryToPlug(false);

				// No valid target
				if( curEmitter!=null ) {
					curEmitter.unplug();
					curEmitter = null;
				}
			}
			else {
				for(e in en.Emitter.ALL) {
					// Grab cable (receiver)
					if( e.cableEnd!=null && MLib.iabs(e.cableEnd.cx-cx)<=1 && MLib.iabs(e.cableEnd.cy-cy)<=1 ) {
						curEmitter = e;
						Fx.ME.hit(e.cableEnd.xx, e.cableEnd.yy, 0xFF8000);
						e.onCableGrab(this);
						cd.set("autoPlug", Const.seconds(1));
						Fx.ME.electricDischarge(this);
						break;
					}
					// Grab cable (emitter)
					if( distance(e)<=20 ) {
						curEmitter = e;
						Fx.ME.hit(e.xx, e.yy, 0x0193FE);
						e.onCableGrab(this);
						cd.set("autoPlug", Const.seconds(0.15));
						Fx.ME.electricDischarge(this);
						break;
					}
				}
			}
		}

		if( jumpPow!=0 && stable ) {
			Game.SBANK.jump03(1);
			Fx.ME.jump(this);
		}

		super.update();

		if( grabbing ) {
			if( grabX==1 ) {
				spr.rotation += Lib.angularSubstractionDeg(-90,spr.rotation)*0.5;
				spr.x+=8;
			}
			else {
				spr.rotation += Lib.angularSubstractionDeg(90,spr.rotation)*0.5;
				spr.x-=8;
			}
		}
		else
			spr.rotation*=0.5;
		if( spr.a.isPlayingAnim("run") ) {
			if( !cd.has("step") ) {
				if( grabbing ) {
					cd.set("step", 5);
					Game.SBANK.foot05(rnd(0.1, 0.2));
				}
				else {
					cd.set("step", 4);
					Game.SBANK.foot04(rnd(0.1, 0.2));
				}
			}
			Fx.ME.walkSmoke(this);
			spr.x+=Math.cos(Game.ME.time*0.3)*1;
		}
	}
}
