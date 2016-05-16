package game 
{
	import flash.geom.Point;
	import net.flashpunk.FP;
	
	public class Enemy extends Creature
	{
		//ai variables
		private var finalBossTimer:Number;
		private var target:Creature;
		private var aim:Number;
		private var aimPoint:Number;
		private var retreatFade:Number;
		private var curDir:Point;
		private static const AI_NOMOVECHANCE:Number = 0.09;
		private static const AI_RANDOMMOVECHANCE:Number = 0.09;
		private static const AI_MELEEMOVECHANCE:Number = 0.25;
		private static const AI_INAPPROPRIATERANGEDCHANCE:Number = 0.3;
		private static const AI_DIRCHANGECHANCE:Number = 1.8;
		private static const AI_ACQUIRERANGE:Number = 320;
		private static const AI_RETREATFADE:Number = 0.6;
		private static const AI_FADEPOINT:Number = 0.25;
		private static const AI_MELEERANGEFUDGE:Number = 1.3;
		
		public function Enemy(_x:Number, _y:Number, _template:uint, enemyRank:uint) 
		{
			super(_x, _y, false, _template, false, enemyRank);
			
			aimPoint = Main.data.templates[_template][13] * 0.01;
			
			target = null;
			aim = -1;
			retreatFade = 1;
			curDir = new Point(0, 0);
			finalBossTimer = 0;
		}
		
		public override function get disappear():Boolean
		{
			if (health != 0 && morale == 0)
			{
				//check to see if you are properly offscreen
				return retreatFade == 0;
			}
			else
				return false;
		}
		
		private function acquireTarget():void
		{
			if (!onscreen)
				return;
			var toTarget:Array = (FP.world as Map).players;
			var closestD:Number = 0;
			for (var i:uint = 0; i < toTarget.length; i++)
			{
				var maybeTarget:Creature = toTarget[i];
				var d:Number = new Point(x - maybeTarget.x, y - maybeTarget.y).length;
				if (!maybeTarget.dead && (d <= AI_ACQUIRERANGE || effectSkill == 2 || isInjured) && (target == null || d < closestD))
				{
					target = maybeTarget;
					closestD = d;
				}
			}
		}
		
		public override function render():void
		{
			if (retreatFade < AI_FADEPOINT)
				alpha = retreatFade / AI_FADEPOINT;
			super.render();
		}
		
		public override function update():void
		{
			if (!active)
			{
				//deactive enemies always are missing one moral; it's to make 100% sure that they acquire a target immediately
				morale = maxMorale - 1;
				return;
			}
			
			super.update();
			
			if (health == 0 || morale == 0)
			{
				//retreat
				if (health != 0)
				{
					if (target == null)
						acquireTarget();
					if (target != null)
					{
						var ret:Point = new Point(x - target.x, y - target.y);
						ret.normalize(1);
						move(ret.x, ret.y);
					}
				}
				
				retreatFade -= FP.elapsed * AI_RETREATFADE;
				if (retreatFade < 0)
					retreatFade = 0;
				
				return;
			}
			
			if (effectSkill == 2)
			{
				//boss stuff
				var lFBT:Number = finalBossTimer;
				finalBossTimer += FP.elapsed;
				
				var smokeEnd:Boolean = false;
				
				var lBurst:uint = lFBT / (Main.data.effects[6][3] * 0.01);
				var burst:uint = finalBossTimer / (Main.data.effects[6][3] * 0.01);
				if (finalBossTimer > burst * Main.data.effects[6][3] * 0.01 + (Main.data.effects[6][3] - Main.data.effects[6][7]) * 0.01)
				{
					//give off smoke
					var lSmoke:uint = lFBT / (Main.data.effects[6][6] * 0.01);
					var smoke:uint = finalBossTimer / (Main.data.effects[6][6] * 0.01);
					if (lSmoke < smoke)
						effectBubble(6);
					smokeEnd = true;
				}
				if (lBurst < burst)
					for (i = 0; i < Main.data.effects[6][5]; i++)
						attack(false, true, Point.polar(1, Math.PI * 2 * i / Main.data.effects[6][5]), true, i == 0);
						
				if (smokeEnd)
					return;
				
				var lTele:uint = lFBT / (Main.data.effects[6][2] * 0.01);
				var tele:uint = finalBossTimer / (Main.data.effects[6][2] * 0.01);
				if (lTele < tele)
				{
					for (var i:uint = 0; i < Main.data.effects[6][4]; i++)
						effectBubble(6);
						
					soundEffect(5);
					
					//teleport to a random spot
					do
					{
						x = Math.random() * (FP.world as Map).pWidth;
						y = Math.random() * (FP.world as Map).pHeight;
					}
					while (!spaceEmpty)
					
					for (i = 0; i < Main.data.effects[6][4]; i++)
						effectBubble(6);
				}
			}
			
			if (target != null && target.dead)
				target = null;
			if (target == null)
			{
				acquireTarget();
				aim = -1;
			}
			else if (cooldown <= 0)
			{
				var dif:Point = new Point(target.x - x, target.y - y);
				var dis:Number = dif.length;
				dif.normalize(1);
				
				var oUM:Boolean = usingM;
				var mRange:Boolean = false;
				var rRange:Boolean = false;
				if (hasMelee)
				{
					usingM = true;
					mRange = dis < meleeRangeEstimate * AI_MELEERANGEFUDGE;
				}
				if (hasRanged)
				{
					rRange = perfectAim ||
							Math.abs(y - target.y) < target.bodyHeight ||
							Math.abs(x - target.x) < target.bodySize;
				}
				
				var desDir:Point = new Point(0, 0);
				if (Math.random() < AI_NOMOVECHANCE)
					desDir = new Point(0, 0);
				else if (Math.random() < AI_RANDOMMOVECHANCE)
					desDir = Point.polar(1, Math.random() * 2 * Math.PI);
				else if (hasMelee || Math.random() < AI_MELEEMOVECHANCE)
				{
					//melee people always move in closer
					desDir = new Point(dif.x, dif.y);
				}
				else if (!rRange)
				{
					//ranged people will move towards the closer axist, and away from the longer axis
					var rMove:Point = new Point(Math.abs(dif.x), Math.abs(dif.y));
					if (Math.abs(dif.x) < Math.abs(dif.y))
					{
						rMove.x /= dif.x;
						rMove.y /= -dif.y;
					}
					else
					{
						rMove.x /= -dif.x;
						rMove.y /= dif.y;
					}
					rMove.normalize(1);
					desDir = new Point(rMove.x, rMove.y);
				}
				
				if (Math.random() < AI_DIRCHANGECHANCE * FP.elapsed)
					curDir = desDir;
					
				if (curDir.x != 0 || curDir.y != 0)
					if (!move(curDir.x, curDir.y))
						curDir = new Point(0, 0);
				
				if (mRange || rRange)
				{
					if (aim == -1)
						aim = 0;
					aim += FP.elapsed;
				}
				else
				{
					usingM = oUM;
					aim = -1;
				}
				
				var inR:Boolean = hasRanged && Math.random() < FP.elapsed * AI_INAPPROPRIATERANGEDCHANCE;
				if (mRange)
				{
					usingM = true;
					
					if (aim > aimPoint)
						attack(true, false, dif);
				}
				else if (rRange || inR)
				{
					usingM = false;
					
					if (aim > aimPoint || inR)
						attack(false, true, dif);
				}
			}
		}
	}

}