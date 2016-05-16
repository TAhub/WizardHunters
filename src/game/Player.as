package game 
{
	import flash.display.InterpolationMethod;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.FP;
	
	public class Player extends Creature
	{
		//dialogue stuff
		private var shop:uint;
		private var savedDialogue:uint;
		private var dialogue:uint;
		private var dialogueI:uint;
		private var dialogueN:Creature;
		private var dialogueR:uint;
		public static const DIA_SELECTEDCOLOR:uint = 0xFFFFFF;
		public static const DIA_UNSELECTEDCOLOR:uint = 0x999999;
		public static const DIA_WIDTH:uint = 600;
		private static const DIA_RANGE:uint = 30;
		
		//interface stuff
		private static const INTER_WIDTH:uint = 100;
		public static const INTER_HEALTHCOLOR:uint = 0xFF3333;
		public static const INTER_MORALECOLOR:uint = 0x3333FF;
		private static const INTER_BACKCOLOR:uint = 0x333333;
		private static const INTER_BARHEIGHT:uint = 20;
		private static const INTER_BARBORDER:uint = 2;
		private var keys:Array;
		private var interfaceLockout:Number;
		private static const INTER_LOCKOUTLENGTH:Number = 1.0;
		
		//key listings
		public static const keyLists:Array =
			[[Key.W, Key.A, Key.S, Key.D, Key.V, Key.B],
			[Key.UP, Key.LEFT, Key.DOWN, Key.RIGHT, Key.O, Key.P],
			[Key.NUMPAD_8, Key.NUMPAD_4, Key.NUMPAD_5, Key.NUMPAD_6, Key.NUMPAD_DIVIDE, Key.NUMPAD_MULTIPLY],
			[Key.T, Key.F, Key.G, Key.H, Key.U, Key.I]];
		
		//shop stuff
		private static const SHOP_RESELL:Number = 0.5;
		private static const SHOP_REPMOD:Number = 0.004;
		
		//player variables
		private var reputation:int;
		private static const REPUTATION_MAX:uint = 99;
		private var playerFade:Number;
		
		//score stuff
		private static const SCORE_VICTORYMOD:Number = 1.5;
		private static const SCORE_REPMOD:Number = 0.0051;
		private static const SCORE_REPINTERVAL:Number = 0.05;
		public static const SCORE_NAME:String = "highscores";
		public static const SCORE_LENGTH:uint = 15;
		public static const SCORE_MAXNAME:uint = 8;
		public var name:String;
		
		public function Player(_x:Number, _y:Number, controlScheme:uint) 
		{
			super(_x, _y, true, 0, false);
			
			dialogue = Database.NONE;
			reputation = 0;
			savedDialogue = Database.NONE;
			dialogueR = Database.NONE;
			shop = Database.NONE;
			playerFade = -1;
			name = "PLAYER";
			interfaceLockout = 0;
			
			keys = keyLists[controlScheme];
		}
		
		private function startDialogue(n:Creature):Boolean
		{
			if (n.npcLine == Database.NONE)
				return false;
			
			dialogueN = n;
			dialogue = n.npcLine;
			dialogueI = 0;
			dialogueEffects();
			if (!(FP.world as Map).town) //don't set focus if it's a town
				(FP.world as Map).setFocus(this);
				
			return true;
		}
		
		private function dialogueEffectsName():String
		{
			var str:String = "";
			var numOptions:uint = Main.data.dialogues[dialogue][2];
			var numEffects:uint = Main.data.dialogues[dialogue][3 + numOptions];
			for (var i:uint = 0; i < numEffects; i++)
			{
				var type:uint = Main.data.dialogues[dialogue][4 + numOptions + i * 2];
				var num:int = Main.data.dialogues[dialogue][5 + numOptions + i * 2];
				if (Main.data.dialogueVariables[type][2])
				{
					str += "\n" + Main.data.lines[Main.data.dialogueVariables[type][1]] + " ";
					
					if (num >= 0)
						str += "+";
					str += num;
				}
			}
			return str;
		}
		
		private function dialogueEffects():void
		{
			if ((FP.world as Map).town)
				dialogueEffectsOne(dialogue); //only affect yourself
			else
				for (var i:uint = 0; i < (FP.world as Map).players.length; i++)
					if (!(FP.world as Map).players[i].dead)
						(FP.world as Map).players[i].dialogueEffectsOne(dialogue); //affect the entire party
		}
		
		private function dialogueEffectsOne(d:uint):void
		{
			var numOptions:uint = Main.data.dialogues[d][2];
			var numEffects:uint = Main.data.dialogues[d][3 + numOptions];
			for (var i:uint = 0; i < numEffects; i++)
			{
				var type:uint = Main.data.dialogues[d][4 + numOptions + i * 2];
				var num:int = Main.data.dialogues[d][5 + numOptions + i * 2];
				
				switch(type)
				{
				case 0: //str
					if (str < -num)
						str = 0;
					else
						str += num;
					if (str > Creature.STAT_MAX)
						str = Creature.STAT_MAX;
					break;
				case 1: //end
					var hpDef:uint = maxHealth - health;
					if (end < -num)
						end = 0;
					else
						end += num;
					if (end > Creature.STAT_MAX)
						end = Creature.STAT_MAX;
					health = maxHealth - hpDef; //maintain the same health deficit
					break;
				case 2: //dex
					if (dex < -num)
						dex = 0;
					else
						dex += num;
					if (dex > Creature.STAT_MAX)
						dex = Creature.STAT_MAX;
					break;
				case 3: //mnd
					if (mnd < -num)
						mnd = 0;
					else
						mnd += num;
					if (mnd > Creature.STAT_MAX)
						mnd = Creature.STAT_MAX;
					break;
				case 4:
					//cha
					var morDef:uint = maxMorale - morale;
					if (cha < -num)
						cha = 0;
					else
						cha += num;
					if (cha > Creature.STAT_MAX)
						cha = Creature.STAT_MAX;
					morale = maxMorale - morDef; //maintain the same morale deficit
					break;
				case 5: //health
					if (health < -num)
						health = 0;
					else
						health += num;
					if (health > maxHealth)
						health = maxHealth;
					break;
				case 6: //morale
					if (morale < -num)
						morale = 0;
					else
						morale += num;
					if (morale > maxMorale)
						morale = maxMorale;
					break;
				case 7: //mutex
					break;
				case 8: //money
					money += num;
					break;
				case 9: //reputation
					reputation += num;
					if (reputation > REPUTATION_MAX)
						reputation = REPUTATION_MAX;
					else if (reputation < -REPUTATION_MAX)
						reputation = -REPUTATION_MAX;
					break;
				case 10: //don't end
					dialogueN = null;
					break;
				case 11: //random event
					if ((FP.world as Map).isEventWeek)
					{
						//see which random events are valid
						var validEvents:Array = new Array();
						for (var j:uint = 0; j < num; j++)
						{
							var pick:uint = dialogue + 1 + j;
							var pickNumOptions:uint = Main.data.dialogues[pick][2];
							var pickNumEffects:uint = Main.data.dialogues[pick][3 + pickNumOptions];
							var pickNumConditions:uint = Main.data.dialogues[pick][4 + pickNumOptions + pickNumEffects * 2];
							var pickValid:Boolean = true;
							for (var k:uint = 0; pickValid && k < pickNumConditions; k++)
								pickValid = checkCondition(Main.data.dialogues[pick], 5 + pickNumOptions + pickNumEffects * 2 + k * 2, pick);
							if (pickValid)
								validEvents.push(pick);
						}
						if (validEvents.length > 0)
						{
							//pick one of the valid events at random
							dialogueR = validEvents.length * Math.random();
							dialogueR = validEvents[dialogueR];
							Main.dialogueOnetimes[dialogueR] = false;
						}
					}
					break;
				case 12: //shop
					shop = num;
					break;
				case 13: //onetime
					break;
				case 14: //weapon
					if (Main.data.weapons[num][3])
						rangedW = num;
					else
						meleeW = num;
					break;
				case 15: //inverse money
					break;
				case 16: //phenome
					break;
				case 17: //go on
					//see which result is possible
					for (j = 0; j < (Main.data.dialogueChoices[num].length - 2) / 3; j++)
					{
						var result:uint = Main.data.dialogueChoices[num][2 + j * 3];
						if (checkCondition(Main.data.dialogueChoices[num], 3 + j * 3, dialogue))
						{
							dialogue = result;
							dialogueI = 0;
							dialogueEffects();
							if (shop != Database.NONE)
								dialogueN = null;
							break;
						}
					}
					break;
				case 18: //count down
					break;
				case 19: //month
					break;
				}
			}
		}
		
		private function dialogueControl():void
		{
			var iAdd:Number = 0;
			
			if (Input.pressed(keys[0]))
				iAdd -= 1;
			if (Input.pressed(keys[2]))
				iAdd += 1;
				
			var nOT:uint;
			var numOptions:uint = 1;
			if (shop != Database.NONE)
				nOT = (Main.data.shopLists[shop].length - 1) / 4 + 1;
			else
			{
				numOptions = Main.data.dialogues[dialogue][2];
				nOT = numOptions;
				if (dialogueR != Database.NONE)
					nOT += 1;
			}
			
			if (numOptions != 0 && iAdd != 0)
			{
				soundEffect(2);
				if (dialogueI == 0 && iAdd == -1)
					dialogueI = nOT - 1;
				else if (dialogueI == nOT - 1 && iAdd == 1)
					dialogueI = 0;
				else
					dialogueI += iAdd;
			}
				
			if (Input.pressed(keys[4]) || Input.pressed(keys[5]))
			{
				if (shop != Database.NONE)
				{
					if (dialogueI == nOT - 1)
					{
						soundEffect(3);
						//exit the shop
						dialogue = Database.NONE;
						shop = Database.NONE;
						if (!(FP.world as Map).town) //don't end focus if it's a town
							(FP.world as Map).endFocus();
					}
					else if (getCost(dialogueI) != Database.NONE && itemStatReq(dialogueI) && (money >= getCost(dialogueI) || getCost(dialogueI) < 0))
					{
						//you can afford the item
						money -= getCost(dialogueI);
						soundEffect(1);
						
						var it:uint = Main.data.shopLists[shop][dialogueI * 4 + 1];
						var itType:uint = Main.data.shopLists[shop][dialogueI * 4 + 2];
						switch(itType)
						{
						case 0:
							if (Main.data.weapons[it][3])
								rangedW = it;
							else
								meleeW = it;
							break;
						case 1:
							armor = it;
							break;
						case 2:
							effectSkill = it;
							break;
						}
					}
					return;
				}
				else if (numOptions == 0 && dialogueR == Database.NONE)
				{
					soundEffect(3);
					if (dialogueN != null)
					{
						if ((FP.world as Map).town)
						{
							//the week is over
							(FP.world as Map).townProgress();
						}
						else
						{
							//the npc is done for
							dialogueN.npcLine = Database.NONE;
						}
					}
					
					//exit out of the dialogue
					dialogue = Database.NONE;
					if (!(FP.world as Map).town) //don't end focus if it's a town
						(FP.world as Map).endFocus();
					return;
				}
				
				soundEffect(3);
				
				if (dialogueI == numOptions)
				{
					//it's an event transition!
					//so just go there immediately
					dialogue = dialogueR;
					dialogueI = 0;
					dialogueEffects();
					dialogueR = Database.NONE;
				}
				else
				{
					//select that dialogue option
					var op:uint = Main.data.dialogues[dialogue][3 + dialogueI];
					
					
					//see which result is possible
					for (var i:uint = 0; i < (Main.data.dialogueChoices[op].length - 2) / 3; i++)
					{
						var result:uint = Main.data.dialogueChoices[op][2 + i * 3];
						if (checkCondition(Main.data.dialogueChoices[op], 3 + i * 3, dialogue))
						{
							dialogue = result;
							dialogueI = 0;
							dialogueEffects();
							if (shop != Database.NONE)
								dialogueN = null;
							break;
						}
					}
				}
			}
		}
		
		private function get highestStatVal():uint
		{
			var h:uint = str;
			if (end > h)
				h = end;
			if (dex > h)
				h = dex;
			if (mnd > h)
				h = mnd;
			if (cha > h)
				h = cha;
			return h;
		}
		
		private function get victory():Boolean
		{
			//did you win?
			for (var i:uint = 0; i < Main.currentPlayers.length; i++)
				if (!Main.currentPlayers[i].dead)
					return true;
			return false;
		}
		
		private function get totalStats():uint
		{
			return str + end + dex + mnd + cha;
		}
		
		private function get repModifier():Number
		{
			var rM:uint = (Math.abs(reputation) * SCORE_REPMOD) / SCORE_REPINTERVAL;
			return 1 + rM * SCORE_REPINTERVAL;
		}
		
		public function get scoreBreakdown():String
		{
			var s:String = "SCORE = " + money + " SPARE CASH";
				s += "\n       + " + totalStats + " TOTAL STATS";
				
			if (repModifier != 1)
			{
				if (reputation > 0)
					s += "\n       * " + repModifier + " PARAGON MODIFIER";
				else
					s += "\n       * " + repModifier + " PARIAH MODIFIER";
			}
				
			if (victory)
				s += "\n       * " + SCORE_VICTORYMOD + " VICTORY MODIFIER";
				
			s += "\n       = " + score + " TOTAL";
			return s;
		}
		
		public function get score():uint
		{
			var s:uint = totalStats + money;
			s *= repModifier;
			if (victory)
				s *= SCORE_VICTORYMOD;
			return s;
		}
		
		public function get ending():uint
		{
			for (var i:uint = 0; i < Main.data.endings.length; i++)
			{
				var valid:Boolean = true;
				
				switch(Main.data.endings[i][1])
				{
				case 0: //str
					valid = str == highestStatVal;
					break;
				case 1: //end
					valid = end == highestStatVal;
					break;
				case 2: //dex
					valid = dex == highestStatVal;
					break;
				case 3: //mnd
					valid = mnd == highestStatVal;
					break;
				case 4: //cha
					valid = cha == highestStatVal;
					break;
				}
				
				if (valid && //you have the right stat
					(Main.data.endings[i][2] == Database.NONE || money >= Main.data.endings[i][2]) && //you have enough money
					(Main.data.endings[i][3] == Database.NONE || reputation >= Main.data.endings[i][3]) && //you have enough rep
					Main.data.endings[i][4] == victory && //you won correctly
					(!Main.data.endings[i][6] || health != 0)) //the coward clause
					return i;
			}
			
			return 0; //this is probably unnecessary but...
		}
		
		private function checkCondition(ar:Array, startI:uint, d:uint):Boolean
		{
			var condition:uint = ar[startI];
			var variable:uint = ar[startI + 1];
			
			switch(condition)
			{
			case 0: //str
				return str >= variable;
			case 1: //end
				return end >= variable;
			case 2: //dex
				return dex >= variable;
			case 3: //mnd
				return mnd >= variable;
			case 4: //cha
				return cha >= variable;
			case 5: //health
				return health >= variable;
			case 6: //morale
				return morale >= variable;
			case 7: //mutex
				return Main.dialogueMutexes[d];
			case 8: //money
				return money >= variable;
			case 9: //reputation
				return reputation >= variable;
			case 10: //don't end
				break;
			case 11: //random event
				break;
			case 12: //shop
				break;
			case 13: //onetime
				return Main.dialogueOnetimes[d];
			case 14: //weapon
				break;
			case 15: //inverse money
				return money < variable;
			case 16: //phenome
				return phenome >= variable;
			case 17: //go On
				break;
			case 18: //count down
				return (FP.world as Map).countDown >= variable;
			case 19: //month
				return (FP.world as Map).month >= variable;
			}
			
			return true;
		}
		
		private function itemStatReq(i:uint):Boolean
		{
			return checkCondition(Main.data.shopLists[shop], i * 4 + 3, 0);
		}
		
		public override function render():void
		{
			if (playerFade == -1)
				alpha = 1;
			else
				alpha = playerFade;
			super.render();
		}
		
		private function barRender(x:Number, y:Number, width:Number, height:Number, color:uint, percent:Number):void
		{
			FP.buffer.fillRect(new Rectangle(x, y, width, height), 0);
			FP.buffer.fillRect(new Rectangle(x + INTER_BARBORDER, y + INTER_BARBORDER,
										width - 2 * INTER_BARBORDER, height - 2 * INTER_BARBORDER), INTER_BACKCOLOR);
			FP.buffer.fillRect(new Rectangle(x + INTER_BARBORDER, y + INTER_BARBORDER,
										(width - 2 * INTER_BARBORDER) * percent, height - 2 * INTER_BARBORDER), color);
		}
		
		private function getCost(i:uint):int
		{
			var curValue:uint = 0;
			var itValue:uint = 0;
			
			var it:uint = Main.data.shopLists[shop][i * 4 + 1];
			var itType:uint = Main.data.shopLists[shop][i * 4 + 2];
			
			switch(itType)
			{
			case 0:
				itValue = Main.data.weapons[it][9];
				if (Main.data.weapons[it][3])
				{
					if (rangedW == it)
						return Database.NONE; //it's an even trade...
					curValue = Main.data.weapons[rangedW][9];
				}
				else
				{
					if (meleeW == it)
						return Database.NONE; //it's an even trade..
					curValue = Main.data.weapons[meleeW][9];
				}
				break;
			case 1:
				if (armor == it)
					return Database.NONE; //it's an even trade..
				itValue = Main.data.armors[it][6];
				curValue = Main.data.armors[armor][6];
				break;
			case 2:
				if (effectSkill == it)
					return Database.NONE; //it's an even trade...
				itValue = Main.data.effectSkills[it][5];
				if (effectSkill == Database.NONE)
					curValue = 0;
				else
					curValue = Main.data.effectSkills[effectSkill][5];
				break;
			}
			
			return Math.ceil(itValue * (1 - (reputation * SHOP_REPMOD))) - Math.floor(curValue * SHOP_RESELL);
		}
		
		public override function uiRender(pNum:uint):void
		{
			var interS:String = money + "G " + reputation + "R";
			if ((FP.world as Map).town)
				interS += "\n" + str + "STR " + end + "END " + dex + "DEX\n" + mnd + "MND " + cha + "CHA";
			var interT:Text = new Text(interS);
			barRender(pNum * (Map.MAP_TILESIZE + INTER_WIDTH), FP.height - INTER_BARHEIGHT * 2 - interT.height,
						INTER_WIDTH, INTER_BARHEIGHT,
						INTER_HEALTHCOLOR, 1.0 * health / maxHealth);
			barRender(pNum * (Map.MAP_TILESIZE + INTER_WIDTH), FP.height - INTER_BARHEIGHT - interT.height,
						INTER_WIDTH, INTER_BARHEIGHT,
						INTER_MORALECOLOR, 1.0 * morale / maxMorale);
			interT.render(FP.buffer, new Point(pNum * (Map.MAP_TILESIZE + INTER_WIDTH), FP.height - interT.height), FP.zero);
		
			var dY:Number = 0;
			if (dialogue != Database.NONE)
			{
				var dT:Text = new Text(dialogueProcess(Main.data.lines[Main.data.dialogues[dialogue][1]]) + dialogueEffectsName());
				dT.wordWrap = true;
				dT.width = DIA_WIDTH;
				dT.color = DIA_SELECTEDCOLOR;
				FP.buffer.fillRect(dT.clipRect, 0);
				dT.render(FP.buffer, FP.zero, FP.zero);
				dY += dT.height;
			}
			if (shop != Database.NONE)
			{
				var dYT:Number = dY;
				var sLen:uint = (Main.data.shopLists[shop].length - 1) / 4 + 1;
				var tW:uint = 0;
				for (var i:uint = 0; i < sLen; i++)
				{
					var sT:Text;
					if (i == sLen - 1)
						sT = new Text("Exit");
					else
					{
						var it:uint = Main.data.shopLists[shop][i * 4 + 1];
						var itType:uint = Main.data.shopLists[shop][i * 4 + 2];
						var sS:String;
						switch(itType)
						{
						case 0:
							sS = Main.data.lines[Main.data.weapons[it][11]];
							break;
						case 1:
							sS = Main.data.lines[Main.data.armors[it][8]];
							break;
						case 2:
							sS = Main.data.lines[Main.data.effectSkills[it][6]];
							break;
						}
						
						sT = new Text(sS);
					}
					if (i == dialogueI)
						sT.color = DIA_SELECTEDCOLOR;
					else
						sT.color = DIA_UNSELECTEDCOLOR;
					FP.buffer.fillRect(new Rectangle(0, dYT, FP.width, sT.height), 0);
					sT.render(FP.buffer, new Point(0, dYT), FP.zero);
					if (sT.width > tW)
						tW = sT.width;
					dYT += sT.height;
				}
				dYT = dY;
				for (i = 0; i < sLen - 1; i++)
				{
					var sSC:String;
					if (getCost(i) == Database.NONE)
						sSC = "(-)";
					else
						sSC = "(" + getCost(i) + ")";
					var sTC:Text = new Text(sSC);
					if (i == dialogueI)
						sTC.color = DIA_SELECTEDCOLOR;
					else
						sTC.color = DIA_UNSELECTEDCOLOR;
					
					var sSR:String = "(REQ ";
					
					var type:uint = Main.data.shopLists[shop][i * 4 + 3];
					var num:int = Main.data.shopLists[shop][i * 4 + 4];
					if (Main.data.dialogueVariables[type][2])
						sSR += Main.data.lines[Main.data.dialogueVariables[type][1]] + " " + num;
					else
						sSR += "-";
					sSR += ")";
					
					var sTR:Text = new Text(sSR);
					if (itemStatReq(i))
						sTR.color = sTC.color;
					else
						sTR.color = INTER_HEALTHCOLOR;
					if (getCost(i) > 0 && getCost(i) != Database.NONE && getCost(i) > money)
						sTC.color = INTER_HEALTHCOLOR;
					sTR.render(FP.buffer, new Point(tW, dYT), FP.zero);
					sTC.render(FP.buffer, new Point(FP.halfWidth, dYT), FP.zero);
					
					dYT += sTR.height;
				}
			}
			else if (dialogue != Database.NONE)
			{
				var numOptions:uint = Main.data.dialogues[dialogue][2];
				var nOT:uint = numOptions;
				if (dialogueR != Database.NONE)
					nOT += 1;
				for (i = 0; i < nOT; i++)
				{
					var oT:Text;
					if (i == numOptions)
						oT = new Text("But then...");
					else
					{
						var op:uint = Main.data.dialogues[dialogue][3 + i];
						oT = new Text(Main.data.lines[Main.data.dialogueChoices[op][1]]);
					}
					if (i == dialogueI)
						oT.color = DIA_SELECTEDCOLOR;
					else
						oT.color = DIA_UNSELECTEDCOLOR;
					FP.buffer.fillRect(new Rectangle(0, dY, oT.width, oT.height), 0);
					oT.render(FP.buffer, new Point(0, dY), FP.zero);
					dY += oT.height;
				}
			}
		}
		
		private function dialogueProcess(rawL:String):String
		{
			var newL:String = "";
			for (var i:uint = 0; i < rawL.length; i++)
			{
				if (rawL.charAt(i) == "%")
				{
					switch(rawL.charAt(i + 1))
					{
					case "N":
						newL += (FP.world as Map).name;
						break;
					case "C":
						newL += (FP.world as Map).countDown;
						break;
					case "A":
						newL += name;
						break;
					}
					
					i++;
				}
				else
					newL += rawL.charAt(i);
			}
			return newL;
		}
		
		public function beginningDialogue():void
		{
			savedDialogue = 4;
		}
		
		public function saveDialogue():void
		{
			interfaceLockout = INTER_LOCKOUTLENGTH;
			lunge = new Point(0, 0);
			knockback = new Point(0, 0);
			if (health == 0)
				savedDialogue = 0;
			else if (morale == 0)
				savedDialogue = 1;
			else
				savedDialogue = 2;
		}
		
		public override function update():void
		{
			if (savedDialogue != Database.NONE)
			{
				dialogueN = null;
				dialogue = savedDialogue;
				dialogueI = 0;
				savedDialogue = Database.NONE;
				
				playerFade = -1;
				health = maxHealth;
				if (morale < maxMorale / 2)
					morale = maxMorale / 2;
			}
			
			if (dialogue != Database.NONE)
			{
				if (interfaceLockout > 0)
					interfaceLockout -= FP.elapsed;
				else
					dialogueControl();
				return;
			}
			
			if ((FP.world as Map).town)
			{
				if (health == 0)
					health = 1;
				if (morale == 0)
					morale = 1;
					
				//remove status effects
				poison = 0;
				slow = 0;
				headtaker = 0;
				fragile = 0;
				
				//final week stuff?
				if ((FP.world as Map).countDown == 0)
				{
					//start the final week dialogue
					dialogue = 3;
					dialogueN = this;
					dialogueI = 0;
					savedDialogue = Database.NONE;
					dialogueEffects();
					return;
				}
			}
			
			super.update();
			
			if (health != 0 && morale == 0)
			{
				if (playerFade == -1)
					playerFade = 1;
				playerFade -= FP.elapsed;
				if (playerFade < 0)
					playerFade = 0;
				return;
			}
			
			if (interfaceLockout > 0)
			{
				interfaceLockout -= FP.elapsed;
				return;
			}
			
			var xAdd:Number = 0;
			var yAdd:Number = 0;
			
			if (Input.check(keys[0]))
				yAdd -= 1;
			if (Input.check(keys[2]))
				yAdd += 1;
			if (Input.check(keys[1]))
				xAdd -= 1;
			if (Input.check(keys[3]))
				xAdd += 1;
				
			move(xAdd, yAdd);
			
			if (!(FP.world as Map).town)
			{
				var mA:Boolean = Input.check(keys[4]);
				var rA:Boolean = Input.check(keys[5]);
				
				/*if (mA || rA)
				{
					//see if there is any enemy onscreen
					var anyOn:Boolean = false;
					for (var i:uint = 0; !anyOn && i < (FP.world as Map).enemies.length; i++)
						if ((FP.world as Map).enemies[i].onscreen && !(FP.world as Map).enemies[i].dead)
							anyOn = true;
					if (!anyOn)
					{
						mA = false;
						rA = false;
					}
				}*/
				
				attack(mA, rA);
			}
			if (Input.pressed(keys[4]))
				for (var i:uint = 0; i < (FP.world as Map).npcs.length; i++)
					if (new Point((FP.world as Map).npcs[i].x - x, (FP.world as Map).npcs[i].y - y).length < DIA_RANGE &&
						startDialogue((FP.world as Map).npcs[i]))
						return;
						
			//if (Input.pressed(Key.DIGIT_1))
			//	((FP.world as Map).switchMap(false));
		}
	}

}