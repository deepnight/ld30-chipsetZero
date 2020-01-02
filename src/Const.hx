class Const { //}
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var UPSCALE = 3;
	public static var GRID = 16;
	public static var FPS = 30;

	public static inline function seconds(v:Float) return Std.int(v*FPS);

	private static var uniq = 0;
	public static var DP_BG = uniq++;
	public static var DP_ENTITY = uniq++;
	public static var DP_MECHANISM = uniq++;
	public static var DP_CABLE = uniq++;
	public static var DP_HERO = uniq++;
	public static var DP_MOBS_BG = uniq++;
	public static var DP_MOBS = uniq++;
	public static var DP_FX = uniq++;
	public static var DP_INTERF = uniq++;

	public static var TITLE = "CHIPSET-0";

	public static var RESTORE_POWER = [
		"Power restored!",
		"I like electricity. Much.",
		"Systems operational!",
	];
}
