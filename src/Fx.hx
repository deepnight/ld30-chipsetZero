import flash.display.BlendMode;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import mt.MLib;
import mt.deepnight.Particle;
import mt.deepnight.Lib;
import mt.deepnight.Color;

import Const;

class Fx {
	public static var ME : Fx;

	var game			: Game;
	var pt0				: flash.geom.Point;
	var lowq(get,never)	: Bool;

	public function new() {
		ME = this;
		game = Game.ME;
		pt0 = new flash.geom.Point(0,0);
	}

	public function register(p:Particle, ?b:BlendMode) {
		game.sdm.add(p, Const.DP_FX);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}

	public function destroy() {
		pt0 = null;
		game = null;
		Particle.clearAll();
		bulletCache.dispose();
		bulletCache = null;
	}

	inline function rnd(min,max,?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min,max,?sign) { return Lib.irnd(min,max,sign); }
	inline function fps() return mt.Timer.fps();
	inline function get_lowq() return Game.ME.lowq;

	public function hit(x,y, ?col=0xFF0000) {
		var r = Const.GRID*0.6;
		var p = new mt.deepnight.Particle(x,y);
		p.drawCircle(r, col, 1);
		p.ds = 0.05;
		p.life = 0;
		p.filters = [
			new flash.filters.GlowFilter(col, 0.5, 8,8,4),
		];
		register(p);

		var p = new mt.deepnight.Particle(x,y);
		p.drawCircle(r*1.2, col, 0.5, false);
		p.ds = 0.1;
		p.life = 0;
		register(p);
	}

	public function powered(e:Entity) {
		var p = new mt.deepnight.Particle(e.xx+rnd(0,2,true),e.yy-rnd(0,8));
		p.graphics.lineStyle(1, 0xC1F0FF, rnd(0.4, 1));
		p.graphics.moveTo(-rnd(3,4), rnd(0,3,true));
		p.graphics.lineTo(-rnd(0,2), rnd(0,4,true));
		p.graphics.lineTo(rnd(1,3), rnd(0,3,true));
		p.graphics.lineTo(rnd(3,4), rnd(0,3,true));
		p.rotation = rnd(0,50,true);
		p.ds = -rnd(0.05, 0.10);
		p.dy = -rnd(0.1,0.3);
		p.frict = 0.9;
		p.life = 0;
		p.filters = [
			new flash.filters.GlowFilter(0x00BFFF, 0.8, 8,8,4),
		];
		register(p);
	}



	public function arrow(cx,cy, ?str:String) {
		var x = (cx+0.5)*Const.GRID;
		var y = (cy+0.5)*Const.GRID;
		var p = new mt.deepnight.Particle(x, y);
		var s = game.tiles.get("arrow");
		s.setCenter(0.5, 1);
		p.addChild(s);
		p.dy = -3;
		p.gy = rnd(0.3,0.4);
		p.frict = 0.8;
		p.onBounce = function() {
			p.dy = -2.5;
		}
		p.onKill = function() {
			s.destroy();
		}
		p.life = Const.seconds(8);
		p.groundY = y;
		register(p, NORMAL);

		if( str!=null ) {
			var tf = Game.ME.createField(str);
			var p = new mt.deepnight.Particle(x, y-10);
			p.addChild(tf);
			p.dy = -6;
			p.frict = 0.8;
			p.life = Const.seconds(8);
			tf.x = Std.int(-tf.textWidth*0.5);
			tf.filters = [
				new flash.filters.GlowFilter(0x0,0.6, 2,2,4),
			];
			register(p, NORMAL);
		}
	}



	public function pop(e:Entity, str:String) {
		var tf = Game.ME.createField(str);
		var p = new mt.deepnight.Particle(e.xx, e.yy-10);
		p.addChild(tf);
		p.dy = -10;
		p.frict = 0.8;
		tf.x = Std.int(-tf.textWidth*0.5);
		tf.filters = [
			new flash.filters.DropShadowFilter(1,90, 0x0,0.4, 0,0)
		];
		register(p, NORMAL);
	}


