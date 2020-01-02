package en.act;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Wall extends en.Activable {
	var defaultState		: Bool;
	public var horizontal	: Bool;

	public function new(x,y, def:Bool) {
		defaultState = def;
		horizontal = false;
		super(x,y);
	}

	override function setPower(p:Bool) {
		var old = powered;
		super.setPower(p);
		Game.ME.level.get(cx,cy).collide = powered ? !defaultState : defaultState;
		redraw();
		if( old!=powered )
			Fx.ME.doorSmoke(this);
	}

	public function redraw() {
		var k = horizontal ? "hwall" : "vwall";
		spr.set(k, Game.ME.level.hasCollision(cx,cy) ? 0 : 1);
	}

	override function unregister() {
		super.unregister();
	}

	override function update() {
		super.update();
		if( horizontal )
			spr.y -= 1;
	}
}
