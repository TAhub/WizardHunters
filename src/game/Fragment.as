package game 
{
	import flash.geom.Point;
	import net.flashpunk.Entity;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	
	public class Fragment extends Entity
	{
		private var typ:uint;
		private var spr:uint;
		private var z:Number;
		private var speed:Point;
		private var zSpeed:Number;
		private var timer:Number;
		private static const FRAG_TIMER:Number = 0.8;
		public static const FRAG_NUM:uint = 9;
		
		public function Fragment(_typ:uint, _x:Number, _y:Number, _z:Number) 
		{
			x = _x;
			y = _y;
			z = _z;
			typ = _typ;
			timer = FRAG_TIMER;
			
			speed = Point.polar(Main.data.fragments[typ][4], Math.random() * 2 * Math.PI);
			zSpeed = Main.data.fragments[typ][5];
			var sprS:uint = Main.data.fragments[typ][1];
			var sprE:uint = Main.data.fragments[typ][2];
			spr = Math.random() * (sprE - sprS + 1) + sprS;
		}
		
		public override function update():void
		{
			x += speed.x * FP.elapsed;
			y += speed.y * FP.elapsed;
			z += zSpeed * FP.elapsed;
			zSpeed -= Main.data.fragments[typ][6] * FP.elapsed;
			timer -= FP.elapsed;
			if (z < 0 || timer < 0)
				FP.world.remove(this);
		}
		
		public override function render():void
		{
			var sprF:Spritemap = Main.data.spriteSheets[10];
			sprF.frame = spr;
			sprF.color = Main.data.colors[Main.data.fragments[typ][3]][1];
			sprF.render(FP.buffer, new Point(x, y - z), FP.camera);
		}
	}

}