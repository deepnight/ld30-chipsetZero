import mt.deepnight.Buffer;
import mt.flash.Sfx;
import mt.deepnight.Lib;
import mt.MLib;
import mt.deepnight.slb.*;
import flash.display.Sprite;

@:bitmap("assets/tiles.png") class GfxTiles extends flash.display.BitmapData {}
@:bitmap("assets/displace.png") class GfxDisplace extends flash.display.BitmapData {}

class Game extends mt.deepnight.FProcess { //}
	public static var ME : Game;
	public static var SBANK = mt.flash.Sfx.importDirectory("assets/sounds");

	public var buffer		: Buffer;
	public var fx			: Fx;
	public var scene		: Sprite;
	var instagram			: BSprite;
	public var sdm			: mt.flash.DepthManager;
	public var tiles		: BLib;
	public var cine			: mt.deepnight.Cinematic;
	var displace			: flash.display.BitmapData;
	var displaceCleanUp		: flash.display.BitmapData;
	var lightBurn			: flash.display.Bitmap;

	public var level		: Level;
	public var hero			: en.Hero;
	public var viewport		: { x:Float, y:Float, wid:Float, hei:Float, dx:Float, dy:Float };

	public var music		: Sfx;
	public var wind			: Sfx;

	var ready				: Bool;
	public var lowq			: Bool;
	var slowFrames			: Int;

	public function new() {
		super();
		ME = this;
		lowq = false;
		ready = false;
		slowFrames = 0;

		fx = new Fx();
		cine = new mt.deepnight.Cinematic(Const.FPS);

		buffer = new Buffer(320,200, Const.UPSCALE, false, 0x0);
		root.addChild(buffer.render);
		buffer.setTexture( Buffer.makeScanline(Const.UPSCALE, 0xFFFFFF), 0.3, true);

		scene = new Sprite();
		buffer.dm.add(scene, Const.DP_BG);
		sdm = new mt.flash.DepthManager(scene);
		scene.graphics.beginFill(0x17141F,1);
		scene.graphics.drawRect(0,0,sw(),sh());

		lightBurn = new flash.display.Bitmap( buffer.createSimilarBitmap(false) );
		buffer.dm.add(lightBurn, Const.DP_FX);
		lightBurn.blendMode = ADD;
		lightBurn.bitmapData.fillRect(lightBurn.bitmapData.rect, 0x6BDBE4);

		tiles = new mt.deepnight.slb.BLib(new GfxTiles(0,0));
		tiles.setSliceGrid(32,32);
		tiles.sliceAnimGrid("idle", 8, 0,0, 2);
		tiles.sliceAnimGrid("idleCompact1", 8, 0,1, 2);
		tiles.sliceAnimGrid("idleCompact2", 8, 0,2, 2);
		tiles.sliceAnimGrid("run", 3, 2,0, 4);
		tiles.sliceAnimGrid("jumpUp", 1, 2,1);
		tiles.sliceAnimGrid("jumpDown", 1, 3,1);
		tiles.sliceAnimGrid("land", 6, 4,1);
		tiles.sliceAnimGrid("hang", 10, 2,2);
		tiles.sliceAnimGrid("wakeUp", 2, 3,2,4);
		tiles.sliceAnimGrid("hangIdle", 10, 7,2);

		tiles.sliceAnimGrid("botIdle", 10, 3,3, 2);
		tiles.sliceAnimGrid("botMove", 2, 3,3, 2);
		tiles.sliceGrid("botGun", 5,3, 2);
		tiles.sliceGrid("botOff", 8,3);
		tiles.sliceAnimGrid("botDeactivate", 3, 7,3, 2);

		tiles.sliceGrid("turret", 9,3);

		tiles.setSliceGrid(16,16);
		tiles.slice("bullet", 0,112, 16*5, 16);
		tiles.sliceGrid("wall", 0,6, 5);
		tiles.sliceGrid("darkWall1", 0,8, 3);
		tiles.sliceGrid("darkWall2", 3,8, 3);
		tiles.sliceGrid("powerHalf", 5,9, 2);
		tiles.sliceGrid("bg", 0,9, 5);
		tiles.sliceGrid("power", 0,10);
		tiles.sliceGrid("receiver", 1,10, 2);
		tiles.sliceGrid("hwall", 3,10, 2);
		tiles.sliceGrid("vwall", 5,10, 2);
		tiles.sliceGrid("arrow", 11,8);
		tiles.sliceGrid("emitterHuman", 12,8, 2);
		tiles.slice("light", 0,176, 3*16, 4*16, 2);
		tiles.slice("pods", 0,240, 176,65);
		tiles.slice("maintain", 176,224, 213,24);
		tiles.slice("hole", 64,304, 176,80);
		tiles.slice("alert", 0,304, 16*4,16*4);
		tiles.slice("instagram", 352,0, 160,160);
		tiles.slice("humanPod", 112,128, 32,32, 2);
		tiles.sliceAnim("humanIdle", 25, 112,160, 16,32);
		tiles.sliceAnim("humanAwaken", 4, 128,160, 16,32, 5);
		tiles.initBdGroups();

		viewport = { x:0, y:0, wid:sw(), hei:sh(), dx:0, dy:0 }

		instagram = tiles.get("instagram");
		instagram.width = sw();
		instagram.height = sh();
		instagram.blendMode = OVERLAY;
		buffer.dm.add(instagram, Const.DP_INTERF);

		displace = buffer.createSimilarBitmap(false);
		displace.fillRect(displace.rect, alpha(0x800000));
		var f = new flash.filters.DisplacementMapFilter(displace, pt0, flash.display.BitmapDataChannel.RED, flash.display.BitmapDataChannel.RED, 30, 5);
		buffer.postFilters.push(f);

		displaceCleanUp = displace.clone();
		displaceCleanUp.fillRect(displaceCleanUp.rect, alpha(0x800000));

		#if debug
		start();
		flash.Lib.current.addChild( new mt.flash.Stats() );
		#else
		new Intro(buffer);
		#end
	}

