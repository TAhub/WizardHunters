package game 
{
	import net.flashpunk.FP;
	import flash.geom.Point;
	import net.flashpunk.graphics.Spritemap;
	
	public class Projectile 
	{
		private var x:Number;
		private var y:Number;
		private var dir:Point;
		private var damage:uint;
		private var moralePer:uint;
		private var good:Boolean;
		private var sprite:uint;
		private var color:uint;
		private var effectSkill:uint;
		private var hit:Creature;
		public var dead:Boolean;
		private static const PROJ_SIZE:uint = 5;
		private static const PROJ_INTERVAL:Number = 3;
		
		public function Projectile(_x:Number, _y:Number, _dir:Point, _damage:uint, _moralePer:uint, _good:Boolean, _sprite:uint, _color:uint, _effectSkill:uint)
		{
			x = _x;
			y = _y;
			dir = _dir;
			damage = _damage;
			moralePer = _moralePer;
			good = _good;
			sprite = _sprite;
			color = _color;
			effectSkill = _effectSkill;
			dead = false;
			hit = null;
		}
		
		public function update():void
		{
			var intervals:uint = Math.ceil(dir.length * FP.elapsed / PROJ_INTERVAL);
			
			for (var i:uint = 0; i < intervals; i++)
			{
				var toHit:Array;
				if (good)
					toHit = (FP.world as Map).enemies;
				else
					toHit = (FP.world as Map).players;
				
				for (var j:uint = 0; j < toHit.length; j++)
				{
					var maybeHit:Creature = toHit[j];
					
					if (!maybeHit.dead && maybeHit.active && maybeHit != hit &&
						(new Point(x - maybeHit.x, y - maybeHit.y).length < maybeHit.bodySize + PROJ_SIZE ||
						new Point(x - maybeHit.x, y - maybeHit.y + maybeHit.bodyHeight).length < maybeHit.bodySize + PROJ_SIZE ||
						new Point(x - maybeHit.x, y - maybeHit.y + maybeHit.bodyHeight / 2).length < maybeHit.bodySize + PROJ_SIZE))
					{
						maybeHit.takeHit(damage, moralePer);
						dead = true;
						if (effectSkill != Database.NONE && Main.data.effectSkills[effectSkill][3])
							switch (maybeHit.applyEffect(Main.data.effectSkills[effectSkill][1], Main.data.effectSkills[effectSkill][4]))
							{
							case 2:
								//attack bounces!
								bounce(maybeHit);
								break;
							}
						return;
					}
				}
				
				if ((FP.world as Map).pointSolid(x, y))
				{
					//(FP.world as Map).smash(x, y);
					dead = true;
					return;
				}
				
				x += dir.x * FP.elapsed / intervals;
				y += dir.y * FP.elapsed / intervals;
			}
		}
		
		private function bounce(maybeHit:Creature):void
		{
			if (hit == null)
			{
				hit = maybeHit;
				
				var target:Creature = null;
				var bestD:Number = Database.NONE;
				var toHit:Array;
				if (good)
					toHit = (FP.world as Map).enemies;
				else
					toHit = (FP.world as Map).players;
					
				for (var i:uint = 0; i < toHit.length; i++)
				{
					var tH:Creature = toHit[i];
					if (tH.onscreen && tH != hit && !tH.dead && tH.active)
					{
						var d:Number = new Point(x - tH.x , y - tH.y).length;
						if (d < bestD)
						{
							target = tH;
							bestD = d;
						}
					}
				}
				
				if (target != null)
				{
					//point towards that creature
					var newD:Point = new Point(target.x - x, target.y - target.bodyHeight / 2 - y);
					newD.normalize(dir.length);
					dir = newD;
					
					//after bouncing you do reduced damage
					damage *= Main.data.effects[2][2] * 0.01;
					
					//you successfully bounced, so don't die
					dead = false;
				}
			}
		}
		
		public function render():void
		{
			var spr:Spritemap = Main.data.spriteSheets[4];
			spr.angle = Math.atan2( -dir.y, dir.x) * 180 / Math.PI;
			spr.frame = sprite;
			spr.color = color;
			spr.render(FP.buffer, new Point(x, y), FP.camera);
		}
	}

}