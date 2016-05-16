package game 
{
	import net.flashpunk.Entity;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.FP;
	
	public class DamageNum extends Entity
	{
		private var t:Text;
		private var life:Number;
		private static const DNUM_YSPEED:uint = 100;
		private static const DNUM_LIFE:Number = 0.8;
		
		public function DamageNum(c:uint, _x:Number, _y:Number, n:String) 
		{
			x = _x;
			y = _y;
			
			life = DNUM_LIFE;
			t = new Text(n);
			t.centerOO();
			t.color = c;
			graphic = t;
		}
		
		public function get tHeight():uint { return t.height; }
		
		public override function update():void
		{
			y -= FP.elapsed * DNUM_YSPEED;
			life -= FP.elapsed;
			if (life <= 0)
				FP.world.remove(this);
		}
	}

}