	public function start() {
		ready = true;
		level = new Level();
		Sfx.disable();

		var pt = level.getMarkers("player")[0];
		hero = new en.Hero(pt.cx, pt.cy);
		viewport.x = hero.xx;
		viewport.y = hero.yy;

		for(pt in level.getMarkers("emitter"))
			new en.Emitter(pt.cx, pt.cy);

		for(pt in level.getMarkers("emitterHalf"))
			new en.EmitterHalf(pt.cx, pt.cy);

		for(pt in level.getMarkers("receiver"))
			new en.Receiver(pt.cx, pt.cy);

		for(pt in level.getMarkers("offWall")) {
			var e = new en.act.Wall(pt.cx, pt.cy, false);
			e.horizontal = level.hasMarker("offWall", pt.cx-1, pt.cy) || level.hasMarker("offWall", pt.cx+1, pt.cy);
			e.redraw();
		}

		for(pt in level.getMarkers("onWall")) {
			var e = new en.act.Wall(pt.cx, pt.cy, true);
			e.horizontal = level.hasMarker("onWall", pt.cx-1, pt.cy) || level.hasMarker("onWall", pt.cx+1, pt.cy);
			e.redraw();
		}

		for(pt in level.getMarkers("humanOn"))
			new en.act.Human(pt.cx, pt.cy, true);

		for(pt in level.getMarkers("humanOff"))
			new en.act.Human(pt.cx, pt.cy, false);

		for(pt in level.getMarkers("bot"))
			new en.Bot(pt.cx, pt.cy);

		for(pt in level.getMarkers("turret"))
			new en.Turret(pt.cx, pt.cy);

		var pt = level.getCloseInternal(25,15);
		new en.CustomReceiver(pt.cx,pt.cy, "firstDoor");

		music = SBANK.music();
		music.setChannel(1);
		Sfx.setChannelVolume(1, 0.8);

		wind = SBANK.wind();
		wind.setChannel(2);

		#if !debug
		cine.create({
			hero.spr.a.play("hang", 9999);
			hero.cd.set("lock", 9999);
			1200;
			announce("Initializing maintenance unit...");
			2500;
			fx.hit(hero.xx, hero.yy-10, 0x00D2FF);
			Game.ME.glitch(Const.seconds(0.6), false);
			fx.electricDischarge(hero);
			SBANK.power02(0.7);
			1000;
			hero.yr+=0.2;
			hero.spr.a.play("wakeUp", 1).chainAndLoop("hangIdle");
			200>>SBANK.talk01(1);
			1000;
			hero.say("I am "+Const.TITLE+".");
			1900;
			announce("System ready.");
			1500;
			fx.sparks(hero);
			hero.cd.unset("lock");
			fx.hit(hero.xx, hero.yy, 0x0080FF);
			SBANK.pain03(0.4);
			570;
			Game.ME.glitch(Const.seconds(0.6), true);
			SBANK.land01(1);
			SBANK.land03(1);
			music.playLoop();
			2000;
			announce("NEW MISSION:\nSeveral human subjects were disconnected from the SYSTEM servers.");
			5500;
			announce("Find them and RECONNECT them to our virtual worlds.");
			2500;
			hero.say("Mission confirmed.");
			1500;
			hero.say("I robot. I obey.");
			500>>en.CustomReceiver.trigger("firstDoor");
			1000;
			hero.say("Luduuuuum!");
			500;
		});
		#end

		Sfx.enable();
		wind.playLoop();
		wind.setVolume(0);
	}



