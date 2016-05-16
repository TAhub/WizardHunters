package game 
{
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	
	public class Map extends World
	{
		//generation values
		private var pL:Array;
		private var pM:uint;
		public var month:uint;
		private var levelBundle:uint;
		
		//name stuff
		public var name:String;
		private var nameDisplay:Number;
		private static const NAME_DISPLAYLENGTH:Number = 4;
		private static const NAME_FADEPOINT:Number = 1;
		
		//lighting effect data
		private var lEffect:Number;
		private var lTimerX:Number;
		private var lTimerY:Number;
		private static const LEFFECT_LEFFECTSPEED:Number = 0.8;
		
		//arenas
		private var arenaActive:uint;
		private var arenaTimer:Number;
		private static const ARENA_TIMERRATE:Number = 0.6;
		private static const ARENA_FINALTIMERRATE:Number = 0.25;
		private var arenas:Array;
		private static const ARENA_NUMBER:uint = 3;
		private static const ARENA_BORDERSIZE:uint = 2;
		private static const ARENA_ENCOUNTERSBASE:uint = 2;
		private static const ARENA_TELECHANCE:Number = 0.3;
		private static const ARENA_FINALENCOUNTERS:uint = 4;
		
		private var eventWeeks:Array;
		private var numPlayers:uint;
		private var width:uint;
		private var height:uint;
		private var tiles:Array;
		private var secondHalf:Array;
		private var aboveTiles:Array;
		public var players:Array;
		public var enemies:Array;
		public var npcs:Array;
		public var projectiles:Array;
		public var town:Boolean;
		private var week:uint;
		private var soloFocus:uint;
		private static const MAP_WEEKS:uint = 4;
		public static const MAP_TILESIZE:uint = 40;
		private static const MAP_PLAYERSPACING:uint = 30;
		private static const GENERATE_BORDER:uint = 3;
		private static const GENERATOR_CELLRAND:Number = 0.15;
		private static const GENERATE_SIDEPASSAGEFAILS:uint = 1000;
		private static const GENERATE_BOSSGOLDPER:Number = 0.3;
		private static const GENERATE_SPACING:Number = 20;
		private static const GENERATE_STARTFAILS:uint = 5000;
		private static const GENERATE_GOLDRAMP:Number = 0.3;
		private static const GENERATE_GOLDBASE:uint = 150;
		private static const GENERATE_RARECHANCE:Number = 0.13;
		private static const GENERATE_BOSSBASE:uint = 6;
		private static const GENERATE_FINALBOSSBASE:uint = 8;
		private static const GENERATE_FURNFAILS:uint = 1000;
		
		public function Map(playerList:Array, premadeMap:uint, _month:uint, _name:String, _levelBundle:uint) 
		{
			name = _name;
			levelBundle = _levelBundle;
			month = _month;
			pL = playerList;
			pM = premadeMap;
			numPlayers = playerList.length;
			projectiles = new Array();
			soloFocus = Database.NONE;
			town = false;
			week = 0;
			arenaActive = 0;
			arenaTimer = -1;
			lEffect = 0;
			lTimerX = 0;
			lTimerY = 0;
			nameDisplay = 0;
		}
		
		public function get countDown():uint
		{
			return (MAP_WEEKS - week);
		}
		
		public function townProgress():void
		{
			soloFocus += 1;
			if (soloFocus >= players.length)
			{
				soloFocus = 0;
				week += 1;
			}
			
			if (week == MAP_WEEKS + 1)
			{
				//your month increases
				month += 1;
				
				//switch to a new map
				switchMap(false);
			}
		}
		
		public function switchMap(toTown:Boolean):void
		{
			var playerList:Array = new Array();
			for (var i:uint = 0; i < numPlayers; i++)
				playerList.push(players[i]);
			if (toTown && month == 5)
			{
				//TODO: actually add high scores or w/e
				FP.world = new Menu();
				Main.menuPhase = 2;
				Main.menuPlayerOn = 0;
				return;
			}
			else if (toTown)
				FP.world = new Map(playerList, 0, month, null, 0); //go to the town map
			else if (month == 5)
				FP.world = new Map(playerList, 1, month, "Final Battle", 0);
			else
				FP.world = new Map(playerList, Database.NONE, month, name, levelBundle);
		}
		
		public function setFocus(on:Creature):void
		{
			for (var i:uint = 0; i < players.length; i++)
				if (players[i] == on)
				{
					soloFocus = i;
					return;
				}
		}
		
		public function endFocus():void
		{
			soloFocus = Database.NONE;
		}
		
		public override function update():void
		{
			lTimerX += FP.elapsed;
			lTimerY += FP.elapsed;
			
			if (pL != null)
			{
				if (pM == Database.NONE)
					mapGenerate(pL);
				else
					mapLoadPremade(pL, pM);
					
				pL = null;
				
				if (town)
				{
					//generate the NEXT map
					levelBundle = Math.random() * Main.data.levelBundles.length;
					name = generateLevelName();
					
					//and play the music
					Main.playMusic(6);
				}
				else if (month == 5)
					Main.playMusic(8);
				else
					Main.playMusic(7);
				nameDisplay = NAME_DISPLAYLENGTH;
			}
			
			if (nameDisplay > 0)
				nameDisplay -= FP.elapsed;
			
			if (!town)
			{
				//find out half status
				var sH:Boolean = true;
				for (var i:uint = 0; sH && i < players.length; i++)
					if (!secondHalf || !secondHalf[toI(players[i].x / MAP_TILESIZE, players[i].y / MAP_TILESIZE)])
						sH = false;
						
				if (sH)
				{
					if (lEffect < 1)
						lEffect += FP.elapsed * LEFFECT_LEFFECTSPEED;
					if (lEffect > 1)
						lEffect = 1;
				}
				else
				{
					if (lEffect > 0)
						lEffect -= FP.elapsed * LEFFECT_LEFFECTSPEED;
					if (lEffect < 0)
						lEffect = 0;
				}
				
				var allDead:Boolean = true;
				for (i = 0; allDead && i < players.length; i++)
					if (!players[i].dead)
						allDead = false;
				if (allDead || (enemies.length == 0 && npcs.length == 0))
				{
					//either you're all dead, or you won
					for (i = 0; i < players.length; i++)
						(players[i] as Player).saveDialogue();
					
					switchMap(true);
					return;
				}
				
				//see if anyone is inside an arena
				for (i = 0; arenaTimer == -1 && i < arenas.length; i++)
					if (arenas[i][2])
						for (j = 0; arenaTimer == -1 && j < players.length; j++)
							if (arenas[i][0].contains(players[j].x / MAP_TILESIZE, players[j].y / MAP_TILESIZE))
							{
								arenaActive = i;
								arenas[i][2] = false; //it's been sprung
								if (month == 5)
									arenaTimer = 0.999;
								else
									arenaTimer = 0;
								
								//turn on the arena's barriers
								soundEffect(5);
								arenaSurroundAction(arenaActive, tryActivateBarrier);
								
								//teleport everyone else into the arena
								for (var k:uint = 0; k < players.length; k++)
									if (k != j)
										arenaActivate(players[k], true);
								arenaActivate(players[j]);
								
								//teleport all onscreen active enemies in too so they don't get stuck in the wall
								centerCamera();
								for (k = 0; k < enemies.length; k++)
									if (enemies[k].onscreen && enemies[k].active)
										arenaActivate(enemies[k], true);
							}
				
				//increment the arena
				if (arenaTimer != -1)
				{
					var oldATU:uint = arenaTimer;
					if (month == 5)
						arenaTimer += FP.elapsed * ARENA_FINALTIMERRATE;
					else
						arenaTimer += FP.elapsed * ARENA_TIMERRATE;
					var aTU:uint = arenaTimer;
					if (oldATU < aTU && oldATU < arenas[arenaActive][1].length)
						arenaActivate(arenas[arenaActive][1][oldATU]);
						
					allDead = true;
					for (i = 0; allDead && i < arenas[arenaActive][1].length; i++)
						if (!arenas[arenaActive][1][i].dead)
							allDead = false;
							
					if (allDead)
					{
						//turn off the arena
						arenaTimer = -1;
						
						//clear it's list, so the memory of fleeing enemies can be freed
						arenas[arenaActive][1] = new Array();
						
						//turn off its barrier
						arenaSurroundAction(arenaActive, tryDeactivateBarrier);
					}
				}
			}
			
			
			if (soloFocus != Database.NONE)
				(players[soloFocus] as Creature).update();
			else
				for (i = 0; i < players.length; i++)
					(players[i] as Creature).update();
			
			if (soloFocus == Database.NONE)
			{
				var newEn:Array = new Array();
				for (i = 0; i < enemies.length; i++)
				{
					(enemies[i] as Creature).update();
					if ((enemies[i] as Creature).dead && (enemies[i] as Creature).money != 0)
					{
						for (var j:uint = 0; j < numPlayers; j++)
							(players[j] as Creature).money += (enemies[i] as Creature).money;
						(enemies[i] as Creature).money = 0;
					}
					if (!(enemies[i] as Creature).disappear)
						newEn.push(enemies[i]);
				}
				enemies = newEn;
				
				var newN:Array = new Array();
				for (i = 0; i < npcs.length; i++)
				{
					(npcs[i] as Creature).update();
					if ((npcs[i] as Creature).npcLine != Database.NONE)
						newN.push(npcs[i]);
				}
				npcs = newN;
			}
			
			var newProj:Array = new Array();
			for (i = 0; i < projectiles.length; i++)
			{
				(projectiles[i] as Projectile).update();
				if (!(projectiles[i] as Projectile).dead)
					newProj.push(projectiles[i]);
			}
			projectiles = newProj;
			
			super.update();
		}
		
		private function soundEffect(n:uint):void
		{
			Main.data.soundEffects[n].play(Main.data.lists[2][n * 2 + 1] * 0.01 * Main.soundVol * 0.01);
		}
		
		private function arenaActivate(cr:Creature, firstG:Boolean = false):void
		{
			cr.active = true;
			
			while (!cr.spaceEmpty || firstG || Math.random() < ARENA_TELECHANCE)
			{
				//move it to a random spot in the arena
				cr.x = MAP_TILESIZE * ((Math.random() * arenas[arenaActive][0].width) + arenas[arenaActive][0].x);
				cr.y = MAP_TILESIZE * ((Math.random() * arenas[arenaActive][0].height) + arenas[arenaActive][0].y);
				
				firstG = false; //for the goodguy teleport
			}
		}
		
		private function toI(x:uint, y:uint):uint { return x + y * width; }
		
		public function pointSolid(x:Number, y:Number):Boolean
		{
			var xI:int = x / Map.MAP_TILESIZE;
			var yI:int = y / Map.MAP_TILESIZE;
			if (xI < 0 || yI < 0 || xI >= width || yI >= height)
				return true;
			return tileSolid(toI(xI, yI));
		}
		
		private function get xWidth():uint { return FP.width / MAP_TILESIZE; }
		private function get yHeight():uint { return FP.height / MAP_TILESIZE; }
		
		private function centerCamera():void
		{
			//get the camera position
			if (arenaTimer == -1)
			{
				var playerC:Point = new Point(0, 0);
				var playerN:uint = 0;
				for (var i:uint = 0; i < players.length; i++)
					if (!players[i].dead && (!town || i == soloFocus))
					{
						playerC.x += players[i].x;
						playerC.y += players[i].y;
						playerN += 1;
					}
				if (playerN > 0)
				{
					playerC.x /= playerN;
					playerC.y /= playerN;
					FP.camera.x = playerC.x - FP.halfWidth;
					FP.camera.y = playerC.y - FP.halfHeight;
				}
			}
			else
			{
				FP.camera.x = (arenas[arenaActive][0].x + 0.5 + arenas[arenaActive][0].width / 2) * MAP_TILESIZE - FP.halfWidth;
				FP.camera.y = (arenas[arenaActive][0].y + 0.5 + arenas[arenaActive][0].height / 2) * MAP_TILESIZE - FP.halfHeight;
			}
			
			if (FP.camera.x < 0)
				FP.camera.x = 0;
			else if (FP.camera.x + FP.width > width * MAP_TILESIZE)
				FP.camera.x = width * MAP_TILESIZE - FP.width;
			if (FP.camera.y < 0)
				FP.camera.y = 0;
			else if (FP.camera.y + FP.height > height * MAP_TILESIZE)
				FP.camera.y = height * MAP_TILESIZE - FP.height;
		}
		
		private function uiRenders():void
		{
			for (var i:uint = 0; i < players.length; i++)
				if (!town || soloFocus == i)
					(players[i] as Creature).uiRender(i);
		}
		
		public override function render():void
		{
			centerCamera();
			
			if (week >= MAP_WEEKS)
			{
				if (week == MAP_WEEKS)
					uiRenders();
				return;
			}
			
			var xStart:int = FP.camera.x / MAP_TILESIZE;
			var yStart:int = FP.camera.y / MAP_TILESIZE;
			if (xStart + xWidth >= width)
				xStart = width - xWidth;
			if (yStart + yHeight >= height)
				yStart = height - yHeight;
			if (xStart < 0)
				xStart = 0;
			if (yStart < 0)
				yStart = 0;
			var tileSp:Spritemap = Main.data.spriteSheets[5];
			for (var y:uint = yStart; y <= yStart + yHeight && y < height; y++)
				for (var x:uint = xStart; x <= xStart + xWidth && x < width; x++)
				{
					var i:uint = tiles[toI(x, y)];
					if (i != 0)
					{
						tileSp.frame = Main.data.tiles[i][1];
						tileSp.color = Main.data.colors[Main.data.tiles[i][2]][1];
						tileSp.render(FP.buffer, new Point(x * MAP_TILESIZE, y * MAP_TILESIZE), FP.camera);
					}
					
					//draw abovetile too (don't bother to do this in the void)
					if (aboveTiles != null)
					{
						i = aboveTiles[toI(x, y)];
						if (i != Database.NONE)
						{
							tileSp.frame = Main.data.aboveTiles[i][1];
							tileSp.color = Main.data.colors[Main.data.aboveTiles[i][2]][1];
							tileSp.render(FP.buffer, new Point(x * MAP_TILESIZE, y * MAP_TILESIZE), FP.camera);
						}
					}
				}
			
			
			for (i = 0; i < players.length; i++)
				if (!town || soloFocus == i)
					(players[i] as Creature).render();
			
			for (i = 0; i < npcs.length; i++)
				(npcs[i] as Creature).render();
				
			for (i = 0; i < enemies.length; i++)
				(enemies[i] as Creature).render();
			
			for (i = 0; i < projectiles.length; i++)
				(projectiles[i] as Projectile).render();
				
			if (!town)
				printLightLayer();
				
			super.render();
				
			uiRenders();
				
			if (nameDisplay > 0)
			{
				//display the name
				var nT:Text;
				if (town)
					nT = new Text("the Town of Seastar");
				else
					nT = new Text(name);
				if (nameDisplay < NAME_FADEPOINT)
					nT.alpha = nameDisplay / NAME_FADEPOINT;
				nT.color = Player.DIA_SELECTEDCOLOR;
				nT.size *= 2;
				nT.render(FP.buffer, new Point(FP.halfWidth - nT.width / 2, FP.halfHeight / 2 - nT.height / 2), FP.zero);
			}
		}
		
		private function printLightLayer():void
		{
			var lP:uint = Main.data.tilesets[tileset][23];
			if (lP != Database.NONE)
				for (var i:uint = 0; i < 2; i++)
				{
					var lOn:uint = lP + i;
					var lSpr:Spritemap = Main.data.spriteSheets[Main.data.lightPatterns[lOn][1]];
					var a:Number;
					if (i == 0)
						a = (1 - lEffect);
					else
						a = lEffect;
					if (a != 0)
					{
						lSpr.color = Main.data.colors[Main.data.lightPatterns[lOn][3]][1];
						lSpr.alpha = a * Main.data.lightPatterns[lOn][2] * 0.01;
						
						var xS:Number = 0;
						var yS:Number = 0;
						
						var xSD:Number = 0;
						if (Main.data.lightPatterns[lOn][4] != 0)
						{
							xSD = lTimerX * Main.data.lightPatterns[lOn][4] * 0.01;
							while (xSD > lSpr.width)
							{
								if (a == 1)
									lTimerX -= lSpr.width * 100 / Main.data.lightPatterns[lOn][4];
								xSD -= lSpr.width;
							}
						}
						var ySD:Number = 0;
						if (Main.data.lightPatterns[lOn][5] != 0)
						{
							ySD = lTimerY * Main.data.lightPatterns[lOn][5] * 0.01;
							while (ySD > lSpr.height)
							{
								if (a == 1)
									lTimerY -= lSpr.height * 100 / Main.data.lightPatterns[lOn][5];
								ySD -= lSpr.height;
							}
						}
						xS += xSD;
						yS += ySD;
						
						xS += -FP.camera.x * Main.data.lightPatterns[lOn][6] * 0.01;
						yS += -FP.camera.y * Main.data.lightPatterns[lOn][7] * 0.01;
							
						while (xS < 0)
							xS += lSpr.width;
						if (xS > 0)
							xS -= lSpr.width;
						while (yS < 0)
							yS += lSpr.height;
						if (yS > 0)
							yS -= lSpr.height;
						
						for (var y:Number = yS; y < FP.height; y += lSpr.height)
							for (var x:Number = xS; x < FP.width; x += lSpr.width)
								lSpr.render(FP.buffer, new Point(x, y), FP.zero);
					}
				}
		}
		
		private function playerPosXAdd(i:uint):int
		{
			return (i - numPlayers * 0.5) * MAP_PLAYERSPACING;
		}
		
		//map load
		private function mapLoadPremade(playerList:Array, premadeMap:uint):void
		{
			town = premadeMap == 0;
			
			secondHalf = null;
			
			width = Main.data.premadeMaps[premadeMap][1];
			height = Main.data.premadeMaps[premadeMap][2];
			
			var startX:uint = Main.data.premadeMaps[premadeMap][3];
			var startY:uint = Main.data.premadeMaps[premadeMap][4];
			
			tiles = new Array();
			aboveTiles = null;
			secondHalf = null;
			for (var i:uint = 0; i < width * height; i++)
				tiles.push(Main.data.premadeMaps[premadeMap][5 + i]);
				
			players = new Array();
			enemies = new Array();
			npcs = new Array();
			for (i = 0; i < numPlayers; i++)
			{
				playerList[i].x = (startX + 0.5) * MAP_TILESIZE + playerPosXAdd(i);
				playerList[i].y = (startY + 0.5) * MAP_TILESIZE;
				players.push(playerList[i]);
			}
			for (i = 0; i < (Main.data.premadeMaps[premadeMap].length - 5 - width * height); i += 2)
			{
				var j:uint = Main.data.premadeMaps[premadeMap][5 + width * height + i];
				var n:uint = Main.data.premadeMaps[premadeMap][6 + width * height + i];
				var x:uint = j % width;
				var y:uint = j / width;
				npcs.push(new Creature((x + 0.5) * MAP_TILESIZE, (y + 0.5) * MAP_TILESIZE, true, n, true));
			}
			
			arenas = new Array();
			
			if (town)
			{
				soloFocus = 0;
				
				//pick the event weeks
				eventWeeks = new Array();
				for (i = 0; i < players.length; i++)
				{
					var eW:Array = new Array();
					for (j = 0; j < 4; j++)
						eW.push(false);
					for (j = 0; j < 2; j++)
						while (true)
						{
							var eWP:uint = Math.random() * 4;
							if (!eW[eWP])
							{
								eW[eWP] = true;
								break;
							}
						}
					eventWeeks.push(eW);
				}
			}
			else
			{
				//place the main arena
				var arena:Array = new Array();
				arenas.push(arena);
				arena.push(new Rectangle(0, 0, width, height));
				var arenaCreatures:Array = new Array();
				arena.push(arenaCreatures);
				arena.push(true);
				
				//place the final boss
				var boss:Creature = new Enemy(width / 2, height / 2, 1, GENERATE_FINALBOSSBASE + Main.data.numPlayerDatas[playerList.length][2]);
				arenaCreatures.push(boss);
				enemies.push(boss);
				
				//place the creatures in the arena
				for (i = 0; i < ARENA_FINALENCOUNTERS; i++)
					placeEncounter(0, 0, 0, width, height, playerList.length, arena);
			}
		}
		
		public function get isEventWeek():Boolean
		{
			var iEW:Boolean = eventWeeks[soloFocus][week];
			eventWeeks[soloFocus][week] = false;
			return iEW;
		}
		
		private function tileSolid(i:uint):Boolean
		{
			if (aboveTiles != null && aboveTiles[i] != Database.NONE && Main.data.aboveTiles[aboveTiles[i]][3])
				return true;
			return Main.data.tiles[tiles[i]][3];
		}
		
		private function fragmentsOnTile(x:uint, y:uint, type:uint):void
		{
			for (var j:uint = 0; j < Fragment.FRAG_NUM; j++)
				add(new Fragment(type, (x + Math.random()) * MAP_TILESIZE, (y + 1) * MAP_TILESIZE, Math.random() * MAP_TILESIZE + 1));
		}
		
		public function smash(x:Number, y:Number):void
		{
			var cornerX:uint = x / MAP_TILESIZE;
			var cornerY:uint = y / MAP_TILESIZE;
			var i:uint = toI(cornerX, cornerY);
			if (aboveTiles && aboveTiles[i] != Database.NONE && Main.data.aboveTiles[aboveTiles[i]][5] != Database.NONE)
			{
				fragmentsOnTile(cornerX, cornerY, Main.data.aboveTiles[aboveTiles[i]][5]);
				aboveTiles[i] = Database.NONE;
			}
		}
		
		public function get pWidth():Number { return width * MAP_TILESIZE; }
		public function get pHeight():Number { return height * MAP_TILESIZE; }
		
		//map generate
		private function mapGenerate(playerList:Array):void
		{
			while (!mapGenerateInner(playerList)) {}
		}
		
		private function get tileset():uint
		{
			return Main.data.levelBundles[levelBundle][1];
		}
		
		private function generateLevelName():String
		{
			var n:String = Main.data.lines[Main.data.levelBundles[levelBundle][2]];
			var p1S:uint = Main.data.tilesets[tileset][19];
			var p1E:uint = Main.data.tilesets[tileset][20];
			var p2S:uint = Main.data.tilesets[tileset][21];
			var p2E:uint = Main.data.tilesets[tileset][22];
			var p1:uint = Math.random() * (p1E - p1S + 1) + p1S;
			var p2:uint = Math.random() * (p2E - p2S + 1) + p2S;
			var n2:String = Main.data.lines[p1] + Main.data.lines[p2];
			
			//auto-capitalize n2
			var c:Boolean = true;
			for (var i:uint = 0; i < n2.length; i++)
			{
				if (n2.charAt(i) == " ")
				{
					c = true;
					n += " ";
				}
				else if (c)
				{
					c = false;
					n += n2.charAt(i).toUpperCase();
				}
				else
					n += n2.charAt(i);
			}
			
			return n;
		}
		
		private function get enemySet():uint
		{
			return Main.data.levelBundles[levelBundle][3];
		}
		
		private function mapGenerateInner(playerList:Array):Boolean
		{
			//resources
			var totalGold:uint = GENERATE_GOLDBASE * (1 + GENERATE_GOLDRAMP * (month - 1));
			
			//prepare tile lists
			var floor1:uint = Main.data.tilesets[tileset][3];
			var floor2:uint = Main.data.tilesets[tileset][4];
			var top1:uint = Main.data.tilesets[tileset][1];
			var top2:uint = Main.data.tilesets[tileset][2];
			var wall1:uint = Main.data.tilesets[tileset][5];
			var wall2:uint = Main.data.tilesets[tileset][6];
			
			//make the coarse array
			var coarseW:uint = Main.data.tilesets[tileset][10];
			var coarseH:uint = Main.data.tilesets[tileset][10];
			var pathLength:uint = Main.data.tilesets[tileset][11];
			var sidePassages:uint = Main.data.tilesets[tileset][12];
			
			var coarseTiles:Array = new Array();
			var coarseOrder:Array = new Array();
			for (var i:uint = 0; i < coarseW * coarseH; i++)
			{
				coarseTiles.push(0); //0 is layer 1 wall
				coarseOrder.push(0);
			}
				
			
			//start at an end
			var at:Point = new Point(coarseW / 2, coarseH / 2);
			var rnd:uint = Math.random() * 4;
			switch(rnd)
			{
			case 0:
				at.x = 1;
				break;
			case 1:
				at.x = coarseW - 2;
				break;
			case 2:
				at.y = 1;
				break;
			case 3:
				at.y = coarseH - 2;
				break;
			}
			var start:Point = new Point(at.x, at.y);
			
			//go around at random
			var order:uint = 0;
			for (i = 0; i < pathLength; i++)
			{
				var atI:uint = at.x + at.y * coarseW;
				//hollow out this tile
				if (i < pathLength / 2)
					coarseTiles[atI] = 1;
				else
					coarseTiles[atI] = 3;
				coarseOrder[atI] = order;
				order += 1;
					
				
				//pick the direction to go next
				rnd = Math.random() * 4;
				for (var j:uint = 0;; j++)
				{
					if (j == 4)
					{
						trace("MAIN PATH DEAD END");
						return false; //you got into a dead end
					}
					
					//which way to go?
					var dir:Point;
					switch((j + rnd) % 4)
					{
					case 0:
						dir = new Point(0, 1);
						break;
					case 1:
						dir = new Point(0, -1);
						break;
					case 2:
						dir = new Point(1, 0);
						break;
					case 3:
						dir = new Point( -1, 0);
						break;
					}
					
					//is that direction valid?
					var newAt:Point = new Point(at.x + dir.x, at.y + dir.y);
					if (newAt.x > 0 && newAt.y > 0 && newAt.x < coarseW - 1 && newAt.y < coarseH - 1)
					{
						//it's in bounds, but will it intersect?
						var surrounds:uint = 0;
						var sX:uint = newAt.x - 1;
						var sY:uint = newAt.y - 1;
						if (sX < 0)
							sX = 0;
						if (sY < 0)
							sY = 0;
							
						for (var y:uint = sY; y <= newAt.y + 1 && y < coarseH; y++)
							for (var x:uint = sX; x <= newAt.x + 1 && x < coarseW; x++)
								if (coarseTiles[x + y * coarseW] % 2 == 1) //it's an open tile
									surrounds += 1;
						
						if (surrounds <= 2)
						{
							//it's not surrounded much
							at = newAt;
							break;
						}
					}
				}
			}
			
			//place side passages
			var sidePassageLengthMin:uint = Main.data.tilesets[tileset][13];
			var sidePassageLengthMax:uint = Main.data.tilesets[tileset][14];
			
			for (i = 0; i < sidePassages; i++)
				for (j = 0;; j++)
				{
					if (j == GENERATE_SIDEPASSAGEFAILS)
					{
						trace("SIDE PATH FAIL");
						return false; //you failed to find a place for a side passage
					}
					
					//find a starting spot which isn't a wall
					do
					{
						x = Math.random() * coarseW;
						y = Math.random() * coarseH;
					}
					while (coarseTiles[x + y * coarseW] % 2 == 0)
					
					
					rnd = Math.random() * 4;
					switch(rnd)
					{
					case 0:
						dir = new Point(1, 0);
						break;
					case 1:
						dir = new Point(0, 1);
						break;
					case 2:
						dir = new Point( -1, 0);
						break;
					case 3:
						dir = new Point(0, -1);
						break;
					}
					
					var oFrom:uint = coarseOrder[x + y * coarseW];
					var gFrom:uint = coarseTiles[x + y * coarseW];
					var sPStage:uint = 0;
					var passageLength:uint = Math.random() * (sidePassageLengthMax - sidePassageLengthMin + 1) + sidePassageLengthMin;
					for (; passageLength > 0 && (x > 1 || dir.x != -1) && (y > 1 || dir.y != -1) && (x < coarseW - 2 || dir.x != 1) && (y < coarseH - 2 || dir.y != 1); passageLength -= 1)
					{
						x += dir.x;
						y += dir.y;
						oFrom += 1;
						
						if (coarseTiles[x + y * coarseW] == 0)
						{
							if (y == 0)
								sY = 0;
							else
								sY = y - 1;
							if (x == 0)
								sX = 0;
							else
								sX = x - 1;
							surrounds = 0;
							for (y2 = sY; y2 <= y + 1 && y2 < coarseH; y2++)
								for (x2 = sX; x2 <= x + 1 && x2 < coarseW; x2++)
									if (coarseTiles[x2 + y2 * coarseW] % 2 == 1)
										surrounds += 1;
										
							var maxSurr:uint = 1;
							if (sPStage == 0)
								maxSurr += 1; //for the very first one, there's a bit more leeway
							if (surrounds <= maxSurr)
							{
								sPStage += 1;
								coarseTiles[x + y * coarseW] = gFrom;
								coarseOrder[x + y * coarseW] = oFrom;
							}
							else
								break;
						}
						else
							break;
					}
					
					if (sPStage > 0)
						break;
				}
			
			//pick brush size
			var brushMin:uint = Main.data.tilesets[tileset][8];
			var brushMax:uint = Main.data.tilesets[tileset][9];
			var brushW:uint = Math.random() * (brushMax - brushMin + 1) + brushMin;
			var brushH:uint = Math.random() * (brushMax - brushMin + 1) + brushMin;
			
			//translate it
			width = coarseH * brushW;
			height = coarseW * brushH;
			
			tiles = new Array();
			for (y = 0; y < coarseH; y++)
				for (var y2:uint = 0; y2 < brushH; y2++)
					for (x = 0; x < coarseW; x++)
						for (var x2:uint = 0; x2 < brushW; x2++)
						{
							switch(coarseTiles[x + y * coarseW])
							{
							case 0:
								tiles.push(top1);
								break;
							case 1:
								tiles.push(floor1);
								break;
							case 3:
								tiles.push(floor2);
								break;
							default:
								tiles.push(0); //who knows what
								break;
							}
						}
						
			//place arenas
			arenas = new Array();
			for (i = 1; i <= ARENA_NUMBER; i++)
			{
				//what range of order should it be in?
				var lowerRange:uint = Math.round(i * pathLength / (ARENA_NUMBER + 0.2));
				var upperRange:uint = Math.round(i * pathLength / (ARENA_NUMBER - 0.2));
				
				var possiblePlaces:Array = new Array();
				for (y = 0; y < coarseH; y++)
					for (x = 0; x < coarseW; x++)
					{
						var cO:uint = coarseOrder[x + y * coarseW];
						if (cO >= lowerRange && cO <= upperRange)
						{
							//find the rectangle
							var rec:Rectangle = new Rectangle(x * brushW - ARENA_BORDERSIZE, y * brushH - ARENA_BORDERSIZE,
																brushW + ARENA_BORDERSIZE * 2, brushH + ARENA_BORDERSIZE * 2);
							
							//does it intersect the player start zone, or the edges of the map?
							if (!rec.contains((start.x + 0.5) * brushW, (start.y + 0.5) * brushH) &&
								rec.left >= 0 && rec.top >= 0 && rec.right < width && rec.bottom < height)
							{
								//does it intersect any other arena or any ?
								var inters:Boolean = false;
								for (j = 0; !inters && j < arenas.length; j++)
									if (rec.intersects(arenas[j][0]))
										inters = true;
								
								if (!inters)
									possiblePlaces.push(rec);
							}
						}
					}
					
				if (possiblePlaces.length == 0)
				{
					trace("ARENA FAIL");
					return false; //you can't find a spot for an arena! that's bad
				}
					
				//initialize the arena
				var arena:Array = new Array();
				arenas.push(arena);
					
				//pick a spot
				var pR:uint = possiblePlaces.length * Math.random();
				rec = possiblePlaces[pR];
				arena.push(rec);
				
				//clean up the spot
				var floor:uint = tiles[toI(rec.x + ARENA_BORDERSIZE + brushW / 2, rec.y + ARENA_BORDERSIZE + brushH / 2)];
				for (y = rec.top; y < rec.bottom; y++)
					for (x = rec.left; x < rec.right; x++)
						tiles[toI(x, y)] = floor;
						
				//push the empty creature array
				arena.push(new Array());
				
				//it's yet to be sprung
				arena.push(true);
			}
						
			//do some cellular smoothing
			for (i = 0; i < Main.data.tilesets[tileset][7]; i++)
				cellularSmooth(top1);
			
			players = new Array();
			enemies = new Array();
			npcs = new Array();
			
			//find a good start position
			var pS:Point;
			for (i = 0;; i++)
			{
				if (i == GENERATE_STARTFAILS)
				{
					trace("START FAIL");
					return false;
				}
				
				pS = new Point((start.x + Math.random()) * brushW * MAP_TILESIZE, (start.y + Math.random()) * brushH * MAP_TILESIZE);
				var valid:Boolean = true;
				for (j = 0; valid && j < numPlayers; j++)
				{
					playerList[j].x = pS.x + playerPosXAdd(j);
					playerList[j].y = pS.y;
					if (!playerList[j].spaceEmpty)
						valid = false;
				}
				
				if (valid)
				{
					for (j = 0; j < numPlayers; j++)
						players.push(playerList[j]);
					break;
				}
			}
			
			//place npcs
			//new treasure algorithm: instead of pre-picking spots, instead look for dead ends at this stage
			var eventList:uint = Main.data.tilesets[tileset][16];
			for (y = 1; y < coarseH - 1; y++)
				for (x = 1; x < coarseW - 1; x++)
					if (x != start.x || y != start.y)
					{
						order = coarseOrder[x + coarseW * y];
						//see if this tile has any neighbors of a higher order
						if (coarseOrder[x - 1 + coarseW * y] < order &&
							coarseOrder[x + 1 + coarseW * y] < order &&
							coarseOrder[x + coarseW * (y - 1)] < order &&
							coarseOrder[x + coarseW * (y + 1)] < order)
						{
							var l:uint = Math.random() * (Main.data.lists[eventList].length - 1) + 1;
							l = Main.data.lists[eventList][l];
							var n:uint = Math.random() * (Main.data.lists[l].length - 1) + 1;
							npcs.push(new Creature((x + 0.5) * brushW * MAP_TILESIZE, (y + 0.5) * brushH * MAP_TILESIZE,
												true, Main.data.lists[l][n], true));
						}
					}
			
			//place arena monsters
			for (i = 0; i < arenas.length; i++)
				for (j = 0; j < ARENA_ENCOUNTERSBASE + i; j++)
					placeEncounter(enemySet, arenas[i][0].x, arenas[i][0].y, arenas[i][0].width, arenas[i][0].height, playerList.length, arenas[i]);
				
			//generate the boss
			//it goes in the final arena
			var lastA:Array = arenas[arenas.length - 1];
			var boss:Enemy = new Enemy(lastA[0].x + lastA[0].width / 2, lastA[0].y + lastA[0].height / 2,
										Main.data.enemySets[enemySet][3], GENERATE_BOSSBASE + month + Main.data.numPlayerDatas[playerList.length][2]);
			boss.active = false;
			arenas[arenas.length - 1][1].push(boss);
			enemies.push(boss);
			
			//place enemy encounters
			var enemyInterval:uint = Main.data.tilesets[tileset][15];
			for (y = 0; y < coarseH; y++)
				for (x = 0; x < coarseW; x++)
					if (coarseOrder[x + y * coarseW] > enemyInterval && //can't be too close to the player
						coarseOrder[x + y * coarseW] % enemyInterval == enemyInterval - 1) //has to be at the right interval
						placeEncounter(enemySet, x * brushW, y * brushH, brushW, brushH, playerList.length);
						
			//distribute enemy gold
			var bossGold:uint = totalGold * GENERATE_BOSSGOLDPER;
			var goldLeft:uint = totalGold - bossGold;
			for (i = 1; i < enemies.length; i++)
			{
				var goldDis:uint = totalGold * (1 - GENERATE_BOSSGOLDPER) / (enemies.length - 1);
				goldLeft -= goldDis;
				if (goldDis == 0)
					goldDis = 1; //just in case; better to give too much gold than none at all
				(enemies[i] as Creature).money += goldDis;
			}
			
			//give the boss the remaining money
			boss.money += bossGold + goldLeft;
			
			recutMap(top1);
			
			//determine second/first half status
			secondHalf = new Array();
			for (i = 0; i < tiles.length; i++)
				secondHalf.push(tiles[i] == floor2);
			
			//initial modify tiles
			for (y = 0; y < height; y++)
			{
				tiles[toI(0, y)] = 0;
				tiles[toI(width - 1, y)] = 0;
			}
			for (x = 0; x < width; x++)
			{
				tiles[toI(x, 0)] = 0;
				tiles[toI(x, height - 1)] = 0;
			}
			for (y = 1; y < height - 1; y++)
				for (x = 1; x < width - 1; x++)
				{
					i = toI(x, y);
					switch(tiles[i])
					{
					case top1:
					case top2:
						//is there a non-solid tile nearby?
						var nSN:Boolean = false;
						for (y2 = y - 1; !nSN && y2 <= y + 1; y2++)
							for (x2 = x - 1; !nSN && x2 <= x + 1; x2++)
								if (!tileSolid(toI(x2, y2)))
									nSN = true;
						if (!nSN)
							tiles[i] = 0;
						else if (!tileSolid(i + width) && Main.data.tiles[tiles[i]][4] != Database.NONE)
							tiles[i] = Main.data.tiles[tiles[i]][4]; //change to front wall
						break;
					case floor2:
						for (y2 = y - 1; y2 <= y + 1; y2++)
							for (x2 = x - 1; x2 <= x + 1; x2++)
							{
								if (tiles[toI(x2, y2)] == top1)
									tiles[toI(x2, y2)] = top2;
								else if (tiles[toI(x2, y2)] == wall1)
									tiles[toI(x2, y2)] = wall2;
							}
						break;
					}
				}
				
			//make abovetiles array
			aboveTiles = new Array();
			for (i = 0; i < tiles.length; i++)
				aboveTiles.push(Database.NONE);
			
			//place furniture
			var furnitureList:uint = Main.data.tilesets[tileset][17];
			var furnitureNum:uint = Main.data.tilesets[tileset][18];
			var furnFailed:Boolean = false;
			for (i = 0; !furnFailed && i < furnitureNum; i++)
				for (j = 0;; j++)
				{
					if (j == GENERATE_FURNFAILS)
					{
						trace("FURNITURE FAIL");
						furnFailed = true;
						break;
					}
					
					//pick a random spot
					x = 0;
					y = 0;
					while (tileSolid(toI(x, y)) || aboveTiles[toI(x, y)] != Database.NONE)
					{
						x = Math.random() * (width - 2) + 1;
						y = Math.random() * (height - 2) + 1;
					}
					
					//pick a furniture, based on the ground
					var fL:uint = furnitureList;
					if (secondHalf[toI(x, y)])
						fL += 1; //use the alternate array
					var furn:uint = Math.random() * (Main.data.lists[fL].length - 1) + 1;
					furn = Main.data.lists[fL][furn];
					
					//see if the spot is valid going by that furniture's rules
					var furnValid:Boolean = false;
					for (y2 = y - 1; !furnValid && y2 <= y + 1; y2++)
						for (x2 = x - 1; !furnValid && x2 <= x + 1; x2++)
							if (Main.data.tiles[tiles[toI(x2, y2)]][3])
								furnValid = true;
								
					if (!Main.data.aboveTiles[furn][4])
						furnValid = !furnValid;
						
					if (furnValid && !obstructedCheck(x, y, furn))
					{
						placeFurnInner(furn, x, y);
						break;
					}
				}
			
			//place arena barriers
			for (i = 0; i < arenas.length; i++)
				arenaSurroundAction(i, tryPlaceBarrier);
				
			//pick tile alternates
			var newTiles:Array = new Array();
			for (y = 0; y < height; y++)
				for (x = 0; x < width; x++)
				{
					i = toI(x, y);
					newTiles.push(tiles[i]);
					var alt:uint = Main.data.tiles[tiles[i]][6];
					switch(Main.data.tiles[tiles[i]][5])
					{
					case 0:
						//fifty percent
						if (Math.random() < 0.5)
							newTiles[i] = alt;
						break;
					case 1:
						//even
						if (x % 2 == 0)
							newTiles[i] = alt;
						break;
					case 2:
						//surrounded
						if (x > 0 && y > 0 && x < width - 1 && y < height - 1)
						{
							var surr:Boolean = true;
							for (y2 = y - 1; y2 <= y + 1; y2++)
								for (x2 = x - 1; x2 <= x + 1; x2++)
									if (tiles[toI(x2, y2)] != tiles[i])
									{
										surr = false;
										break;
									}
							if (surr)
								newTiles[i] = alt;
						}
						break;
					case 3:
						//surrounded permissive
						if (x > 0 && y > 0 && x < width - 1 && y < height - 1)
						{
							surr = true;
							for (y2 = y - 1; y2 <= y + 1; y2++)
								for (x2 = x - 1; x2 <= x + 1; x2++)
									if (Main.data.tiles[tiles[toI(x2, y2)]][3] != Main.data.tiles[tiles[i]][3])
									{
										surr = false;
										break;
									}
							if (surr)
								newTiles[i] = alt;
						}
						break;
					case 4:
						//ten percent
						if (Math.random() < 0.1)
							newTiles[i] = alt;
						break;
					default:
						//no alternate scheme
						break;
					}
				}
			tiles = newTiles;
			
			return true; //it worked!
		}
		
		private function obstructedCheck(x:uint, y:uint, furn:uint):Boolean
		{
			if (!Main.data.aboveTiles[furn][3])
				return false; //no need to check, since it's not solid anyway
			
			var oldAT:uint = aboveTiles[toI(x, y)];
			aboveTiles[toI(x, y)] = 1;
			for (var i:uint = 0; i < 3; i++)
			{
				var ar:Array;
				switch(i)
				{
				case 0:
					ar = enemies;
					break;
				case 1:
					ar = players;
					break;
				case 2:
					ar = npcs;
					break;
				}
				
				for (var j:uint = 0; j < ar.length; j++)
				{
					var cr:Creature = ar[j];
					if (cr.active && !cr.spaceEmpty)
					{
						aboveTiles[toI(x, y)] = oldAT;
						return true;
					}
				}
			}
			
			aboveTiles[toI(x, y)] = oldAT;
			return false;
		}
		
		private function placeFurnInner(furn:uint, x:uint, y:uint):void
		{
			var minCluster:uint = Main.data.aboveTiles[furn][6];
			var maxCluster:uint = Main.data.aboveTiles[furn][7];
			var cluster:uint = Math.random() * (maxCluster - minCluster + 1) + minCluster - 1;
			
			//place it
			var spots:Array = new Array();
			spots.push(new Point(x, y));
			aboveTiles[toI(x, y)] = furn;
			
			//place the rest of the cluster
			var checkedSpots:Array = new Array();
			var possibleSpots:Array = new Array();
			checkedSpots.push(new Point(x, y));
			for (var i:uint = 0; i < cluster;)
			{
				if (possibleSpots.length > 0)
				{
					//use up one of the spots
					var pSP:uint = possibleSpots.length * Math.random();
					aboveTiles[toI(possibleSpots[pSP].x, possibleSpots[pSP].y)] = furn;
					spots.push(possibleSpots[pSP]);
					
					//remove that from the possibilities;
					if (pSP != possibleSpots.length - 1)
						possibleSpots[pSP] = possibleSpots[possibleSpots.length - 1];
					possibleSpots.pop();
					
					i++;
				}
				
				for (var j:uint = 0; j < spots.length; j++)
					for (var k:uint = 0; k < 4; k++)
					{
						//pick a spot adjacent to an existing spot
						x = spots[j].x;
						y = spots[j].y;
						switch(k)
						{
						case 0:
							x -= 1;
							break;
						case 1:
							y -= 1;
							break;
						case 2:
							x += 1;
							break;
						case 3:
							y += 1;
							break;
						}
						
						//don't check the same spot twice
						var doneBefore:Boolean = false;
						for (var l:uint = 0; !doneBefore && l < checkedSpots.length; l++)
							if (checkedSpots[l].x == x && checkedSpots[l].y == y)
								doneBefore = true;
								
						if (!doneBefore)
						{
							checkedSpots.push(new Point(x, y));
							
							//see if you can 
							if (!tileSolid(toI(x, y)) && aboveTiles[toI(x, y)] == Database.NONE && !obstructedCheck(x, y, furn))
								possibleSpots.push(new Point(x, y));
						}
					}
					
				if (possibleSpots.length == 0)
					return; //it's impossible if you have no spots at all after checking
			}
		}
		
		private function arenaSurroundAction(i:uint, f:Function):void
		{
			for (var j:uint = 0; j < arenas[i][0].width + 3; j++)
			{
				f(arenas[i][0].x - 1 + j, arenas[i][0].top - 1);
				f(arenas[i][0].x - 1 + j, arenas[i][0].bottom + 1);
			}
			for (j = 0; j < arenas[i][0].height + 3; j++)
			{
				f(arenas[i][0].left - 1, arenas[i][0].y - 1 + j);
				f(arenas[i][0].right + 1, arenas[i][0].y - 1 + j);
			}
		}
		
		private function tryDeactivateBarrier(x:uint, y:uint):void
		{
			if (aboveTiles && aboveTiles[toI(x, y)] == 1)
			{
				aboveTiles[toI(x, y)] = 2;
				fragmentsOnTile(x, y, 1);
			}
		}
		
		private function tryActivateBarrier(x:uint, y:uint):void
		{
			if (aboveTiles && aboveTiles[toI(x, y)] == 0)
			{
				aboveTiles[toI(x, y)] = 1;
				fragmentsOnTile(x, y, 0);
			}
		}
		
		private function tryPlaceBarrier(x:uint, y:uint):void
		{
			if (!Main.data.tiles[tiles[toI(x, y)]][3])
				aboveTiles[toI(x, y)] = 0;
		}
		
		private function placeEncounter(enemySet:uint, x:uint, y:uint, w:uint, h:uint, numPlayers:uint, arena:Array = null):void
		{
			//get this month's values for encounters
			var com1:uint;
			var com2:uint;
			var rar:uint;
			switch(month)
			{
			case 1: //first dungeon
				com1 = 0;
				com2 = 1;
				rar = 2;
				break;
			case 2: //second dungeon
				com1 = 1;
				com2 = 2;
				rar = 0;
				break;
			case 3: //third dungeon
				com1 = 2;
				com2 = 3;
				rar = 4;
				break;
			case 4: //last dungeon
				com1 = 3;
				com2 = 4;
				rar = 2;
				break;
			case 5: //final battle
				com1 = 0;
				com2 = 1;
				rar = 4;
				break;
			}
			
			var numF:Number = Math.random() * (Main.data.enemySets[enemySet][2] - Main.data.enemySets[enemySet][1] + 1) +
							Main.data.enemySets[enemySet][1]
			numF *= Main.data.numPlayerDatas[numPlayers][1] * 0.01;
			var num:uint = numF;
			for (var i:uint = 0; i < num; i++)
				while (true)
				{
					//pick a position
					var eX:uint = (w - 2) * Math.random() + x + 1;
					var eY:uint = (h - 2) * Math.random() + y + 1;
					
					//pick an enemy type
					var rank:uint;
					if (Math.random() < GENERATE_RARECHANCE)
						rank = rar;
					else if (Math.random() < 0.5)
						rank = com1;
					else
						rank = com2;
					var type:uint = Main.data.enemySets[enemySet][rank + 4];
					
					if (!tileSolid(toI(eX, eY)))
					{
						//check to see if it collides with anyone else
						var closestDis:Number = Database.NONE;
						for (var k:uint = 0; k < 2 && closestDis > GENERATE_SPACING; k++)
						{
							var lst:Array;
							if (k == 0)
								lst = enemies;
							else
								lst = npcs;
								
							for (var j:int = lst.length - 1; closestDis > GENERATE_SPACING && j >= 0; j--)
							{
								var dis:Number = new Point(lst[j].x - (eX + 0.5) * MAP_TILESIZE, lst[j].y - (eY + 0.5) * MAP_TILESIZE).length;
								if (dis < closestDis)
									closestDis = dis;
							}
						}
						
						if (closestDis > GENERATE_SPACING)
						{
							//it's a valid position, hooray
							var en:Creature = new Enemy((eX + 0.5) * MAP_TILESIZE, (eY + 0.5) * MAP_TILESIZE, type, rank + Main.data.numPlayerDatas[numPlayers][2]);
							enemies.push(en);
							if (arena != null)
							{
								en.active = false;
								arena[1].push(en);
							}
							break;
						}
					}
				}
		}
		
		private function cellularSmooth(top:uint):void
		{
			var newTiles:Array = new Array();
			for (var i:uint = 0; i < width * height; i++)
				newTiles.push(tiles[i]);
			for (var y:uint = 1; y < height - 1; y++)
				for (var x:uint = 1; x < width - 1; x++)
				{
					var surround:uint = 0;
					var surEmp:uint = Database.NONE;
					for (var y2:uint = y - 1; y2 <= y + 1; y2++)
						for (var x2:uint = x - 1; x2 <= x + 1; x2++)
						{
							if (tileSolid(toI(x2, y2)))
							{
								if ((x2 != x || y2 != y))
									surround += 1;
							}
							else if (surEmp == Database.NONE || Math.random() < 0.5)
								surEmp = tiles[toI(x2, y2)];
						}
						
					if (surround >= 6 || (surround >= 5 && Math.random() > GENERATOR_CELLRAND))
						newTiles[toI(x, y)] = top;
					else
						newTiles[toI(x, y)] = surEmp;
				}
			tiles = newTiles;
		}
		
		private function recutMap(topT:uint):void
		{
			//recut the map
			var left:int = width;
			var top:int = height;
			var right:uint = 0;
			var bottom:uint = 0;
			
			for (var y:uint = 0; y < height; y++)
				for (var x:uint = 0; x < width; x++)
					if (!tileSolid(toI(x, y)))
					{
						if (x < left)
							left = x;
						if (y < top)
							top = y;
						if (x > right)
							right = x;
						if (y > bottom)
							bottom = y;
					}
					
			right += GENERATE_BORDER;
			bottom += GENERATE_BORDER;
			top -= GENERATE_BORDER;
			left -= GENERATE_BORDER;
			var newWidth:uint = right - left + 1;
			var newHeight:uint = bottom - top + 1;
			var newTiles:Array = new Array();
			
			for (var i:uint = 0; i < newWidth * newHeight; i++)
				newTiles.push(topT);
				
			//shift tiles over
			var sX:uint;
			var sY:uint;
			if (top < 0)
				sY = 0;
			else
				sY = top;
			if (left < 0)
				sX = 0;
			else
				sX = left;
			
			for (y = sY; y <= bottom && y < height; y++)
				for (x = sX; x <= right && x < width; x++)
					if (x > 0 && y > 0 && x < width && y < height)
						newTiles[(x - left) + (y - top) * newWidth] = tiles[toI(x, y)];
				
			//shift creatures
			for (i = 0; i < players.length; i++)
			{
				(players[i] as Creature).x -= left * MAP_TILESIZE;
				(players[i] as Creature).y -= top * MAP_TILESIZE;
			}
			for (i = 0; i < enemies.length; i++)
			{
				(enemies[i] as Creature).x -= left * MAP_TILESIZE;
				(enemies[i] as Creature).y -= top * MAP_TILESIZE;
			}
			for (i = 0; i < npcs.length; i++)
			{
				(npcs[i] as Creature).x -= left * MAP_TILESIZE;
				(npcs[i] as Creature).y -= top * MAP_TILESIZE;
			}
			
			//shift arenas
			for (i = 0; i < arenas.length; i++)
			{
				arenas[i][0].x -= left;
				arenas[i][0].y -= top;
			}
				
			tiles = newTiles;
			height = newHeight;
			width = newWidth;
		}
	}

}