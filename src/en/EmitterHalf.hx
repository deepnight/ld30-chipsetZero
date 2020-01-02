package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import flash.display.Sprite;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class EmitterHalf extends en.Emitter {
	public function new(x,y) {
		super(x,y);
		active = true;
		spr.set("powerHalf");
	}


	override function unregister() {
		super.unregister();
	}

	override function update() {
		super.update();
		if( Game.ME.time%30==0 )
			active = !active;

		if( receiver!=null ) {
			receiver.cd.set("noPowerOffSound", 30);
		}
		spr.set("powerHalf", active ?1:0);
	}
}
