import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import mt.deepnight.Lib;
import mt.MLib;

@:bitmap("assets/levels.png") class GfxLevels extends flash.display.BitmapData {}

enum CellType {
	@col(0xCECECE) C_Wall;
	@col(0x80FF00) @txt("E") C_Emit;
	@col(0x408000) @txt("R") C_Receiv;
}

class Cell {
	public var cx			: Int;
	public var cy			: Int;
	public var collide		: Bool;
	public function new(x,y) {
		cx = x;
		cy = y;
		//collide = cy>=7 && (cx>=8 || cx<=1);// || Std.random(100)<20;
		collide = false;
	}
}

class Level {
	//public var data			: TinyLevel<CellType>;
	public var wid			: Int;
	public var hei			: Int;
	var map					: Array<Array<Cell>>;
	var markers				: Map<String, Array<{cx:Int, cy:Int}>>;

	var wrapper				: Sprite;
	public var bg			: Bitmap;

	public function new() {
		wid = 100;
		hei = 100;

		wrapper = new Sprite();
		Game.ME.sdm.add(wrapper, Const.DP_BG);

		bg = new flash.display.Bitmap( new flash.display.BitmapData(wid*Const.GRID, hei*Const.GRID, true, 0x0) );
		wrapper.addChild(bg);

		readData();

		//for(cx in 0...wid)
			//map[cx][hei-1].collide = true;

		render();
	}

	function readData() {
		markers = new Map();

		map = new Array();
		for(cx in 0...wid) {
			map[cx] = new Array();
			for(cy in 0...hei)
				map[cx][cy] = new Cell(cx,cy);
		}

		var source = new GfxLevels(0,0);
		for(cx in 0...wid)
			for(cy in 0...hei) {
				var p = source.getPixel(cx,cy);
				var c = map[cx][cy];
				switch( p ) {
					case 0xffffff : c.collide = true;
					case 0x00ff00 : addMarker("emitter", cx,cy);
					case 0xfff000 : addMarker("emitterHalf", cx,cy);
					case 0x3976c9 : addMarker("receiver", cx,cy);
					case 0x721111 : addMarker("offWall", cx,cy);
					case 0x979797 : addMarker("onWall", cx,cy);
					case 0xffb400 : addMarker("light", cx,cy);
					#if debug
					case 0x00bdb2 : addMarker("player", cx,cy);
					#else
					case 0xFF00FF : addMarker("player", cx,cy);
					#end
					case 0xFF0000 : addMarker("internal", cx,cy);
					case 0xb5506f : addMarker("humanOn", cx,cy);
					case 0x5f2a3a : addMarker("humanOff", cx,cy);
					case 0x7800ff : addMarker("bot", cx,cy);
					case 0x3ea77e : addMarker("turret", cx,cy);
					default :
				}

			}
		source.dispose();
	}

	function addMarker(id:String, cx,cy) {
		if( !markers.exists(id) )
			markers.set(id,new Array());
		markers.get(id).push({ cx:cx, cy:cy });
	}

	public inline function getMarkers(id) {
		return markers.exists(id) ? markers.get(id) : [];
	}

	public function hasMarker(id,cx,cy) {
		for(pt in getMarkers(id))
			if( pt.cx==cx && pt.cy==cy )
				return true;
		return false;
	}

	public function getCloseInternal(cx,cy) {
		var best : {cx:Int, cy:Int} = null;
		for(pt in getMarkers("internal"))
			if( best==null || Lib.distanceSqr(best.cx,best.cy,cx,cy)>Lib.distanceSqr(pt.cx,pt.cy,cx,cy) )
				best = pt;
		return best;
	}

	public function destroy() {
		map = null;
		wrapper.parent.removeChild(wrapper);

		bg.bitmapData.dispose();
		bg.bitmapData = null;
		bg.parent.removeChild(bg);
		bg = null;
	}


	public function sightCheck(x1,y1, x2,y2) {
		return mt.deepnight.Bresenham.checkThinLine(x1,y1, x2,y2, function(x,y) return !hasCollision(x,y));
	}

	public inline function isValid(cx,cy) return cx>=0 && cx<wid && cy>=0 && cy<hei;
	public inline function get(cx,cy) return map[cx][cy];
	public inline function hasCollision(cx,cy) return !isValid(cx,cy) ? true : map[cx][cy].collide;

