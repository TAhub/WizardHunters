package game
{
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	import net.flashpunk.Sfx;
	
	public class Main extends Engine
	{
		//data stuff
		public static const data:Database = new Database();
		public static var dialogueMutexes:Array;
		public static var dialogueOnetimes:Array;
		
		//menu stuff
		public static var menuPhase:uint;
		public static var menuPlayerOn:uint;
		public static var currentPlayers:Array;
		public static var soundVol:uint;
		public static var musicVol:uint;
		
		//music
		private static var music:uint;
		
		public function Main()
		{
			super(800, 600);
			FP.screen.color = 0;
			soundVol = 100;
			musicVol = 100;
			music = Database.NONE;
			
			/** //map editor
			FP.world = new MapEditor();
			return;
			/**/
			
			FP.world = new Menu();
		}
		
		public static function musicVolumeUpdate():void
		{
			data.soundEffects[music].volume = musicVol * 0.01;
		}
		
		public static function playMusic(n:uint):void
		{
			if (music == n)
				return;
			if (music != Database.NONE)
				data.soundEffects[music].stop();
			music = n;
			data.soundEffects[music].loop(musicVol * 0.01);
		}
	}
	
}