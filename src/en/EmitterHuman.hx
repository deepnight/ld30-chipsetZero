package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import flash.display.Sprite;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class EmitterHuman extends en.Emitter {
	var linkedReceiver		: en.Receiver;
	public function new(x,y, r:en.Receiver) {
		super(x,y);
		linkedReceiver = r;
		active = true;
		spr.set("emitterHuman");
		flatten();
	}


	override function onPlugToReceiver(r:en.Receiver) {
		if( r==linkedReceiver )
			super.onPlugToReceiver(r);
	}

	override function unregister() {
		super.unregister();
	}

	override function update() {
		super.update();
	}
}
