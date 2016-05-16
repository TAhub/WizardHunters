package game {
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.Sfx;
	public class Database 
	{
		//sprites
		[Embed(source = "sprites/body.png")] private static const SPR1:Class;
		[Embed(source = "sprites/armor.png")] private static const SPR2:Class;
		[Embed(source = "sprites/hair.png")] private static const SPR3:Class;
		[Embed(source = "sprites/weapon.png")] private static const SPR4:Class;
		[Embed(source = "sprites/projectile.png")] private static const SPR5:Class;
		[Embed(source = "sprites/tile.png")] private static const SPR6:Class;
		[Embed(source = "sprites/armorLegs.png")] private static const SPR7:Class;
		[Embed(source = "sprites/armorArms.png")] private static const SPR8:Class;
		[Embed(source = "sprites/leafPattern.png")] private static const SPR9:Class;
		[Embed(source = "sprites/cavePattern.png")] private static const SPR10:Class;
		[Embed(source = "sprites/fragment.png")] private static const SPR11:Class;
		
		//sound effects
		[Embed(source = "sounds/215025_taira-komori_swing1.mp3")] private static const SND1:Class;
		[Embed(source = "sounds/180894_jobro_cash-register-opening.mp3")] private static const SND2:Class;
		[Embed(source = "sounds/50561_broumbroum_sf3-sfx-menu-select.mp3")] private static const SND3:Class;
		[Embed(source = "sounds/50565_broumbroum_sf3-sfx-menu-validate.mp3")] private static const SND4:Class;
		[Embed(source = "sounds/138481_randomationpictures_bullet-blood-4.mp3")] private static const SND5:Class;
		[Embed(source = "sounds/172207_fins_teleport.mp3")] private static const SND6:Class;
		[Embed(source = "sounds/Anguish.mp3")] private static const SND7:Class;
		[Embed(source = "sounds/Undaunted.mp3")] private static const SND8:Class;
		[Embed(source = "sounds/Black Vortex.mp3")] private static const SND9:Class;
		
		//files
		[Embed(source = "data/data.txt", mimeType = "application/octet-stream")] private static const DATA:Class;
		[Embed(source = "data/lines.txt", mimeType = "application/octet-stream")] private static const LINES:Class;
		
		public static const NONE:uint = 999999999;
		public var lines:Array = new Array();
		public var spriteSheets:Array = new Array();
		public var soundEffects:Array = new Array();
		private var sheets:Array = new Array();
		private var sounds:Array = new Array();
		
		//other lists
		public var armors:Array = new Array();
		public var weapons:Array = new Array();
		public var races:Array = new Array();
		public var templates:Array = new Array();
		public var tiles:Array = new Array();
		public var aboveTiles:Array = new Array();
		public var tileAlternateSchemes:Array = new Array();
		public var tilesets:Array = new Array();
		public var hairStyles:Array = new Array();
		public var colors:Array = new Array();
		public var lists:Array = new Array();
		public var levelBundles:Array = new Array();
		public var numPlayerDatas:Array = new Array();
		public var appearances:Array = new Array();
		public var colorations:Array = new Array();
		public var dialogues:Array = new Array();
		public var dialogueChoices:Array = new Array();
		public var dialogueVariables:Array = new Array();
		public var premadeMaps:Array = new Array();
		public var fragments:Array = new Array();
		public var npcTemplates:Array = new Array();
		public var enemySets:Array = new Array();
		public var effects:Array = new Array();
		public var effectSkills:Array = new Array();
		public var shopLists:Array = new Array();
		public var itemTypes:Array = new Array();
		public var endings:Array = new Array();
		public var lightPatterns:Array = new Array();
		
		public function Database() 
		{
			//read lines
			var lineNames:Array = new Array();
			var data:Array = new LINES().toString().split("\n");
			for (var i:uint = 0; i < data.length - 1; i++)
			{
				var line:String = data[i];
				if (line.charAt(0) != "/")
				{
					var lineName:String = "";
					var lineContent:String = "";
					var onName:Boolean = true;
					for (var j:uint = 0; j < line.length - 1; j++)
					{
						if (onName && line.charAt(j) == " ")
							onName = false;
						else if (onName)
							lineName += line.charAt(j);
						else
							lineContent += line.charAt(j);
					}
					lineNames.push(lineName);
					lines.push(lineContent);
				}
			}
			
			//read data
			
			data = new DATA().toString().split("\n");
			
			//analyze data
			var allArrays:Array = new Array();
			//remember to push each data array into allarrays
			//if you don't put something into allArrays, it won't be linked with anything
			
			allArrays.push(sheets);
			allArrays.push(sounds);
			//other lists
			allArrays.push(armors);
			allArrays.push(weapons);
			allArrays.push(races);
			allArrays.push(templates);
			allArrays.push(tiles);
			allArrays.push(fragments);
			allArrays.push(tilesets);
			allArrays.push(tileAlternateSchemes);
			allArrays.push(hairStyles);
			allArrays.push(effects);
			allArrays.push(effectSkills);
			allArrays.push(colors);
			allArrays.push(lists);
			allArrays.push(colorations);
			allArrays.push(dialogues);
			allArrays.push(dialogueChoices);
			allArrays.push(dialogueVariables);
			allArrays.push(premadeMaps);
			allArrays.push(npcTemplates);
			allArrays.push(enemySets);
			allArrays.push(shopLists);
			allArrays.push(itemTypes);
			allArrays.push(aboveTiles);
			allArrays.push(levelBundles);
			allArrays.push(lightPatterns);
			allArrays.push(numPlayerDatas);
			allArrays.push(appearances);
			allArrays.push(endings);
			
			var arrayOn:Array;
			for (i = 0; i < data.length; i++)
			{
				line = data[i];
				line = line.substr(0, line.length - 1);
				if (line.charAt(0) != "/")
				{
					switch(line)
					{
						//other lists
					case "ARMOR:":
						arrayOn = armors;
						break;
					case "WEAPON:":
						arrayOn = weapons;
						break;
					case "RACE:":
						arrayOn = races;
						break;
					case "TEMPLATE:":
						arrayOn = templates;
						break;
					case "TILE:":
						arrayOn = tiles;
						break;
					case "TILESET:":
						arrayOn = tilesets;
						break;
					case "TILEALTERNATESCHEME:":
						arrayOn = tileAlternateSchemes;
						break;
					case "HAIRSTYLE:":
						arrayOn = hairStyles;
						break;
					case "COLOR:":
						arrayOn = colors;
						break;
					case "EFFECT:":
						arrayOn = effects;
						break;
					case "NUMPLAYERDATA:":
						arrayOn = numPlayerDatas;
						break;
					case "EFFECTSKILL:":
						arrayOn = effectSkills;
						break;
					case "LIST:":
						arrayOn = lists;
						break;
					case "COLORATION:":
						arrayOn = colorations;
						break;
					case "ABOVETILE:":
						arrayOn = aboveTiles;
						break;
					case "LEVELBUNDLE:":
						arrayOn = levelBundles;
						break;
					case "DIALOGUE:":
						arrayOn = dialogues;
						break;
					case "DIALOGUECHOICE:":
						arrayOn = dialogueChoices;
						break;
					case "DIALOGUEVAR:":
						arrayOn = dialogueVariables;
						break;
					case "FRAGMENT:":
						arrayOn = fragments;
						break;
					case "PREMADEMAP:":
						arrayOn = premadeMaps;
						break;
					case "NPCTEMPLATE:":
						arrayOn = npcTemplates;
						break;
					case "ENEMYSET:":
						arrayOn = enemySets;
						break;
					case "SHOPLIST:":
						arrayOn = shopLists;
						break;
					case "ITEMTYPE:":
						arrayOn = itemTypes;
						break;
					case "LIGHTPATTERN:":
						arrayOn = lightPatterns;
						break;
					case "APPEARANCE:":
						arrayOn = appearances;
						break;
					case "ENDING:":
						arrayOn = endings;
						break;
						
						//core lists
					case "SHEET:":
						arrayOn = sheets;
						break;
					case "SOUND:":
						arrayOn = sounds;
						break;
					case "FILLERDATA:":
						arrayOn = new Array();
						break;
					default:
						//tbis is a data line
						var ar:Array = line.split(" ");
						var newEntry:Array = new Array();
						for (j = 0; j < ar.length; j++)
						{
							//see if it's a string or a number
							if (j == 0)
								newEntry.push(ar[j]); //it's the name
							else if (ar[j] == "none") //it's an empty reference
								newEntry.push(NONE);
							else if (ar[j] == "true")
								newEntry.push(true);
							else if (ar[j] == "false")
								newEntry.push(false);
							else if (isNaN(ar[j]))
							{
								var st:String = ar[j] as String;
								if (st.charAt(0) == "@") //it's a line!
								{
									if (ar[j] == "@none") //it's an empty line
										newEntry.push(NONE);
									else
									{
										//find the line
										var foundLine:Boolean = false;
										for (var k:uint = 0; k < lineNames.length; k++)
											if ("@" + lineNames[k] == ar[j])
											{
												foundLine = true;
												newEntry.push(k);
												break;
											}
										if (!foundLine)
										{
											trace("Unable to find line " + ar[j]);
											newEntry.push(NONE);
										}
									}
								}
								else
									newEntry.push(st);
							}
							else
								newEntry.push((int) (ar[j]));
						}
						//push the finished list
						arrayOn.push(newEntry);
						break;
					}
				}
			}
			
			//link them
			link(allArrays);
			
			//link up sound effects
			for (i = 0; i < sounds.length; i++)
			{
				var SRC:Class;
				switch(i)
				{
				case 0:
					SRC = SND1;
					break;
				case 1:
					SRC = SND2;
					break;
				case 2:
					SRC = SND3;
					break;
				case 3:
					SRC = SND4;
					break;
				case 4:
					SRC = SND5;
					break;
				case 5:
					SRC = SND6;
					break;
				case 6:
					SRC = SND7;
					break;
				case 7:
					SRC = SND8;
					break;
				case 8:
					SRC = SND9;
					break;
				}
				
				var snd:Sfx = new Sfx(SRC);
				soundEffects.push(snd);
			}
			
			//load up spritesheets
			for (i = 0; i < sheets.length; i++)
			{
				switch(i)
				{
				case 0:
					SRC = SPR1;
					break;
				case 1:
					SRC = SPR2;
					break;
				case 2:
					SRC = SPR3;
					break;
				case 3:
					SRC = SPR4;
					break;
				case 4:
					SRC = SPR5;
					break;
				case 5:
					SRC = SPR6;
					break;
				case 6:
					SRC = SPR7;
					break;
				case 7:
					SRC = SPR8;
					break;
				case 8:
					SRC = SPR9;
					break;
				case 9:
					SRC = SPR10;
					break;
				case 10:
					SRC = SPR11;
					break;
				}
				
				var spr:Spritemap = new Spritemap(SRC, sheets[i][1], sheets[i][2]);
				spr.originX = sheets[i][3];
				spr.originY = sheets[i][4];
				spriteSheets.push(spr);
			}
			
			//unload excess data
			sheets = null;
			sounds = null;
		}
		
		private function link(allArrays:Array):void
		{
			for (var i:uint = 0; i < allArrays.length; i++)
			{
				var arrayOn:Array = allArrays[i];
				
				for (var j:uint = 0; j < arrayOn.length; j++)
				{
					var entry:Array = arrayOn[j];
					
					for (var k:uint = 1; k < entry.length; k++)
					{
						if (isNaN(entry[k]))
						{
							var st:String = entry[k] as String;
							if (st.charAt(0) == "#") //it's a literal word
							{
								var newSt:String = "";
								for (var l:uint = 1; l < st.length; l++)
								{
									if (st.charAt(l) == "#")
										newSt += " ";
									else
										newSt += st.charAt(l);
								}
								entry[k] = newSt;
							}
							else
							{
								//link it somewhere
								
								var found:Boolean = false;
								for (l = 0; l < allArrays.length && !found; l++)
								{
									var arrayCheck:Array = allArrays[l];
									
									for (var m:uint = 0; m < arrayCheck.length; m++)
									{
										if (arrayCheck[m][0] == st)
										{
											entry[k] = m;
											found = true;
											break;
										}
									}
								}
								
								if (!found)
									trace("Unable to find " + entry[k]);
							}
						}
					}
				}
			}
		}
	}

}