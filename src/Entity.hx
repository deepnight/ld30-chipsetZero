import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Entity {
	public static var ALL : Array<Entity> = [];

	public var spr			: BSprite;
	public var destroyAsked	: Bool;
	public var uid			: Int;

	public var cx			: Int;
	public var cy			: Int;
	public var xr			: Float;
	public var yr			: Float;
	public var xx			: Float;
	public var yy			: Float;
	public var dx			: Float;
	public var dy			: Float;
	public var dir			: Int;
	var frict				: Float;
	var gravity				: Float;
	var gravityInc			: Float;
	var stable				: Bool;
	public var jumpPow		: Float;
	var grabX				: Int;
	public var grabbing(get,never)	: Bool;

	public var cd			: mt.Cooldown;

	var history				: Array<{cx:Int, cy:Int}>;
	var canGoInCollisions	: Bool;

	public function new() {
		ALL.push(this);
		uid = Game.ME.getUniqId();
		stable = false;
		history = [];
		canGoInCollisions = true;

		spr = new BSprite(Game.ME.tiles);
		Game.ME.sdm.add(spr, Const.DP_ENTITY);
		spr.set(Game.ME.tiles);
		spr.setCenter(0.5,1);

		cd = new mt.Cooldown();
		cd.set("init", 1);

		dir = 1;
		dx = dy = 0;
		gravity = 0.12;
		gravityInc = 0;
		setPosCase(0,0);
		frict = 0.5;
		grabX = 0;
		jumpPow = 0;
	}

	inline function setDepth(d:Int) Game.ME.sdm.add(spr, d);
	public function toString() return '#$uid';
	public function distance(e:Entity) return Lib.distance(xx,yy, e.xx,e.yy);
	public function distanceSqr(e:Entity) return Lib.distanceSqr(xx,yy, e.xx,e.yy);
	inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);
	inline function get_grabbing() return grabX!=0;

	function flatten() {
		updateSprite();
		spr.lib.drawIntoBitmap( Game.ME.level.bg.bitmapData, spr.x, spr.y, spr.groupName, spr.frame, spr.pivot.centerFactorX, spr.pivot.centerFactorY );
		spr.visible = false;
	}

	public static function getAt(cx,cy) {
		for(e in ALL)
			if( e.cx==cx && e.cy==cy )
				return e;
		return null;
	}


	public function destroy() destroyAsked = true;
	public function unregister() {
		spr.destroy();
		cd.destroy();
		ALL.remove(this);
	}

	public function setPosCase(x,y) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
		updateSprite();
	}

	public function setPosFree(x:Float,y:Float) {
		cx = Std.int(x/Const.GRID);
		cy = Std.int(y/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;
		yr = (y-cy*Const.GRID)/Const.GRID;
		updateSprite();
	}

	function onLand() {
		gravityInc = 0;
	}


	public function say(str:String, ?above=false) {
		var bg = new flash.display.Sprite();

		var col = 0x36243E;

		var tf = Game.ME.createField('$str', true);
		bg.addChild(tf);
		tf.multiline = tf.wordWrap = true;
		if( tf.width>250 )
			tf.width = 250;
		tf.height = tf.textHeight+5;
		tf.x = 10;

		bg.graphics.beginFill(col,1);
		var w = tf.x+tf.width;
		var h = tf.y+tf.height;
		bg.graphics.drawRect(0,0, w, h);
		if( !above ) {
			bg.graphics.moveTo(w*0.5,-5);
			bg.graphics.lineTo(w*0.5-4,0);
			bg.graphics.lineTo(w*0.5+4,0);
		}
		else {
			bg.graphics.moveTo(w*0.5,h+5);
			bg.graphics.lineTo(w*0.5-4,h);
			bg.graphics.lineTo(w*0.5+4,h);
		}
		bg.filters = [
			new flash.filters.GlowFilter(0x0,0.25, 4,4,4, 1,true),
			new flash.filters.GlowFilter(0xFFFFFF,1, 2,2,4, 1,true),
		];

		var bmp = Lib.flatten(bg);
		bmp.filters = [
			new flash.filters.DropShadowFilter(4,80, 0x130A2E,0.5, 0,0, 1),
		];
		Game.ME.sdm.add(bmp, Const.DP_INTERF);
		bmp.scaleX = 0;

		var p = Game.ME.createTinyProcess();
		p.onUpdate = function() {
			bmp.x = Std.int(xx-bmp.width*0.5);
			bmp.y = above ? yy-38-bmp.height : yy+3;
		}

		Game.ME.tw.create(bmp.scaleX,1, 200);

		Game.ME.delayer.add(function() {
			Game.ME.tw.create(bmp.alpha,0, 1000).onEnd = function() {
				bmp.parent.removeChild(bmp);
				bmp.bitmapData.dispose();
				bmp.bitmapData = null;
				p.destroy();
			}
		}, 2500+str.length*30);
	}


	function updateSprite() {
		xx = Const.GRID*(cx+xr);
		yy = Const.GRID*(cy+yr);
		spr.x = Std.int(xx);
		spr.y = Std.int(yy);
		if( dx>=0.05 ) dir = 1;
		if( dx<=-0.05 ) dir = -1;
		spr.scaleX = MLib.fabs(spr.scaleX)*dir;
	}

	public inline function isOnScreen() {
		var v = Game.ME.viewport;
		return
			xx>=v.x-v.wid*0.6 && xx<=v.x+v.wid*0.6 &&
			yy>=v.y-v.hei*0.6 && yy<=v.y+v.hei*0.6;
	}

	public function update() {
		cd.update();

		var level = Game.ME.level;

		// Bug fallback
		if( !canGoInCollisions ) {
			if( history.length==0 || history[history.length-1].cx!=cx || history[history.length-1].cy!=cy ) {
				history.push({ cx:cx, cy:cy });
			}
			while( history.length>0 && level.hasCollision(cx,cy) ) {
				var pt = history.pop();
				cx = pt.cx;
				cy = pt.cy;
				xr = yr = 0.5;
			}
		}


		if( !grabbing && (yr<1 || dy!=0 || !level.hasCollision(cx,cy+1) || jumpPow!=0) )
			stable = false;

		// X
		xr+=dx;
		if( grabbing && level.hasCollision(cx-1,cy) && xr<0.1 ) {
			xr = 0.1;
			dx = 0;
		}
		if( !grabbing && level.hasCollision(cx-1,cy) && xr<0.4 ) {
			xr = 0.4;
			dx = 0;
		}
		if( grabbing && level.hasCollision(cx+1,cy) && xr>0.9 ) {
			xr = 0.9;
			dx = 0;
		}
		if( !grabbing && level.hasCollision(cx+1,cy) && xr>0.6 ) {
			xr = 0.6;
			dx = 0;
		}
		while( xr>1 ) { xr--; cx++; }
		while( xr<0 ) { xr++; cx--; }

		dx*=frict;
		if( MLib.fabs(dx)<=0.005 )
			dx = 0;


		// Y
		if( !cd.has("lock") && !grabbing && !stable && gravity!=0 ) {
			gravityInc+=0.004;
			dy+=gravity+gravityInc; // gravity
		}

		dy-=jumpPow;
		jumpPow*=0.91;
		if( jumpPow<=0.05 )
			jumpPow = 0;
		yr+=dy;
		if( level.hasCollision(cx,cy+1) && yr>1 && !stable ) {
			onLand();
			yr = 1;
			dy = 0;
			jumpPow = 0;
			grabX = 0;
			stable = true;
		}
		if( level.hasCollision(cx,cy-1) && yr<0.8 ) {
			dy += 0.15;
		}
		if( level.hasCollision(cx,cy-1) && yr<0.4 ) {
			yr = 0.4;
			dy = 0.2;
		}
		while( yr>1 ) { yr--; cy++; }
		while( yr<0 ) { yr++; cy--; }

		dy*=frict;
		if( MLib.fabs(dy)<=0.005 )
			dy = 0;


		updateSprite();
	}
}