	public function electricDischarge(e:Entity) {
		for(i in 0...30) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,6,true),e.yy-rnd(0,10));
			p.graphics.lineStyle(1, 0xC1F0FF, rnd(0.4, 1));
			p.graphics.moveTo(-rnd(3,4), rnd(0,3,true));
			p.graphics.lineTo(-rnd(0,2), rnd(0,4,true));
			p.graphics.lineTo(rnd(1,3), rnd(0,3,true));
			p.graphics.lineTo(rnd(3,4), rnd(0,3,true));
			p.rotation = rnd(0,50,true);
			p.ds = -rnd(0.05, 0.10);
			p.dy = -rnd(0.1,0.3);
			p.delay = i + rnd(0,2,true);
			p.frict = 0.9;
			p.life = 0;
			p.filters = [
				new flash.filters.GlowFilter(0x00BFFF, 0.8, 8,8,4),
			];
			register(p);
		}
	}


	public function cableCancel(from:Entity, to:Entity) {
		var n = 15;
		var a = Math.atan2(to.yy-from.yy, to.xx-from.xx);
		var d = Lib.distance(from.xx, from.yy, to.xx, to.yy);
		for(i in 0...n) {
			var p = new mt.deepnight.Particle(from.xx+Math.cos(a)*d*i/n-6, from.yy+Math.sin(a)*d*i/n-6);
			p.drawBox(rnd(5,8),2, 0xFF0000);
			p.rotation = MLib.toDeg(a);
			p.moveAng(a, rnd(0.2, 0.3, true));
			p.filters = [ new flash.filters.GlowFilter(0xFF0000,0.5, 8,8,2) ];
			p.gy = rnd(0.03, 0.12);
			p.ds = -rnd(0.05, 0.10);
			p.life = rnd(5, 15);
			p.frict = 0.9;
			register(p);
		}
	}

	var bulletCache : BitmapData;
	public function bullet(from:Entity, to:Entity) {
		if( bulletCache==null )
			bulletCache = game.tiles.getBitmapData("bullet");

		var fx = from.xx;
		var fy = from.yy-11;
		var tx = to.xx;
		var ty = to.yy-8;
		var a = Math.atan2(ty-fy, tx-fx);
		var d = Lib.distance(fx,fy, tx,ty) + rnd(0,15);
		fx+=Math.cos(a)*15+rnd(0,1,true);
		fy+=Math.sin(a)*15+rnd(0,1,true);

		// Gun
		var p = new mt.deepnight.Particle(fx,fy);
		p.drawCircle(rnd(4,6), 0xFFFF00, rnd(0.9,1));
		p.ds = rnd(0.1, 0.2);
		p.life = rnd(1,3);
		p.fadeOutSpeed = 0.3;
		p.filters = [ new flash.filters.GlowFilter(0xFF5300,1,8,8,3) ];
		register(p);

		// Impact
		var p = new mt.deepnight.Particle(tx+rnd(0,3,true),ty+rnd(0,3,true));
		p.drawCircle(rnd(3,5), 0xB3FAFF, rnd(0.9,1));
		p.ds = rnd(0.1, 0.2);
		p.life = rnd(1,3);
		p.fadeOutSpeed = 0.3;
		p.filters = [ new flash.filters.GlowFilter(0x009FFF,1,8,8,3) ];
		register(p);

		// Bullet
		for(i in 0...3) {
			var a = a+rnd(0,0.05,true);
			var p = new mt.deepnight.Particle(fx+Math.cos(a)*d*0.1, fy+Math.sin(a)*d*0.1);
			var bmp = new flash.display.Bitmap(bulletCache);
			p.addChild(bmp);
			bmp.x = -bmp.width*0.5;
			bmp.y = -bmp.height*0.5;
			p.life = rnd(1,5);
			p.moveAng(a, rnd(20,30));
			p.ds = -0.1;
			p.fadeOutSpeed = 0.2;
			p.rotation = MLib.toDeg(a);
			p.delay = i+rnd(0,1);
			p.onKill = function() {
				bmp.bitmapData = null;
				bmp.parent.removeChild(bmp);
			}
			p.filters = [ new flash.filters.GlowFilter(0xFF8000,0.8, 16,16,1) ];
			register(p);
		}

		// Hit dots
		for(i in 0...(lowq?1:5)) {
			var p = new mt.deepnight.Particle(tx+rnd(0,4,true), ty+rnd(0,5,true));
			p.drawBox(1,1, 0xffffff,1);
			p.filters = [ new flash.filters.GlowFilter(0x009FFF,1,4,4,4) ];
			p.dx = (fx>tx ? 1 : -1) * rnd(-1, 4);
			p.dy = rnd(-8,1);
			p.gy = rnd(0.2,0.4);
			p.frict = 0.9;
			p.life = rnd(5,15);
			register(p);
		}

		// Canon  dots
		for(i in 0...(lowq?1:5)) {
			var p = new mt.deepnight.Particle(fx+rnd(0,1,true), fy);
			p.drawBox(1,1, 0xFFFF00,1);
			p.filters = [ new flash.filters.GlowFilter(0xFF8000,1,4,4,4) ];
			p.dx = Math.cos(3.14+a)*rnd(1,4);
			p.dy = rnd(-4,-1);
			p.gy = rnd(0.1,0.3);
			p.frict = 0.9;
			p.life = rnd(5,15);
			register(p);
		}
	}


	public function alert(x,y, ?sy=1.0) {
		var p = new mt.deepnight.Particle(x,y);
		var s = game.tiles.get("alert");
		s.setCenter(0.5,0.5);
		s.alpha = 0.35;
		p.addChild(s);
		p.da = 0.4;
		p.alpha = 0;
		p.scaleY = sy;
		p.life = 3;
		p.fadeOutSpeed = 0.05;
		p.onKill = function() {
			s.destroy();
		}
		register(p);
	}


	public function land(e:Entity) {
		for(i in 0...10) {
			var p = new mt.deepnight.Particle(e.xx, e.yy+rnd(0,2));
			p.drawCircle(rnd(1,3), 0x99A4B5, rnd(0.3,0.7));
			p.dx = rnd(1,3, true);
			p.gy = -rnd(0.01,0.04);
			p.frict = 0.8;
			p.ds = rnd(0.02, 0.06);
			p.life = rnd(6,10);
			p.fadeOutSpeed = rnd(0.1, 0.2);
			p.filters = [
				new flash.filters.BlurFilter(2,2),
				new flash.filters.DropShadowFilter(4,-90, 0x0,0.5, 0,0,1, 1,true),
			];
			register(p, NORMAL);
		}
	}


	public function doorSmoke(e:Entity) {
		for(i in 0...(lowq ? 2 : 5)) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,5,true), e.yy+rnd(0,4,true)-5);
			p.drawCircle(rnd(4,6), 0x99A4B5, rnd(0.3,0.7));
			p.dx = 0;
			p.gy = -rnd(0.01,0.04);
			p.frict = 0.8;
			p.ds = rnd(0.02, 0.06);
			p.life = rnd(5,20);
			p.fadeOutSpeed = rnd(0.1, 0.2);
			p.filters = [
				new flash.filters.BlurFilter(2,2),
				new flash.filters.DropShadowFilter(4,-90, 0x0,0.5, 0,0,1, 1,true),
			];
			register(p, NORMAL);
		}
	}


	public function walkSmoke(e:Entity) {
		if( lowq ) return;

		var p = new mt.deepnight.Particle(e.xx, e.yy);
		if( e.grabbing )
			p.setPos(p.x+6*e.dir, p.y+rnd(0,5,true));
		else
			p.setPos(p.x+rnd(0,5,true), p.y);
		p.drawCircle(rnd(1,2), 0xDFE6F2, rnd(0.3,0.7));
		if( e.grabbing ) {
			p.dy = -e.dy*10;
			p.gy = rnd(0,0.2);
		}
		else {
			p.dx = -e.dx*10;
			p.gy = -rnd(-0.01,0.1);
		}
		p.frict = 0.8;
		p.ds = rnd(0.02, 0.06);

		p.life = rnd(5,10);
		p.fadeOutSpeed = 0.03;
		p.filters = [
			new flash.filters.BlurFilter(2,2),
			new flash.filters.DropShadowFilter(2,-90, 0x0,0.5, 0,0,1, 1,true),
		];
		register(p, NORMAL);
	}

	public function sparks(e:Entity) {
		for(i in 0...10) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,1)+e.dir*7, e.yy+rnd(0,10));
			p.drawBox(1, 1, 0xFFCC00, rnd(0.4, 1));
			p.dx = rnd(0.1,0.3) * (-e.dir);
			p.gx = rnd(0,0.03,true);
			p.dy = -rnd(1,4);
			p.frict = 0.9;
			p.gy = rnd(0.1, 0.4);
			p.life = rnd(2,8);
			register(p);
			p.filters = [ new flash.filters.GlowFilter(0xDE533A,1, 4,4,2) ];
		}
	}

	public function jump(e:Entity) {
		for(i in 0...10) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,4,true), e.yy-rnd(0,3));
			p.drawBox(1, 1, 0x927041, rnd(0.4, 1));
			p.dx = rnd(0,0.2,true) + e.dx*3;
			p.gx = rnd(0,0.03,true);
			p.dy = e.dy*10-e.jumpPow*2 - rnd(0,0.5);
			p.frict = 0.95;
			p.gy = rnd(0.1, 0.2);
			p.groundY = e.yy;
			p.life = rnd(2,10);
			register(p, NORMAL);
			//p.filters = [ new flash.filters.GlowFilter(0xF87721,1, 4,4,2) ];
		}
	}



	public function wallJump(e:Entity) {
		for(i in 0...10) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,1,true) + e.dir*8, e.yy+rnd(0,5,true));
			p.drawBox(1, 1, 0x927041, rnd(0.4, 1));
			p.dx = rnd(0,0.2,true) + e.dx*3;
			p.gx = rnd(0,0.03,true);
			p.dy = e.dy*10-e.jumpPow*2 - rnd(0,0.5);
			p.frict = 0.95;
			p.gy = rnd(0.1, 0.2);
			p.life = rnd(2,10);
			register(p, NORMAL);
		}
	}



	public function exitDust(cx,cy) {
		var x = (cx)*Const.GRID;
		var y = (cy-1)*Const.GRID;
		var a = 148;

		var p = new mt.deepnight.Particle(x-rnd(20,2),y+rnd(0,30));
		p.alpha = 0;
		p.da = rnd(0.05, 0.1);
		p.drawBox(1,1, 0x64CDD9,rnd(0.5,0.7));
		p.moveAng( MLib.toRad(a), rnd(0.2, 0.4) );
		register(p, ADD);
		p.frict = 0.96;
		p.life = rnd(20, 40);
		p.fadeOutSpeed = 0.03;
		p.gx = -rnd(0.01, 0.03);
		p.gy = rnd(0,0.01);
		p.filters = [ new flash.filters.GlowFilter(0x64CDD9,0.8, 8,8,6) ];

		if( !lowq )
			for(i in 0...2) {
				var p = new mt.deepnight.Particle(x-rnd(-20,260), y+32-rnd(0,15));
				p.drawCircle(rnd(6,10), 0x8CBCC1, rnd(0.3,0.7));
				p.alpha = 0;
				p.da = 0.01;
				p.dx = 0;
				p.gy = -rnd(0,0.06);
				p.frict = 0.8;
				p.life = rnd(20,40);
				p.fadeOutSpeed = rnd(0.003, 0.006);
				p.filters = [
					new flash.filters.BlurFilter(16,4),
					//new flash.filters.DropShadowFilter(4,-90, 0x0,0.8, 0,0,1, 1,true),
				];
				register(p);
			}
	}


	public function update() {
		var v = game.viewport;
		Particle.DEFAULT_BOUNDS = new flash.geom.Rectangle(v.x-v.wid*0.5, v.y-v.hei*0.5, v.wid, v.hei);
		Particle.update();
	}
}