	override function unregister() {
		super.unregister();
		while( Entity.ALL.length>0 ) {
			Entity.ALL[0].destroy();
			Entity.ALL[0].unregister();
		}
		tiles.destroy();
		buffer.destroy();
		music.stop();
		wind.stop();

		displace.dispose(); displace = null;
		displaceCleanUp.dispose(); displaceCleanUp = null;
		lightBurn.bitmapData.dispose(); lightBurn.bitmapData = null;
		instagram.destroy();
		cine.destroy();
		level.destroy();

		sdm.destroy();
	}


	public function announce(str:String, ?col=0x313960) {
		SBANK.menu03(1);

		var bg = new flash.display.Sprite();

		var tf = Game.ME.createField('$str');
		bg.addChild(tf);
		tf.multiline = tf.wordWrap = true;
		if( tf.width>250 )
			tf.width = 250;
		tf.height = tf.textHeight+5;
		tf.x = 5;

		bg.graphics.beginFill(col,1);
		bg.graphics.drawRect(0,0,tf.x+tf.width,tf.y+tf.height);
		bg.filters = [
			new flash.filters.GlowFilter(0x0,0.25, 4,4,4, 1,true),
			new flash.filters.GlowFilter(0xFFFFFF,1, 2,2,4, 1,true),
		];

		var bmp = Lib.flatten(bg);
		bmp.filters = [
			new flash.filters.DropShadowFilter(4,80, 0x130A2E,0.5, 0,0, 1),
		];
		Game.ME.buffer.dm.add(bmp, Const.DP_INTERF);
		bmp.x = Game.ME.sw();
		bmp.y = Game.ME.sh()-bmp.height-40 + irnd(0,10,true);
		Game.ME.tw.create(bmp.x, Game.ME.sw()-bmp.width+2, 300);
		Game.ME.delayer.add(function() {
			Game.ME.tw.create(bmp.alpha,0, 1000).onEnd = function() {
				bmp.parent.removeChild(bmp);
				bmp.bitmapData.dispose();
				bmp.bitmapData = null;
			}
		}, 2500+str.length*30);
	}


	public function createField(txt:Dynamic, ?fit=true) {
		var f = new flash.text.TextFormat("def",8,0xFFFFFF);
		var tf = new flash.text.TextField();
		tf.defaultTextFormat = f;
		tf.setTextFormat(f);
		tf.htmlText = Std.string(txt);
		tf.embedFonts = true;
		if( fit ) {
			tf.width = tf.textWidth+8;
			tf.height= tf.textHeight+5;
		}
		tf.selectable = tf.mouseEnabled = tf.mouseWheelEnabled = false;
		return tf;
	}


	public inline function doOnce(k:String) {
		if( cd.has("event_"+k) )
			return false;
		else {
			cd.set("event_"+k, 999999);
			return true;
		}
	}

	public inline function around(cx,cy) {
		return Lib.distanceSqr(cx,cy, hero.cx, hero.cy)<=4*4;
	}


	function updateTutorial() {
		if( around(30,15) && doOnce("controls") ) {
			cine.create({
				fx.arrow(27, 15, "Press SPACE here");
				1000;
				fx.arrow(32, 13, "...Connect here!");
			});
		}

		if( around(60,15) && doOnce("job") ) {
			cine.create({
				hero.say("Must connect humans.");
				2000;
				hero.say("I robot. I obey.");
			});
		}

		if( around(71,15) && doOnce("saveMe") ) {
			var e = Entity.getAt(74,11);
			cine.create({
				e.say("Help! ", true);
				//2000;
				//hero.say("I robot. I obey.");
			});
		}

		if( around(88,30) && doOnce("alert") ) {
			var p = createTinyProcess();
			var f = mt.deepnight.Color.getColorizeFilter(0x970000, 0,1);
			if( !lowq )
				buffer.postFilters.push(f);
			p.onUpdate = function() {
				var r = 0.4 + Math.sin(p.time*0.3)*0.2;
				f.matrix = mt.deepnight.Color.getColorizeFilter(0x970000, r,1-r).matrix;
				if( p.time>=Const.seconds(15) )
					p.destroy();
			}
			p.onDestroy = function() {
				buffer.postFilters.remove(f);
			}
			p.pause();
			cine.create({
				announce("ERROR: The System has encountered a problem and needs to destroy you.", 0x840000);
				1000;
				p.resume();
				4500;
				announce("ERROR #18. ERROR #1009. ERROR #404. ERROR: too many errors.", 0x840000);
			});
		}


		if( around(12,66) && doOnce("discoverHole") ) {
			cine.create({
				hero.say("???");
				1500;
				hero.say("UNKNOWN ERROR found in the wall!");
			});
		}
	}



