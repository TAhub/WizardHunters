package game 
{
	import flash.geom.Point;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import flash.net.SharedObject;
	
	public class Menu extends World
	{
		private var optionOn:uint;
		private var joinedPlayers:Array;
		private var appearancePlayers:Array;
		private var confirmedPlayers:Array;
		private var highscoresA:Array;
		
		private var highscores:SharedObject;
		
		private static const MENU_MAXPLAYERS:uint = 4;
		
		private function prepareGame():void
		{
			//make the player list
			Main.currentPlayers = new Array();
			joinedPlayers = new Array();
			appearancePlayers = new Array();
			confirmedPlayers = new Array();
			
			//generate dialogue mutexes
			Main.dialogueMutexes = new Array();
			Main.dialogueOnetimes = new Array();
			for (var i:uint = 0; i < Main.data.dialogues.length; i++)
			{
				Main.dialogueMutexes.push(Math.random() < 0.5);
				Main.dialogueOnetimes.push(true);
			}
		}
		
		private function textListDraw(tl:Array, it:String, highlight:Boolean, titleSize:uint = 1, entrySize:uint = 1):Number
		{
			var texts:Array = new Array();
			
			var itT:Text = new Text(it);
			itT.color = Player.DIA_SELECTEDCOLOR;
			itT.wordWrap = true;
			itT.width = Player.DIA_WIDTH;
			itT.size *= titleSize;
			texts.push(itT);
			
			var tY:Number = itT.height;
			
			for (var i:uint = 0; i < tl.length; i++)
			{
				var tlT:Text = new Text(tl[i]);
				if (i == optionOn && highlight)
					tlT.color = Player.DIA_SELECTEDCOLOR;
				else
					tlT.color = Player.DIA_UNSELECTEDCOLOR;
				
				tlT.size *= entrySize;
				texts.push(tlT);
				tY += tlT.height;
			}
			
			tY = (FP.height - tY) / 2;
			var sY:Number = tY;
			for (i = 0; i < texts.length; i++)
			{
				texts[i].render(FP.buffer, new Point(0, tY), FP.zero);
				tY += texts[i].height;
			}
			return sY;
		}
		
		private function playerDP(i:uint):Point
		{
			switch(i)
			{
			case 0:
				return new Point(0, 0);
			case 1:
				return new Point(FP.halfWidth, Map.MAP_TILESIZE * 2);
			case 2:
				return new Point(0, FP.halfHeight);
			default:
				return new Point(FP.halfWidth, FP.halfHeight + Map.MAP_TILESIZE * 2);
			}
		}
		
		public override function render():void
		{
			switch(Main.menuPhase)
			{
			case 0: //main menu
				textListDraw(["Start\n ", "High Scores\n ", "Sound Volume: " + Main.soundVol + "%\n ", "Music Volume: " + Main.musicVol + "%"], "WIZARD HUNTERS", true, 3, 2);
				break;
			case 1: //enter menu
				var toJoin:Array = new Array();
				for (var i:uint = 0; i < Player.keyLists.length; i++)
				{
					var picked:Boolean = false;
					for (var j:uint = 0; !picked && j < joinedPlayers.length; j++)
						if (joinedPlayers[j] == i)
							picked = true;
					if (!picked)
						toJoin.push(i);
				}
				for (i = 0; i < MENU_MAXPLAYERS; i++)
				{
					var tP:Point = playerDP(i);
					if (i < Main.currentPlayers.length)
					{
						Main.currentPlayers[i].render();
						
						if (!confirmedPlayers[i])
						{
							var t:Text = new Text("Press " + Key.name(Player.keyLists[joinedPlayers[i]][0]) + " and " +
												Key.name(Player.keyLists[joinedPlayers[i]][2]) + " to change appearance.\n" +
												"Press " + Key.name(Player.keyLists[joinedPlayers[i]][4]) + " to confirm.");
							t.color = Player.DIA_SELECTEDCOLOR;
							tP.y += Map.MAP_TILESIZE;
							t.render(FP.buffer, tP, FP.zero);
						}
					}
					else
					{
						var tS:String = "";
						for (j = 0; j < toJoin.length; j++)
						{
							if (j != 0 && j == toJoin.length - 1)
								tS += " or ";
							else if (j != 0)
								tS += ", ";
							tS += Key.name(Player.keyLists[toJoin[j]][4]);
						}
						t = new Text("Press " + tS + " to join.");
						t.color = Player.DIA_SELECTEDCOLOR;
						t.render(FP.buffer, tP, FP.zero);
					}
				}
				break;
			case 2: //highscore enter menu
				
				var endingT:uint = Main.data.endings[Main.currentPlayers[Main.menuPlayerOn].ending][5];
				var hETop:String = Main.currentPlayers[Main.menuPlayerOn].name + " the " + Main.data.lines[endingT] + "\n" + Main.data.lines[endingT + 1] +
									"\n\n" + Main.currentPlayers[Main.menuPlayerOn].scoreBreakdown;
				
				Main.currentPlayers[Main.menuPlayerOn].x = Map.MAP_TILESIZE;
				Main.currentPlayers[Main.menuPlayerOn].y = textListDraw(["Yes", "No"], hETop + "\n\nAdd to high scores list?", true, 2) - Map.MAP_TILESIZE / 2;
				Main.currentPlayers[Main.menuPlayerOn].render();
				break;
			case 3: //highscore view menu
				textListDraw(highscoresA, "HIGH SCORES", false, 2);
				break;
			case 4: //name enter
				Main.currentPlayers[Main.menuPlayerOn].x = Map.MAP_TILESIZE;
				Main.currentPlayers[Main.menuPlayerOn].y = textListDraw([], "Player " + Main.menuPlayerOn + ", enter a name and then press enter.\n   " + Main.currentPlayers[Main.menuPlayerOn].name, true, 2) - Map.MAP_TILESIZE / 2;
				Main.currentPlayers[Main.menuPlayerOn].render();
				break;
			}
		}
		
		private function soundEffect(n:uint):void
		{
			Main.data.soundEffects[n].play(Main.data.lists[2][n * 2 + 1] * 0.01 * Main.soundVol * 0.01);
		}
		
		private function joinPlayer(scheme:uint):Boolean
		{
			if (!Input.pressed(Player.keyLists[scheme][4]))
				return false;
			for (var i:uint = 0; i < joinedPlayers.length; i++)
				if (joinedPlayers[i] == scheme)
					return false;
			joinedPlayers.push(scheme);
			appearancePlayers.push(0);
			confirmedPlayers.push(false);
			soundEffect(3);
			Main.currentPlayers.push(new Player(playerDP(i).x + Map.MAP_TILESIZE, playerDP(i).y + Map.MAP_TILESIZE, scheme));
			Main.currentPlayers[Main.currentPlayers.length - 1].applyAppearance(0, Main.currentPlayers.length - 1);
			return true;
		}
		
		private function kCheck(k:uint, scheme:uint = Database.NONE):Boolean
		{
			for (var i:uint = 0; i < Player.keyLists.length; i++)
			{
				if (Input.pressed(Player.keyLists[i][k]) && (scheme == i || scheme == Database.NONE))
					return true;
			}
			return false;
		}
		
		public override function update():void
		{
			var maxOption:uint = 0;
			var selected:Boolean = kCheck(4) || Input.pressed(Key.SPACE);
			
			switch(Main.menuPhase)
			{
			case 0: //main menu
				maxOption = 4;
				
				if (selected)
				{
					switch(optionOn)
					{
					case 0: //start a game
						prepareGame();
						Main.menuPhase = 1;
						optionOn = 0;
						break;
					case 1: //view highscores
						//preload the scores
						loadScores();
						highscoresA = new Array();
						for (i = 0; i < highscores.data.scores.length; i++)
							highscoresA.push(highscores.data.scores[i][2] + " the " + Main.data.lines[Main.data.endings[highscores.data.scores[i][1]][5]] + "     " + 
										highscores.data.scores[i][0]);
						closeScores();
						
						Main.menuPhase = 3;
						break;
					case 2: //sound effects
						Main.soundVol += 20;
						if (Main.soundVol > 100)
							Main.soundVol -= 100;
						break;
					case 3: //music
						Main.musicVol += 20;
						if (Main.musicVol > 100)
							Main.musicVol -= 100;
						Main.musicVolumeUpdate();
						break;
					}
					soundEffect(3);
				}
				break;
			case 1: //enter menu
				if (confirmedPlayers.length > 0)
				{
					var allCon:Boolean = true;
					for (var i:uint = 0; allCon && i < confirmedPlayers.length; i++)
						if (!confirmedPlayers[i])
							allCon = false;
					if (allCon)
					{
						//everyone picks names
						Main.menuPlayerOn = 0;
						Main.menuPhase = 4;
					}
				}
				
				for (i = 0; i < joinedPlayers.length; i++)
				{
					if (!confirmedPlayers[i])
					{
						var aA:int = 0;
						if (kCheck(0, joinedPlayers[i]))
							aA -= 1;
						if (kCheck(2, joinedPlayers[i]))
							aA += 1;
						if (aA != 0)
						{
							soundEffect(2);
							appearancePlayers[i] = (Main.data.appearances.length + appearancePlayers[i] + aA) % Main.data.appearances.length;
							Main.currentPlayers[i].applyAppearance(appearancePlayers[i], i);
						}
					}
					
					if (kCheck(4, joinedPlayers[i]))
					{
						soundEffect(3);
						confirmedPlayers[i] = !confirmedPlayers[i];
					}
				}
				
				//wait for player join input
				joinPlayer(0);
				joinPlayer(1);
				joinPlayer(2);
				joinPlayer(3);
				break;
			case 2: //highscore enter menu
				maxOption = 2;
				
				//TODO:
				//new high scores entry menu (plus high score calculation)
				//	high score calculation calculation:
				//		(final gold + total stats) * (1 + paragon/pariah modifier + victory modifier)
				//	there should be an actual breakdown of how each modifier 
				//	life classification modifiers: pacifist, stat-based, victory-based, etc
				//	this displays once per person
				
				if (selected)
				{
					soundEffect(3);
					if (optionOn == 0)
					{
						loadScores();
						
						//push it into the scores
						var newScore:Array = new Array();
						newScore.push(Main.currentPlayers[Main.menuPlayerOn].score);
						newScore.push(Main.currentPlayers[Main.menuPlayerOn].ending);
						newScore.push(Main.currentPlayers[Main.menuPlayerOn].name);
						highscores.data.scores.push(newScore);
						
						//sort the array
						highscores.data.scores.sort(scoreSort);
						
						//drop the lowest scores
						while (highscores.data.scores.length > Player.SCORE_LENGTH)
							highscores.data.scores.pop();
						
						closeScores();
					}
					
					Main.menuPlayerOn += 1;
					if (Main.menuPlayerOn == Main.currentPlayers.length) //return to main
						Main.menuPhase = 0;
					optionOn = 0;
				}
				
				break;
			case 3: //highscore view menu
				
				//TODO:
				
				if (selected)
				{
					soundEffect(3);
					Main.menuPhase = 0;
					optionOn = 0;
				}
				break;
			case 4: //name menu
				if (Input.pressed(Key.ENTER) && Main.currentPlayers[Main.menuPlayerOn].name.length > 0)
				{
					soundEffect(3);
					Main.menuPlayerOn += 1;
					if (Main.menuPlayerOn == Main.currentPlayers.length)
					{
						Main.menuPhase = Database.NONE;
						
						//load the intro dialogue
						Main.currentPlayers[0].beginningDialogue();
						
						//load the map
						FP.world = new Map(Main.currentPlayers, 0, 0, null, 0);
						//FP.world = new Map(Main.currentPlayers, 1, 5, "Final Battle", 0);
					}
				}
				else
					enterName();
				break;
			}
			
			if (maxOption != 0)
			{
				var oA:int = 0;
				if (kCheck(0))
					oA -= 1;
				if (kCheck(2))
					oA += 1;
					
				if (oA != 0)
				{
					optionOn = (maxOption + optionOn + oA) % maxOption;
					soundEffect(2);
				}
			}
		}
		
		private function enterName():void
		{
			var snd:Boolean = false;
			var cP:Player = Main.currentPlayers[Main.menuPlayerOn];
			for (var i:int = Key.A; i <= Key.Z; i++)
				if (Input.pressed(i))
				{
					snd = true;
					if (cP.name == "PLAYER")
						cP.name = "";
					if (cP.name.length < Player.SCORE_MAXNAME)
						cP.name += Key.name(i);
					break;
				}
				
			if (!snd && Input.pressed(Key.SPACE))
			{
				if (cP.name == "PLAYER")
					cP.name = "";
				if (cP.name.length > 0 && cP.name.charAt(cP.name.length - 1) != " ")
					cP.name += " ";
				snd = true;
			}
			
			if (!snd && Input.pressed(Key.BACKSPACE))
			{
				cP.name = cP.name.substr(0, cP.name.length - 1);
				snd = true;
			}
			
			if (snd)
				soundEffect(2);
		}
		
		private function loadScores():void
		{
			highscores = SharedObject.getLocal(Player.SCORE_NAME);
			if (!highscores.data.scores)
			{
				highscores.data.scores = new Array();
				
				//add empty scores
				for (var i:uint = 0; i < Player.SCORE_LENGTH; i++)
				{
					var newScore:Array = new Array();
					newScore.push(0);
					newScore.push(0);
					newScore.push("Nobody");
					
					highscores.data.scores.push(newScore);
				}
			}
		}
		
		private function closeScores():void
		{
			highscores.close();
		}
		
		public function Menu() 
		{
			Main.playMusic(6);
			Main.menuPhase = 0;
			optionOn = 0;
		}
		
		
		public static function scoreSort(a, b):int
		{
			return b[0] - a[0];
		}
	}
}