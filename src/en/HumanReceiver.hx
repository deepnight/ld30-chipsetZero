package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class HumanReceiver extends Receiver {
	public function new(x,y) {
		super(x,y);
		reach = 0;
		spr.alpha = 0.5;
	}

	override function activateAround() {
		for(e in Activable.ALL)
			if( e.cx==cx && e.cy==cy+2 )
				e.setPower(powered);
	}

	override function unregister() {
		super.unregister();
	}

	override function update() {
		super.update();
	}
}
