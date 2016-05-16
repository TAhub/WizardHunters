package game 
{
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.graphics.Spritemap;
	import flash.geom.Point;
	
	public class MapEditor extends World
	{
		private var width:uint;
		private var height:uint;
		private var tiles:Array;
		private var cursorX:uint;
		private var cursorY:uint;
		private var placeX:uint;
		private var placeY:uint;
		private var startP:Point;
		private var npcGrid:Array;
		private var npcNGrid:Array;
		
		public function MapEditor() 
		{
			//width and height, at the moment, cannot be changed in-editor but instead has to be changed in-source
			//if this was supposed to be a player-usable map-editor that'd be a problem but it's not so hey
			
			cursorX = 0;
			cursorY = 0;
			placeX = 0;
			placeY = 0;
			
			/**/ //load map
			load(0);
			/**/
			
			/** //initialize empty
			startP = new Point(0, 0);
			width = 100;
			height = 100;
			npcGrid = new Array();
			npcNGrid = new Array();
			tiles = new Array();
			for (var i:uint = 0; i < width * height; i++)
			{
				npcGrid.push(null);
				npcNGrid.push(Database.NONE);
				tiles.push(0);
			}
			/**/
		}
		
		private function load(num:uint):void
		{
			width = Main.data.premadeMaps[num][1];
			height = Main.data.premadeMaps[num][2];
			startP = new Point(Main.data.premadeMaps[num][3], Main.data.premadeMaps[num][4]);
			tiles = new Array();
			npcNGrid = new Array();
			npcGrid = new Array();
			for (var i:uint = 0; i < width * height; i++)
			{
				tiles.push(Main.data.premadeMaps[num][5 + i]);
				npcNGrid.push(Database.NONE);
				npcGrid.push(null);
			}
			for (i = 0; i < (Main.data.premadeMaps[num].length - 5 - width * height); i += 2)
			{
				var j:uint = Main.data.premadeMaps[num][5 + width * height + i];
				var n:uint = Main.data.premadeMaps[num][6 + width * height + i];
				npcNGrid[j] = n;
				var x:uint = j % width;
				var y:uint = j / width;
				npcGrid[j] = new Creature((x + 0.5) * Map.MAP_TILESIZE, (y + 0.5) * Map.MAP_TILESIZE, true, n, true);
			}
		}
		
		public override function update():void
		{
			var xA:int = 0;
			var yA:int = 0;
			
			if (Input.pressed(Key.W))
				yA -= 1;
			if (Input.pressed(Key.S))
				yA += 1;
			if (Input.pressed(Key.A))
				xA -= 1;
			if (Input.pressed(Key.D))
				xA += 1;
				
			if (cursorY == 0 && yA == -1)
				cursorY = height - 1;
			else if (cursorY == height - 1 && yA == 1)
				cursorY = 0;
			else
				cursorY += yA;
			if (cursorX == 0 && xA == -1)
				cursorX = width - 1;
			else if (cursorX == width - 1 && xA == 1)
				cursorX = 0;
			else
				cursorX += xA;
				
			var pXA:int = 0;
			var pYA:int = 0;
			
			if (Input.pressed(Key.R))
				pYA -= 1;
			if (Input.pressed(Key.F))
				pYA += 1;
			if (Input.pressed(Key.Q))
				pXA -= 1;
			if (Input.pressed(Key.E))
				pXA += 1;
				
			if (pXA != 0)
			{
				pYA = 0;
				placeY = 0;
			}
				
			var placeXMax:uint = 3;
			var placeYMax:uint;
			switch(placeX)
			{
			case 0: //tile
				placeYMax = Main.data.tiles.length;
				break;
			case 1: //player
				placeYMax = 1;
				break;
			case 2: //npc
				placeYMax = Main.data.npcTemplates.length;
				break;
			}
			
			if (placeY == 0 && pYA == -1)
				placeY = placeYMax - 1;
			else if (placeY == placeYMax - 1 && pYA == 1)
				placeY = 0;
			else
				placeY += pYA;
			if (placeX == 0 && pXA == -1)
				placeX = placeXMax - 1;
			else if (placeX == placeXMax - 1 && pXA == 1)
				placeX = 0;
			else
				placeX += pXA;
				
			var i:uint = cursorX + cursorY * width;
			if (Input.pressed(Key.SPACE))
				switch(placeX)
				{
				case 0:
					if (Input.check(Key.SHIFT))
						for (var j:uint = 0; j < tiles.length; j++)
							if (j != i && tiles[j] == tiles[i])
								tiles[j] = placeY;
					tiles[i] = placeY;
					break;
				case 1:
					startP.x = cursorX;
					startP.y = cursorY;
					break;
				case 2:
					if (npcNGrid[i] != Database.NONE)
					{
						npcNGrid[i] = Database.NONE;
						npcGrid[i] = null;
					}
					else
					{
						var n:Creature = new Creature((cursorX + 0.5) * Map.MAP_TILESIZE, (cursorY + 0.5) * Map.MAP_TILESIZE, true, placeY, true);
						npcGrid[i] = n;
						npcNGrid[i] = placeY;
					}
					break;
				}
				
			if (Input.pressed(Key.I))
				recut();
				
			if (Input.pressed(Key.P))
			{
				//save!
				trace("SAVING");
				var saveStr:String = "pmp_*** " + width + " " + height + " " + startP.x + " " + startP.y;
				for (i = 0; i < width * height; i++)
					saveStr += " " + tiles[i];
				for (i = 0; i < width * height; i++)
					if (npcNGrid[i] != Database.NONE)
						saveStr += " " + i + " " + npcNGrid[i];
				trace(saveStr);
				trace("SAVING COMPLETE");
			}
		}
		
		private function recut():void
		{
			var top:uint = height;
			var left:uint = width;
			var right:uint = 0;
			var bottom:uint = 0;
			
			for (var y:uint = 0; y < height; y++)
				for (var x:uint = 0; x < width; x++)
				{
					if (tiles[x + y * width] != 0)
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
				}
				
			var newWidth:uint = (right - left + 1) + 4;
			var newHeight:uint = (bottom - top + 1) + 4;
			
			startP.x += 2 - left;
			startP.y += 2 - top;
			cursorX += 2 - left;
			cursorY += 2 - top;
			
			var newTiles:Array = new Array();
			var newNPCGrid:Array = new Array();
			var newNPCNGrid:Array = new Array();
			for (var i:uint = 0; i < newWidth * newHeight; i++)
			{
				newTiles[i] = 0;
				newNPCGrid[i] = null;
				newNPCNGrid[i] = Database.NONE;
			}
				
			for (y = top; y <= bottom; y++)
				for (x = left; x <= right; x++)
				{
					var newI:uint = (x - left + 2) + (y - top + 2) * newWidth;
					i = x + y * width;
					newTiles[newI] = tiles[i];
					newNPCGrid[newI] = npcGrid[i];
					newNPCNGrid[newI] = npcNGrid[i];
					if (npcGrid[i] != null)
					{
						npcGrid[i].x += (2 - left) * Map.MAP_TILESIZE;
						npcGrid[i].y += (2 - top) * Map.MAP_TILESIZE;
					}
				}
					
			width = newWidth;
			height = newHeight;
			tiles = newTiles;
			npcGrid = newNPCGrid;
			npcNGrid = newNPCNGrid;
		}
		
		public override function render():void
		{
			var sX:int = cursorX - (FP.halfWidth / Map.MAP_TILESIZE);
			var sY:int = cursorY - (FP.halfHeight / Map.MAP_TILESIZE);
			if (sX < 0)
				sX = 0;
			if (sY < 0)
				sY = 0;
			FP.camera.x = sX * Map.MAP_TILESIZE;
			FP.camera.y = sY * Map.MAP_TILESIZE;
			var tileSp:Spritemap = Main.data.spriteSheets[5];
			for (var y:uint = sY; y < height && y < sY + FP.height / Map.MAP_TILESIZE; y++)
				for (var x:uint = sX; x < width && x < sX + FP.width / Map.MAP_TILESIZE; x++)
				{
					var tI:uint = tiles[x + y * width];
					if (tI != 0)
					{
						tileSp.frame = Main.data.tiles[tI][1];
						tileSp.color = Main.data.colors[Main.data.tiles[tI][2]][1];
						tileSp.render(FP.buffer, new Point(x * Map.MAP_TILESIZE, y * Map.MAP_TILESIZE), FP.camera);
					}
					var n:Creature = npcGrid[x + y * width];
					if (n != null)
						n.render();
				}
			FP.buffer.fillRect(new Rectangle((startP.x + 0.5) * Map.MAP_TILESIZE - FP.camera.x,
											(startP.y + 0.5) * Map.MAP_TILESIZE - FP.camera.y,
											Map.MAP_TILESIZE / 2, Map.MAP_TILESIZE / 2), 0x00FF00);
			FP.buffer.fillRect(new Rectangle((cursorX + 0.5) * Map.MAP_TILESIZE - FP.camera.x,
											(cursorY + 0.5) * Map.MAP_TILESIZE - FP.camera.y,
											Map.MAP_TILESIZE / 2, Map.MAP_TILESIZE / 2), 0xFFFFFF);
				
			var placeS:String = "(" + width + ", " + height + ") ";
			switch(placeX)
			{
			case 0:
				placeS += "TILE: ";
				placeS += Main.data.tiles[placeY][0];
				break;
			case 1:
				placeS += "START POSITION";
				break;
			case 2:
				placeS += "NPC: ";
				placeS += Main.data.npcTemplates[placeY][0];
				break;
			}
			var placeT:Text = new Text(placeS);
			placeT.render(FP.buffer, FP.zero, FP.zero);
		}
		
	}

}