package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Receiver extends Entity {
	public static var ALL : Array<Receiver> = [];

	public var powered			: Bool;
	public var reach			: Int;
	public var allowAutoPlug	: Bool;

	public function new(x,y) {
		super();
		powered = false;
		allowAutoPlug = true;
		ALL.push(this);
		setPosCase(x,y);
		setDepth(Const.DP_MECHANISM);
		gravity = 0;
		reach = 2;

		spr.set("receiver");
	}

	public function getEmitter() {
		for(e in Emitter.ALL)
			if( e.cableEnd==this )
				return e;
		return null;
	}

	inline function coordToId(cx,cy) return cx+cy*1024;

	function activateAround() {
		var allMap = new Map();
		for(e in Activable.ALL)
			allMap.set( coordToId(e.cx,e.cy), e );

		function rec(x,y, range) {
			for(x in x-range...x+range+1)
				for(y in y-range...y+range+1) {
					var id = coordToId(x,y);
					if( allMap.exists(id) ) {
						var e = allMap.get(id);
						allMap.remove(id);
						e.setPower(powered);
						rec(e.cx, e.cy, 1);
					}
				}
		}
		rec(cx,cy,reach);
	}

	public function setPower(p:Bool) {
		if( powered && !p && !cd.has("noPowerOffSound") )
			Game.SBANK.power01(0.3);

		powered = p;

		spr.set("receiver", getEmitter()!=null && powered ? 1 : 0);

		activateAround();

		//var tagMap = new Map();
//
		//function rec(x,y) {
			//if( tagMap.exists(coordToId(x,y)) )
				//return;
//
			//tagMap.set(coordToId(x,y), true);
			//for(e in Activable.ALL)
				//if( MLib.iabs(cx-e.cx)<=1 &&  MLib.iabs(cy-e.cy)<=1 ) {
					//e.setPower(powered);
				//}
		//}
//
		//rec(cx, cy);
		//for(e in Activable.ALL)
			//if( MLib.iabs(cx-e.cx)<=1 &&  MLib.iabs(cy-e.cy)<=1 ) {
				//e.setPower(powered);
				//tagMap.set(coordToId(e.cx, e.cy), true);
			//}
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function update() {
		super.update();
		if( isOnScreen() && spr.visible && powered && Game.ME.time%2==0 )
			Fx.ME.powered(this);
	}
}
