package game 
{
	import flash.display.Sprite;
	import flash.geom.Point;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.FP;
	import net.flashpunk.Sfx;
	
	public class Creature 
	{
		//position and movement
		public var x:Number;
		public var y:Number;
		private var xP:Boolean;
		private var yP:Boolean;
		private var xOrY:Boolean;
		private var diag:Boolean;
		protected var lunge:Point;
		protected var knockback:Point;
		private static const MOVE_LUNGESLOW:Number = 1000;
		private static const MOVE_KNOCKBACKSLOW:Number = 3000;
		
		//combat constants
		private static const COMB_MAXAUTOAIM:Number = 0.12;
		private static const COMB_PLAYERHEALTHRESIST:Number = 0.25;
		private static const COMB_PLAYERMORALERESIST:Number = 0.18;
		private static const COMB_ENEMYMULT:Number = 1.3;
		private static const COMB_ENEMYSLOWD:Number = 1.8;
		private static const COMB_RANGEDSLOWD:Number = 1.2;
		private static const COMB_BASESLOWD:Number = 0.12;
		
		//states
		protected var cooldown:Number;
		public var active:Boolean;
		protected var health:uint;
		protected var morale:uint;
		
		//status effects
		protected var poison:Number;
		protected var slow:Number;
		protected var headtaker:Number;
		protected var fragile:Number;
		private static const EFFECT_TICKFREQUENCY:Number = 0.5;
		
		//stats
		protected var str:uint;
		protected var end:uint;
		protected var dex:uint;
		protected var mnd:uint;
		protected var cha:uint;
		public static const STAT_MAX:uint = 99;
		private static const STAT_BADDODGEPEN:uint = 12;
		private static const STAT_BASEHEALTH:uint = 100;
		private static const STAT_BASEHEALTHBAD:uint = 50;
		private static const STAT_STRLUNGE:Number = 0.0055;
		private static const STAT_STRMOVE:Number = 0.002;
		private static const STAT_STRDAMAGE:Number = 0.01;
		private static const STAT_DEXMOVE:Number = 0.008;
		private static const STAT_DEXCOOLDOWN:Number = 0.006;
		private static const STAT_DEXDODGE:Number = 0.3;
		private static const STAT_DEXDAMAGE:Number = 0.008;
		private static const STAT_MNDDAMAGE:Number = 0.005;
		
		//enemy scaling
		private static const SCALE_DAMAGESTATBOOST:uint = 10;
		private static const SCALE_HEALTHSTATMULT:Number = 0.6;
		private static const SCALE_HEALTHSTATBOOST:uint = 20;
		
		//appearance, etc
		private var template:uint;
		protected var phenome:uint;
		private var race:uint;
		private var good:Boolean;
		private var hair:uint;
		private var hairColor:uint;
		private var skinColor:uint;
		protected var alpha:Number;
		
		//equipment
		public var money:int;
		protected var effectSkill:uint;
		protected var armor:uint;
		protected var meleeW:uint;
		protected var rangedW:uint;
		protected var usingM:Boolean;
		
		//NPC stuff
		public var npcLine:uint;
		
		//drawing
		private static const DRAW_WALKSPEED:Number = 2.5;
		private var walk:Number;
		
		public function applyAppearance(aNum:uint, pNum:uint):void
		{
			hair = Main.data.appearances[aNum][1];
			phenome = Main.data.appearances[aNum][2];
			skinColor = Main.data.appearances[aNum][3];
			armor = Main.data.appearances[aNum][4];
			hairColor = Main.data.lists[1][1 + pNum];
		}
		
		public function Creature(_x:Number, _y:Number, _good:Boolean, _template:uint, npc:Boolean, enemyRank:uint = 0)
		{
			if (npc)
				initNPC(_x, _y, _template);
			else
				initNormal(_x, _y, _good, _template, enemyRank);
		}
		
		private function initNPC(_x:Number, _y:Number, npcTemplate:uint):void
		{
			x = _x;
			y = _y;
			good = true;
			
			template = 0; //for the purpose of everything that uses templates, you are template 0
							//this is mostly irrelevant stuff like movement though
			
			race = Main.data.npcTemplates[npcTemplate][1];
			meleeW = Main.data.npcTemplates[npcTemplate][2];
			rangedW = Database.NONE;
			effectSkill = Database.NONE;
			armor = Main.data.npcTemplates[npcTemplate][3];
			hair = Main.data.npcTemplates[npcTemplate][4];
			hairColor = Main.data.npcTemplates[npcTemplate][5];
			phenome = Main.data.npcTemplates[npcTemplate][6];
			skinColor = Main.data.npcTemplates[npcTemplate][7];
			
			npcLine = Main.data.npcTemplates[npcTemplate][8];
			
			//npc stats are set to make them immortal, hopefully
			str = 1;
			dex = 1;
			mnd = 1;
			end = 10000;
			cha = 10000;
			
			
			baseInit();
			xP = Math.random() < 0.5;
			
			if (Main.data.npcTemplates[npcTemplate][9])
				health = 0; //you're a corpse NPC
		}
		
		public function initNormal(_x:Number, _y:Number, _good:Boolean, _template:uint, enemyRank:uint):void
		{
			x = _x;
			y = _y;
			good = _good;
			
			npcLine = Database.NONE; //you aren't an NPC
			
			template = _template;
			phenome = Math.random() * Main.data.templates[template][7];
			race = Main.data.templates[template][1];
			
			str = Main.data.templates[template][8] + SCALE_DAMAGESTATBOOST * enemyRank;
			end = Main.data.templates[template][9] * (1 + SCALE_HEALTHSTATMULT * enemyRank) + enemyRank * SCALE_HEALTHSTATBOOST;
			dex = Main.data.templates[template][10] + SCALE_DAMAGESTATBOOST * enemyRank;
			mnd = Main.data.templates[template][11];
			cha = Main.data.templates[template][12] * (1 + SCALE_HEALTHSTATMULT * enemyRank) + enemyRank * SCALE_HEALTHSTATBOOST;
			effectSkill = Main.data.templates[template][14];
			
			hair = Main.data.templates[template][6];
			hair = Main.data.hairStyles[hair][Math.floor(Math.random() * (Main.data.hairStyles[hair].length - 1) / 2) * 2 + phenome + 1];
			
			var coloration:uint = Main.data.races[race][10];
			skinColor = Math.random() * (Main.data.colorations[coloration][2] - Main.data.colorations[coloration][1] + 1) +
										Main.data.colorations[coloration][1];
			hairColor = Math.random() * (Main.data.colorations[coloration][4] - Main.data.colorations[coloration][3] + 1) +
										Main.data.colorations[coloration][3];
			
			armor = Main.data.templates[template][5];
			meleeW = Main.data.templates[template][3];
			rangedW = Main.data.templates[template][4];
			
			baseInit();
			
			if (!good)
				trace(Main.data.templates[template][0] + " " + maxHealth + " " + maxMorale + "   " + weaponDamage);
			/**else
				money += 1000;/**/
		}
		
		private function baseInit():void
		{
			lunge = new Point(0, 0);
			knockback = new Point(0, 0);
			cooldown = 0;
			health = maxHealth;
			morale = maxMorale;
			usingM = hasMelee;
			xP = true;
			yP = true;
			xOrY = true;
			diag = false;
			walk = -1;
			alpha = 1;
			money = 0;
			active = true;
			poison = 0;
			slow = 0;
			headtaker = 0;
			fragile = 0;
		}
		
		//derived stats
		private function get moveSpeed():Number
		{
			var baseM:Number = Main.data.templates[template][2] * (1 + str * STAT_STRMOVE + dex * STAT_DEXMOVE) * (1 - 0.01 * Main.data.armors[armor][4]);
			
			if (slow > 0)
				baseM *= Main.data.effects[1][2] * 0.01;
				
			if (headtaker > 0)
				baseM *= Main.data.effects[4][4] * 0.01;
			
			return baseM;
		}
		private function get lungeMod():Number
		{
			//cap your str in case it's over max stat (for enemies, etc)
			var cStr:uint = str;
			if (cStr > STAT_MAX)
				cStr = STAT_MAX;
			
			var lM:Number = 1 + cStr * STAT_STRLUNGE;
			if (headtaker > 0)
				lM *= Main.data.effects[4][2] * 0.01;
			return lM;
		}
		private function get weaponCooldown():Number
		{
			//cap your dex in case it's over max stat (for enemies, etc)
			var cDex:uint = dex;
			if (cDex > STAT_MAX)
				cDex = STAT_MAX;
				
			var w:Number = Main.data.weapons[weapon][4] * 0.01 * (1 - cDex * STAT_DEXCOOLDOWN) / (1 - 0.01 * Main.data.armors[armor][4]);
			if (!good)
				w *= COMB_ENEMYSLOWD;
			if (Main.data.weapons[weapon][3])
				w *= COMB_RANGEDSLOWD;
			else if (headtaker > 0)
				w *= Main.data.effects[4][3] * 0.01;
			return w + COMB_BASESLOWD;
		}
		private function get defense():uint
		{
			var def:uint = 0;
			if (armor != Database.NONE)
				def += Main.data.armors[armor][3];
			return def;
		}
		private function get dodgeChance():uint
		{
			var dod:uint = dex * STAT_DEXDODGE;
			
			//apply the dodge chance penalty if you are an enemy
			if (good)
				return dod;
			else if (dod > STAT_BADDODGEPEN)
				return dod - STAT_BADDODGEPEN;
			else
				return 0;
		}
		protected function get maxHealth():uint
		{
			if (good)
				return STAT_BASEHEALTH + end;
			else
				return STAT_BASEHEALTHBAD + end;
		}
		protected function get maxMorale():uint
		{
			if (good)
				return STAT_BASEHEALTH + cha;
			else
				return STAT_BASEHEALTHBAD + cha;
		}
		public function get bodySize():uint { return Main.data.races[race][8]; }
		public function get bodyHeight():uint { return Main.data.races[race][9]; }
		public function get dead():Boolean { return morale == 0 || health == 0; }
		public function get disappear():Boolean { return false; }
		private function get weaponDamage():uint
		{
			var damage:uint = Main.data.weapons[weapon][6];
			var mult:Number = 1;
			if (Main.data.weapons[weapon][3])
				mult += STAT_DEXDAMAGE * dex;
			else
			{
				mult += STAT_STRDAMAGE * str;
				if (lungeMod > 0)
					mult += Main.data.effects[4][5] * 0.01;
			}
			if (Main.data.weapons[weapon][10])
				mult += STAT_MNDDAMAGE * mnd;
			return damage * mult;
		}
		private function get weapon():uint
		{
			if (usingM)
				return meleeW;
			else
				return rangedW;
		}
		
		public function get spaceEmpty():Boolean
		{
			return moveInner( -1, 0) == null && moveInner(1, 0) == null;
		}
		
		protected function move(xAdd:Number, yAdd:Number):Boolean
		{
			if (lunging || knockbacked)
				return false;
			
			if (xAdd < 0)
				xP = false;
			else if (xAdd > 0)
				xP = true;
			if (yAdd < 0)
				yP = false;
			else if (yAdd > 0 || (yAdd == 0 && xAdd != 0))
				yP = true;
				
			if (xAdd != 0 || yAdd != 0)
			{
				var dAdj:Point = new Point(xAdd, yAdd);
				dAdj.normalize(1);
				xAdd = dAdj.x;
				yAdd = dAdj.y;
				
				if (Math.abs(xAdd) > Math.abs(yAdd))
					xOrY = true;
				else if (Math.abs(xAdd) < Math.abs(yAdd))
					xOrY = false;
					
				diag = xAdd != 0 && yAdd != 0;
				
				walkAnim();
				
				return moveInner(xAdd * moveSpeed * FP.elapsed, yAdd * moveSpeed * FP.elapsed, true, good) == null;
			}
			else
			{
				walk = -1;
				return false;
			}
		}
		
		private function moveInner(xD:Number, yD:Number, canSlide:Boolean = false, borderCheck:Boolean = false, canSmash:Boolean = false):Creature
		{
			var dis:Number = new Point(xD, yD).length;
			var intervals:int = Math.ceil(dis);
			
			for (var i:uint = 0; i < intervals; i++)
			{
				var newX:Number = x + xD / intervals;
				var newY:Number = y + yD / intervals;
				
				//see if you hit a wall or a border
				for (var j:uint = 0; j < 5; j++)
				{
					var checkX:Number = newX;
					var checkY:Number = newY;
					switch(j)
					{
					case 0:
						checkX -= bodySize / 2;
						break;
					case 1:
						checkX += bodySize / 2;
						break;
					case 2:
						checkX -= bodySize / 2;
						checkY -= bodyHeight;
						break;
					case 3:
						checkX += bodySize / 2;
						checkY -= bodyHeight;
						break;	
					}
					
					if ((j == 4 && borderCheck && (newX - bodySize / 2 < FP.camera.x || newY - bodySize / 2 < FP.camera.y ||
						newX + bodySize / 2 > FP.camera.x + FP.width || newY + bodySize / 2 > FP.camera.y + FP.height)) ||
						(j != 4 && (FP.world as Map).pointSolid(checkX, checkY)))
					{
						if (canSlide)
						{
							//separate the remaining move into components
							if (xD != 0)
								moveInner((intervals - i) * dis * xD / (Math.abs(xD) * intervals), 0, false, borderCheck);
							if (yD != 0)
								moveInner(0, (intervals - i) * dis * yD / (Math.abs(yD) * intervals), false, borderCheck);
						}
						if (j != 4 && canSmash)
							(FP.world as Map).smash(checkX, checkY);
						return this;
					}
				}
				
				var maxJ:uint = 2; //bad guys move THROUGH npcs
				if (good)
					maxJ += 1;
				for (j = 0; j < maxJ; j++)
				{
					var toHit:Array;
					//hit the opposite first, and the same second
					if (j == 2)
						toHit = (FP.world as Map).npcs;
					else if ((good && j == 0) || (!good && j == 1))
						toHit = (FP.world as Map).enemies;
					else if ((FP.world as Map).town)
						toHit = new Array();
					else
						toHit = (FP.world as Map).players;
						
					for (var k:uint = 0; k < toHit.length; k++)
					{
						var maybeHit:Creature = toHit[k];
						
						//did you hit it?
						if (maybeHit != this && maybeHit.active && (!maybeHit.dead || maybeHit.npcLine != Database.NONE) &&
							new Point(newX - maybeHit.x, newY - maybeHit.y).length < bodySize + maybeHit.bodySize)
							return maybeHit; //you hit it
					}
				}
				
				x = newX;
				y = newY;
			}
			
			return null;
		}
		
		private function walkAnim():void
		{
			if (walk == -1)
					walk = 0;
					
			walk += FP.elapsed * DRAW_WALKSPEED;
			walk -= ((int) (walk));
		}
		
		protected function get perfectAim():Boolean { return effectSkill == 1 || effectSkill == 2; }
		
		protected function soundEffect(n:uint):void
		{
			var vol:Number;
			if (good)
				vol = Main.data.lists[2][n * 2 + 1] * 0.01;
			else
				vol = Main.data.lists[2][n * 2 + 2] * 0.01;
			Main.data.soundEffects[n].play(vol * Main.soundVol * 0.01);
		}
		
		protected function attack(mA:Boolean, rA:Boolean, dir:Point = null, forceAttack:Boolean = false, playSound:Boolean = true):Boolean
		{
			if (forceAttack || (!lunging && !knockbacked && (mA || rA) && cooldown <= 0))
			{
				usingM = mA;
				
				cooldown = weaponCooldown;
				
				//attack sound
				if (playSound)
					soundEffect(0);
				
				if (dir == null)
				{
					dir = new Point(0, 0);
					if (xP)
						dir.x = 1;
					else
						dir.x = -1;
					if (yP)
						dir.y = 1;
					else
						dir.y = -1;
					if (!diag || !usingM)
					{
						if (xOrY)
							dir.y = 0;
						else
							dir.x = 0;
					}
				}
				//else if (!usingM)
				{
					xP = dir.x > 0;
					yP = dir.y >= 0;
					
					if (Math.abs(dir.x) > Math.abs(dir.y))
					{
						if (!usingM && !perfectAim)
							dir.y = 0;
						xOrY = true;
					}
					else
					{
						if (!usingM && !perfectAim)
							dir.x = 0;
						xOrY = false;
					}
				}
				
				if (!usingM)
				{
					//shoot!
					var pS:uint = 2;
					if (!xOrY && yP)
						pS += 2;
					else if (!xOrY)
						pS += 4;
						
					var pXA:int = Main.data.races[race][pS];
					if (!xP)
						pXA *= -1;
					var pYA:int = Main.data.races[race][pS + 1];
					
					if (perfectAim)
						dir.normalize(Main.data.weapons[weapon][5]);
					else
						dir = autoAim(dir, x + pXA, y + pYA, Main.data.weapons[weapon][5]);
					(FP.world as Map).projectiles.push(new Projectile(x + pXA, y + pYA, dir, weaponDamage, Main.data.weapons[weapon][7], good, Main.data.weapons[weapon][8], Main.data.colors[Main.data.weapons[weapon][2]][1], effectSkill));
				}
				else
				{
					//lunge!
					lunge = dir;
					lunge.normalize(Main.data.weapons[weapon][5] * lungeMod);
				}
				return true;
			}
			return false;
		}
		
		private function autoAim(dir:Point, xS:uint, yS:uint, pSpd:uint):Point
		{
			var targets:Array;
			if (good)
				targets = (FP.world as Map).enemies;
			else
				targets = (FP.world as Map).players;
				
			var bestDif:Point = dir;
			var bestAngleDif:Number = 0;
			
			for (var i:uint = 0; i < targets.length; i++)
			{
				var tar:Creature = targets[i];
				if (tar.onscreen && !tar.dead && tar.active)
				{
					var dif:Point = new Point(tar.x - x, tar.y - y);
					var angleDif:Number = Math.abs(Math.atan2(dir.y, dir.x) - Math.atan2(dif.y, dif.x));
						
					if (angleDif < COMB_MAXAUTOAIM && (bestDif == dir || bestAngleDif > angleDif))
					{
						bestDif = dif;
						bestAngleDif = angleDif;
					}
				}
			}
			
			bestDif.normalize(pSpd);
			return bestDif;
		}
		
		public function takeHit(damage:uint, moralePer:uint):Boolean
		{
			var roll:uint = Math.random() * 100;
			if (roll <= dodgeChance)
			{
				FP.world.add(new DamageNum(Player.DIA_UNSELECTEDCOLOR, x, y - bodyHeight, "Dodged!"));
				return false;
			}
			
			if (damage == 0)
				return true;
				
			soundEffect(4);
			
			//reduce damage with your armor, UP TO 50% damage taken
			if (damage / 2 > defense)
				damage -= defense;
			else
				damage /= 2;
			
			var hDam:uint = damage * (100 - moralePer) / 100;
			var mDam:uint = damage * moralePer / 100;
			
			takeHitInner(hDam, mDam, moralePer);
			return true;
		}
		
		private function takeHitInner(hDam:uint, mDam:uint, moralePer:uint):void
		{
			if (good)
			{
				//good guy resistance
				hDam *= COMB_PLAYERHEALTHRESIST;
				mDam *= COMB_PLAYERMORALERESIST;
			}
			else
			{
				//bad guy un-resistance
				hDam *= COMB_ENEMYMULT;
				mDam *= COMB_ENEMYMULT;
			}
			
			if (fragile > 0)
			{
				hDam *= Main.data.effects[5][2] * 0.01;
				mDam *= Main.data.effects[5][2] * 0.01;
			}
			
			if (moralePer != 0 && hDam == 0)
				hDam = 1;
			if (moralePer != 100 && mDam == 0)
				mDam = 1;
				
			if (hDam == 0)
				FP.world.add(new DamageNum(Player.INTER_MORALECOLOR, x, y - bodyHeight, "" + mDam));
			else if (mDam == 0)
				FP.world.add(new DamageNum(Player.INTER_HEALTHCOLOR, x, y - bodyHeight, "" + hDam));
			else
			{
				var hNum:DamageNum = new DamageNum(Player.INTER_HEALTHCOLOR, x, y - bodyHeight, "" + hDam);
				var mNum:DamageNum = new DamageNum(Player.INTER_MORALECOLOR, x, y - bodyHeight, "" + mDam);
				hNum.y -= hNum.tHeight / 2;
				mNum.y += hNum.tHeight / 2;
				FP.world.add(hNum);
				FP.world.add(mNum);
			}
				
			if (health > hDam)
				health -= hDam;
			else
				health = 0;
				
			if (morale > mDam)
				morale -= mDam;
			else
				morale = 0;
		}
		
		//internal stuff
		protected function get lunging():Boolean { return lunge.x != 0 || lunge.y != 0; }
		protected function get knockbacked():Boolean { return knockback.x != 0 || knockback.y != 0; }
		protected function get isInjured():Boolean { return health < maxHealth || morale < maxMorale; }
		protected function get hasMelee():Boolean { return meleeW != Database.NONE; }
		protected function get hasRanged():Boolean { return rangedW != Database.NONE; }
		public function get onscreen():Boolean { return x >= FP.camera.x - bodySize && x <= FP.camera.x + FP.width + bodySize && y >= FP.camera.y - bodyHeight - bodySize && y <= FP.camera.y + FP.height + bodySize + bodyHeight; }
		protected function get meleeRangeEstimate():Number
		{
			return (Main.data.weapons[weapon][5] * Main.data.weapons[weapon][5] * lungeMod) /
					(2 * MOVE_LUNGESLOW);
		}
		
		public function applyEffect(ef:uint, variable:uint):uint
		{
			switch(ef)
			{
			case 0: //poison
				if (effectSkill !== 0)
					poison += variable * 0.01;
				break;
			case 1: //slow
				if (effectSkill !== 0)
					slow += variable * 0.01;
				break;
			case 5: //fragile
				if (effectSkill != 0)
					fragile += variable * 0.01;
				break;
			case 2: //bounce
			case 3: //knockback burst
			case 4: //headtaker
				return ef;
			}
			
			return Database.NONE;
		}
		
		protected function effectBubble(effect:uint, hR:uint = 0, vRU:uint = 0, vRD:uint = 0):void
		{
			if (hR == 0)
				hR = bodySize;
			if (vRU == 0)
				vRU = bodyHeight;
			FP.world.add(new Fragment(Main.data.effects[effect][1], x - hR + hR * 2 * Math.random(), y + vRD, Math.random() * (vRU + vRD)));
		}
		
		public function update():void
		{
			if (cooldown > 0)
				cooldown -= FP.elapsed;
			
			//manage status effects
			if (poison > 0)
			{
				var oldPT:uint = poison / EFFECT_TICKFREQUENCY;
				poison -= FP.elapsed;
				if (poison < 0)
					poison = 0;
				var newPT:uint = poison / EFFECT_TICKFREQUENCY;
				while (newPT < oldPT)
				{
					newPT += 1;
					//take a poison damage tick
					takeHitInner(Main.data.effects[0][2] * 0.01 * maxHealth, Main.data.effects[0][2] * 0.01 * maxMorale, 50);
					effectBubble(0);
				}
			}
			
			if (slow > 0)
			{
				var oldST:uint = slow / EFFECT_TICKFREQUENCY;
				slow -= FP.elapsed;
				if (slow < 0)
					slow = 0;
				var newST:uint = slow / EFFECT_TICKFREQUENCY;
				while (newST < oldST)
				{
					newST += 1;
					//make a slow bubble
					effectBubble(1);
				}
			}
			
			if (headtaker > 0)
			{
				var oldHT:uint = headtaker / EFFECT_TICKFREQUENCY;
				headtaker -= FP.elapsed;
				if (headtaker < 0)
					headtaker = 0;
				var newHT:uint = headtaker / EFFECT_TICKFREQUENCY;
				while (newHT < oldHT)
				{
					newHT += 1;
					//make a headtaker bubble
					effectBubble(4);
				}
			}
			
			if (fragile > 0)
			{
				var oldFT:uint = fragile / EFFECT_TICKFREQUENCY;
				fragile -= FP.elapsed;
				if (fragile < 0)
					fragile = 0;
				var newFT:uint = fragile / EFFECT_TICKFREQUENCY;
				while (newFT < oldFT)
				{
					newFT += 1;
					//make a fragile bubble
					effectBubble(5);
				}
			}
			
			if (lunging)
			{
				//lunge
				var hit:Creature = moveInner(lunge.x * FP.elapsed, lunge.y * FP.elapsed, false, good, true);
				if (hit != null)
				{
					//get knocked in the opposite direction
					lunge.normalize(Main.data.weapons[weapon][5]);
					knockback.x = -lunge.x;
					knockback.y = -lunge.y;
					
					//stop lunging
					lunge.x = 0;
					lunge.y = 0;
					
					//hit them, maybe
					if (hit.good != good && hit.npcLine == Database.NONE && hit.takeHit(weaponDamage, Main.data.weapons[weapon][7]))
					{
						//they get knocked around too
						hit.knockback.x -= knockback.x * lungeMod;
						hit.knockback.y -= knockback.y * lungeMod;
						
						//see if you can apply an effect
						if (effectSkill != Database.NONE && Main.data.effectSkills[effectSkill][2])
							switch (hit.applyEffect(Main.data.effectSkills[effectSkill][1], Main.data.effectSkills[effectSkill][4]))
							{
							case 3:
								hitBurst(hit);
								break;
							case 4:
								if (hit.dead)
									headtaker += Main.data.effectSkills[effectSkill][4] * 0.01;
								break;
							}
					}
				}
				else
				{
					walkAnim();
					
					var lungeS:Number = lunge.length;
					lungeS -= FP.elapsed * MOVE_LUNGESLOW * lungeMod;
					if (lungeS <= 0)
					{
						lunge.x = 0;
						lunge.y = 0;
					}
					else
						lunge.normalize(lungeS);
				}
			}
			if (knockbacked)
			{
				if (moveInner(knockback.x * FP.elapsed, knockback.y * FP.elapsed, false, good) != null)
				{
					knockback.x = 0;
					knockback.y = 0;
				}
				else
				{
					var knockS:Number = knockback.length;
					knockS -= FP.elapsed * MOVE_KNOCKBACKSLOW * lungeMod;
					if (knockS <= 0)
					{
						knockback.x = 0;
						knockback.y = 0;
					}
					else
						knockback.normalize(knockS);
				}
			}
		}
		
		private function hitBurst(ignore:Creature):void
		{
			var toHit:Array;
			if (good)
				toHit = (FP.world as Map).enemies;
			else
				toHit = (FP.world as Map).players;
				
			var hitSomeone:Boolean = false;
			for (var i:uint = 0; i < toHit.length; i++)
			{
				var tH:Creature = toHit[i];
				if (tH != ignore && !tH.dead && tH.active && tH.onscreen)
				{
					var dif:Point = new Point(ignore.x - tH.x, ignore.y - tH.y);
					var d:Number = dif.length;
					if (d <= Main.data.effects[3][2])
					{
						hitSomeone = true;
						
						//they take a hit!
						tH.takeHitInner(0, Main.data.effects[3][4] * (1 + STAT_STRDAMAGE * str), 100);
						
						//knock them back
						dif.normalize(Main.data.effects[3][3] * lungeMod);
						tH.knockback.x -= dif.x;
						tH.knockback.y -= dif.y;
					}
				}
			}
			
			//make the AoE effect
			if (hitSomeone)
				for (i = 0; i < Main.data.effects[3][5]; i++)
					ignore.effectBubble(3, Main.data.effects[3][2], Main.data.effects[3][2], Main.data.effects[3][2]);
		}
		
		private function alphaColorSet(spr:Spritemap, baseColor:uint, baseAlpha:Number = 1):void
		{
			spr.alpha = alpha * baseAlpha;
			if (alpha < 1)
				spr.color = FP.colorLerp(0, baseColor, alpha);
			else
				spr.color = baseColor;
		}
		
		private function partRender(spr:Spritemap, xA:int = 0):void
		{
			if (health == 0)
			{
				spr.angle = 90;
				spr.render(FP.buffer, new Point(x + bodyHeight / 2, y + xA), FP.camera);
			}
			else
			{
				spr.angle = 0;
				spr.render(FP.buffer, new Point(x + xA, y), FP.camera);
			}
		}
		
		public function uiRender(pNum:uint):void {}
		
		public function render():void
		{
			if (!onscreen || !active)
				return;
			
			var spr:Spritemap = Main.data.spriteSheets[0];
			var reduced:Boolean = Main.data.races[race][11];
			var gA:uint;
			if (reduced)
				gA = Main.data.races[race][1] * 8 + phenome;
			else
				gA = (phenome + Main.data.races[race][1]) * 8;
			if (health == 0 && good)
			{
				//do some modifications for part rendering
				xOrY = true;
				xP = true;
				yP = false;
			}
			
			spr.flipped = !xP;
			if (health == 0)
			{
				var bloodColor:uint = Main.data.colorations[Main.data.races[race][10]][5];
				
				if (bloodColor != Database.NONE)
				{
					//draw the blood pool
					var bStart:uint = Main.data.lists[0][2];
					var bEnd:uint = Main.data.lists[0][3];
					spr.color = Main.data.colors[bloodColor][1];
					spr.alpha = Main.data.colors[bloodColor][2] * 0.01;
					spr.angle = 0;
					var fChoice:uint = x % (bEnd - bStart + 1) + bStart;
					spr.frame = fChoice;
					spr.render(FP.buffer, new Point(x, y + Main.data.lists[0][1]), FP.camera);
					
					alphaColorSet(spr, Main.data.colors[skinColor][1], Main.data.colors[skinColor][2] * 0.01);
					spr.color = FP.colorLerp(Main.data.colors[bloodColor][1], spr.color, 0.5);
				}
			}
			else
				alphaColorSet(spr, Main.data.colors[skinColor][1], Main.data.colors[skinColor][2] * 0.01);
			
			//draw hair back
			var sprH:Spritemap = Main.data.spriteSheets[2];
			if (hair != Database.NONE)
			{
				sprH.flipped = spr.flipped;
				alphaColorSet(sprH, Main.data.colors[hairColor][1], Main.data.colors[hairColor][2] * 0.01);
				sprH.frame = hair * 2;
				if (yP)
					partRender(sprH);
			}
			
			if (!reduced)
			{
				//draw weapon (below)
				var sprW:Spritemap = Main.data.spriteSheets[3];
				var drawWeapon:Boolean = !dead && Main.data.weapons[weapon][1] != Database.NONE;
				if (drawWeapon)
				{
					sprW.flipped = spr.flipped;
					alphaColorSet(sprW, Main.data.colors[Main.data.weapons[weapon][2]][1]);
					sprW.frame = Main.data.weapons[weapon][1] * 3;
					var wA:int = 0;
					if (sprW.flipped)
						wA = (sprW.originX - spr.originX) * 2;
					if (!yP && !xOrY)
					{
						sprW.frame += 1;
						partRender(sprW, wA);
					}
				}
					
				//draw legs
				spr.frame = 2 + gA;
				if (walk >= 0 && walk < 0.5)
					spr.frame += 1;
				partRender(spr);
				
				//draw leg armor
				if (armor != Database.NONE && Main.data.armors[armor][5] != Database.NONE)
				{
					var sprAL:Spritemap = Main.data.spriteSheets[6];
					
					sprAL.frame = Main.data.armors[armor][5] * 4 + phenome * 2;
					if (walk >= 0 && walk < 0.5)
						sprAL.frame += 1;
					sprAL.flipped = spr.flipped;
					alphaColorSet(sprAL, Main.data.colors[Main.data.armors[armor][2]][1]);
					partRender(sprAL);
				}
			}
			
			//draw body
			spr.frame = 0 + gA;
			if (!yP)
				spr.frame += 1;
			partRender(spr);
			
			if (!reduced)
			{
				//draw armor
				if (armor != Database.NONE && Main.data.armors[armor][1] != Database.NONE)
				{
					var sprA:Spritemap = Main.data.spriteSheets[1];
					sprA.flipped = spr.flipped;
					alphaColorSet(sprA, Main.data.colors[Main.data.armors[armor][2]][1]);
					sprA.frame = Main.data.armors[armor][1] * 4 + phenome * 2;
					if (!yP)
						sprA.frame += 1;
					partRender(sprA);
				}
				
				
				//draw main arm
				var armA:uint = 0;
				if (!dead && (Main.data.weapons[weapon][1] != Database.NONE || npcLine == Database.NONE))
				{
					if (xOrY)
						armA += 2;
					else if (!yP)
						armA += 1;
				}
				spr.frame = 4 + gA + armA;
				partRender(spr);
				
				//draw arm armor
				if (armor != Database.NONE && Main.data.armors[armor][7] != Database.NONE)
				{
					var sprAA:Spritemap = Main.data.spriteSheets[7];
					
					sprAA.frame = Main.data.armors[armor][7] * 6 + phenome * 3 + armA;
					sprAA.flipped = spr.flipped;
					alphaColorSet(sprAA, Main.data.colors[Main.data.armors[armor][2]][1]);
					partRender(sprAA);
				}
					
				//draw weapon (above)
				if (drawWeapon)
				{
					if (yP && !xOrY)
					{
						partRender(sprW, wA);
					}
					else if (xOrY)
					{
						sprW.frame += 2;
						partRender(sprW, wA);
					}
				}
			}
			
			//draw hair front
			if (hair != Database.NONE)
			{
				if (yP)
					sprH.frame += 1;
				partRender(sprH);
			}
		}
	}

}