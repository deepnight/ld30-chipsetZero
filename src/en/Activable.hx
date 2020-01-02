package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Activable extends Entity {
	public static var ALL : Array<Activable> = [];
	public var powered		: Bool;

	public function new(x,y) {
		super();
		powered = false;
		ALL.push(this);
		setPosCase(x,y);
		setDepth(Const.DP_BG);
		gravity = 0;

		setPower(false);
	}

	public function setPower(p:Bool) {
		powered = p;
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function update() {
		super.update();
	}
}
