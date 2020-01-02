package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Cable extends Entity {
	public var parent			: Entity;

	public function new(p) {
		super();
		parent = p;
		spr.graphics.beginFill(0xAFBAC9,1);
		spr.graphics.drawRect(-6, -1, 12, 2);
	}

	override function unregister() {
		super.unregister();
	}

	override function update() {
		super.update();
	}
}