	public function render() {
		var pt0 = new flash.geom.Point();
		var bd = bg.bitmapData;
		bd.fillRect(bd.rect,0x0);

		var walls = bd.clone();

		var lib = Game.ME.tiles;
		for(cx in 0...wid)
			for(cy in 0...hei) {
				var x = cx*Const.GRID;
				var y = cy*Const.GRID;
				lib.drawIntoBitmapRandom(bd,x,y,"bg");
				if( hasCollision(cx,cy) ) {
					lib.drawIntoBitmapRandom(walls,x,y,"darkWall"+(cy>=32?1:2));
					//if( hasCollision(cx,cy-1) && hasCollision(cx,cy+1) && hasCollision(cx-1,cy) && hasCollision(cx+1,cy) && (!hasCollision(cx+1,cy+1)  || !hasCollision(cx-1,cy+1)  || !hasCollision(cx-1,cy-1)  || !hasCollision(cx+1,cy-1)) )
						//lib.drawIntoBitmap(walls,x,y,"wall",0);
					//if( !hasCollision(cx,cy-1) )	lib.drawIntoBitmap(walls,x,y,"wall", 1);
					//if( !hasCollision(cx,cy+1) )	lib.drawIntoBitmap(walls,x,y,"wall", 2);
					//if( !hasCollision(cx-1,cy) )	lib.drawIntoBitmap(walls,x,y,"wall", 3);
					//if( !hasCollision(cx+1,cy) )	lib.drawIntoBitmap(walls,x,y,"wall", 4);
					//if( !hasCollision(cx+1,cy+1) || !hasCollision(cx-1,cy+1)  || !hasCollision(cx-1,cy-1)  || !hasCollision(cx+1,cy-1) )
						//lib.drawIntoBitmap(walls,x,y,"wall",0);
				}
			}

		//walls.applyFilter(walls, walls.rect, pt0, new flash.filters.GlowFilter(0x0,0.1, 8,10,100, 1,true));
		//walls.applyFilter(walls, walls.rect, pt0, new flash.filters.GlowFilter(0xb3b9c8,1, 8,10,100, 1,true));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.GlowFilter(0x0,0.3, 4,4,10, 1,true));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.GlowFilter(0xffffff,0.8, 2,2,4, 1,true));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.DropShadowFilter(2,-90, 0x0,0.2, 0,0,1, 1,true));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.DropShadowFilter(1,-90, 0xEF5629,0.6, 0,0,1, 1,true));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.DropShadowFilter(1,180, 0x4592EF,0.6, 0,0,1, 1,true));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.DropShadowFilter(2,-90, 0x5B657D,1, 0,0));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.DropShadowFilter(1,-90, 0x0,0.1, 0,0));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.DropShadowFilter(10,0, 0x0,0.2, 0,8));
		walls.applyFilter(walls, walls.rect, pt0, new flash.filters.GlowFilter(0x0C0B1A,0.8, 32,64,2, 2));

		var alphaMap = walls.clone();

		var perlin = walls.clone();
		perlin.perlinNoise(8,8,2, 1866, false, true, 1, true);
		perlin.threshold(perlin, perlin.rect, pt0, "<", 0xff888888, 0x0, 0xffffffff);
		perlin.threshold(perlin, perlin.rect, pt0, ">", 0xffaaaaaa, 0x0, 0xffffffff);
		perlin.threshold(perlin, perlin.rect, pt0, ">", 0x00000000, 0xff000000, 0xff000000);
		walls.draw(perlin, new flash.geom.ColorTransform(1,1,1,0.05), flash.display.BlendMode.OVERLAY);
		walls.copyChannel(alphaMap, alphaMap.rect, pt0, flash.display.BitmapDataChannel.ALPHA, flash.display.BitmapDataChannel.ALPHA);

		perlin.perlinNoise(8,128,2, 1866, false, true, 1, true);
		perlin.threshold(perlin, perlin.rect, pt0, "<", 0xff888888, 0x0, 0xffffffff);
		perlin.threshold(perlin, perlin.rect, pt0, ">", 0xffaaaaaa, 0x0, 0xffffffff);
		perlin.threshold(perlin, perlin.rect, pt0, ">", 0x00000000, 0xff000000, 0xff000000);
		bd.draw(perlin, new flash.geom.ColorTransform(1,1,1,0.1), flash.display.BlendMode.OVERLAY);

		bd.copyPixels(walls, walls.rect, pt0,true);


		var light0 = lib.getBitmapData("light",0);
		var light1 = lib.getBitmapData("light",1);
		var ct = new flash.geom.ColorTransform();
		for(pt in getMarkers("light")) {
			var m = new flash.geom.Matrix();
			m.translate((pt.cx-1)*Const.GRID, (pt.cy*Const.GRID));
			//m.scale(Lib.rnd(1,2), 1);
			ct.alphaMultiplier = Lib.rnd(0.5, 0.7);
			bd.draw(light0, m, ct, flash.display.BlendMode.OVERLAY);
			bd.draw(light0, m, ct, flash.display.BlendMode.OVERLAY);
			bd.draw(light1, m, flash.display.BlendMode.ADD);
		}
		light0.dispose();
		light1.dispose();


		// Start pods
		var pt = getCloseInternal(10,10);
		lib.drawIntoBitmapRandom(bd, pt.cx*Const.GRID, pt.cy*Const.GRID, "pods");

		// Maintain label
		var sbd = lib.getBitmapData("maintain");
		var m = new flash.geom.Matrix();
		m.translate(pt.cx*Const.GRID-30, pt.cy*Const.GRID+60);
		bd.draw(sbd, m, new flash.geom.ColorTransform(1,1,1, 1), OVERLAY);
		sbd.dispose();

		// Hole
		var pt = getCloseInternal(6,60);
		lib.drawIntoBitmap(bd, (pt.cx-6)*Const.GRID, (pt.cy-3)*Const.GRID-2, "hole");


		perlin.dispose();
		alphaMap.dispose();
		walls.dispose();
	}
}