	public inline function sw() return buffer.width;
	public inline function sh() return buffer.height;

	public function glitch(d:Float, strong:Bool) {
		cd.set("glitch", d);
		if( !strong )
			cd.set("glitchLight", d);
	}

	public function updateScroller() {
		if( cd.has("scroller") )
			return;

		var tx = hero.xx;
		var ty = hero.yy-15;
		var speed = 0.020; // 0.008
		if( Lib.distanceSqr(tx,ty, viewport.x, viewport.y)>=25*25 ) {
			viewport.dx += (tx - viewport.x)*speed;
			viewport.dy += (ty - viewport.y)*speed;
		}
		viewport.x+=viewport.dx;
		viewport.y+=viewport.dy;
		if( MLib.fabs(viewport.dx)<=0.15 )
			viewport.dx = 0;
		if( MLib.fabs(viewport.dy)<=0.15 )
			viewport.dy = 0;

		viewport.x = MLib.fmax(viewport.x, viewport.wid*0.5+10 );
		viewport.x = MLib.fmin(viewport.x, level.wid*Const.GRID-viewport.wid*0.5+10 );
		viewport.y = MLib.fmax(viewport.y, viewport.hei*0.5+10 );

		scene.x = Std.int(-viewport.x+viewport.wid*0.5);
		scene.y = Std.int(-viewport.y+viewport.hei*0.5);
		viewport.dx*=0.85;
		viewport.dy*=0.85;
	}


	public inline function fps() return mt.Timer.fps();


	override function update() {
		super.update();

		if( !ready )
			return;

		mt.flash.Key.update();
		#if debug
		if( mt.flash.Key.isToggled(flash.ui.Keyboard.S) )
			cd.set("scroller", Const.seconds(30));

		if( mt.flash.Key.isToggled(flash.ui.Keyboard.T) )
			trace(en.act.Human.getStats());

		if( mt.flash.Key.isToggled(flash.ui.Keyboard.C) )
			trace(hero.cx+","+hero.cy);
		#end

		if( mt.flash.Key.isToggled(flash.ui.Keyboard.M) )
			Sfx.toggleMuteChannel(1);

		// Entities
		var gc = [];
		for(e in Entity.ALL) {
			if( !e.destroyAsked )
				e.update();
			if( e.destroyAsked )
				gc.push(e);
		}
		for(e in gc)
			e.unregister();
		gc = null;


		// Exit
		var exit = level.getCloseInternal(6,60);
		var d = Lib.distanceSqr(exit.cx, exit.cy, hero.cx+hero.xr, hero.cy+hero.yr);
		var maxDist = 4*4;
		lightBurn.visible = d<=maxDist;
		if( hero.cy<=49 )
			wind.mute();
		else {
			wind.unmute();
			wind.setVolume( MLib.fmax(0, 1-d/(25*25)) );
		}
		if( d<=maxDist ) {
			var r = d/maxDist;
			lightBurn.visible = true;
			lightBurn.alpha = rnd(0,0.02) + 0.7 * (1-d/maxDist);
			if( d<=1.5*1.5 && !cd.has("outro") ) {
				cd.set("outro", 99999);
				hero.cd.set("lock", 999999);
				new Outro(buffer);
			}
		}
		if( hero.cy>=60 )
			fx.exitDust(exit.cx, exit.cy);

		updateTutorial();
	}


	override function render() {
		super.render();

		if( ready ) {
			fx.update();
			cine.update();
			updateScroller();
			tiles.updateChildren();

			if( !lowq ) {
				if( cd.has("glitch") ) {
					cd.set("glitchCleanUp",Const.seconds(5));
					var r = new flash.geom.Rectangle(0, rnd(20,sh()-20), sw(), rnd(2,8));
					displace.fillRect(r, mt.deepnight.Color.makeColor(cd.has("glitchLight") ? rnd(0.52, 0.6) : rnd(0.7,1), 0,0));
					scene.x+=rnd(0,2,true);
				}
				if( cd.has("glitchCleanUp") )
					displace.draw(displaceCleanUp, new flash.geom.ColorTransform(1,1,1, cd.has("glitch") ? 0.4 : 0.6));
			}
		}

		buffer.update();
		Sfx.update();

		mt.Timer.update();
		if( !lowq && fps()<=23 ) {
			slowFrames++;
			if( slowFrames>=Const.seconds(1.3) ) {
				buffer.postFilters = [];
				lowq = true;
			}
		}
		else
			slowFrames = 0;
	}
}
