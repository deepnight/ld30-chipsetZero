package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class CustomReceiver extends Receiver {
	static var ALL = [];
	var id		: String;
	public function new(x,y, k:String) {
		ALL.push(this);
		super(x,y);
		id = k;
		reach = 2;
		spr.alpha = 0.5;
		allowAutoPlug = false;
		spr.visible = false;
	}

	public static function trigger(id:String) {
		for(e in ALL)
			if( e.id==id )
				e.setPower(true);
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function update() {
		super.update();
	}
}
