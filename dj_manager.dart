part of CursorDiscoServer;


/// Why a static class you wonder, isnt that against the guidelines?! 
/// Technically yes but it didnt make sense NOT to have a class for this
/// It makes it much easier to see where the functions are going
/// and what the functions are doing because of the class name
class DJManager {
  static String color = "lightblue";
  //Long list of colors coming up!
  static List<String> colors = ["AliceBlue","AntiqueWhite","Aqua","Aquamarine","Azure","Beige","Bisque","Black","BlanchedAlmond","Blue","BlueViolet","Brown","BurlyWood","CadetBlue","Chartreuse","Chocolate","Coral","CornflowerBlue","Cornsilk","Crimson","Cyan","DarkBlue","DarkCyan","DarkGoldenRod","DarkGray","DarkGreen","DarkKhaki","DarkMagenta","DarkOliveGreen","Darkorange","DarkOrchid","DarkRed","DarkSalmon","DarkSeaGreen","DarkSlateBlue","DarkSlateGray","DarkTurquoise","DarkViolet","DeepPink","DeepSkyBlue","DimGray","DimGrey","DodgerBlue","FireBrick","FloralWhite","ForestGreen","Fuchsia","Gainsboro","GhostWhite","Gold","GoldenRod","Gray","Green","GreenYellow","HoneyDew","HotPink","IndianRed ","Indigo ","Ivory","Khaki","Lavender","LavenderBlush","LawnGreen","LemonChiffon","LightBlue","LightCoral","LightCyan","LightGoldenRodYellow","LightGray","LightGreen","LightPink","LightSalmon","LightSeaGreen","LightSkyBlue","LightSlateGray","LightSteelBlue","LightYellow","Lime","LimeGreen","Linen","Magenta","Maroon","MediumAquaMarine","MediumBlue","MediumOrchid","MediumPurple","MediumSeaGreen","MediumSlateBlue","MediumSpringGreen","MediumTurquoise","MediumVioletRed","MidnightBlue","MintCream","MistyRose","Moccasin","NavajoWhite","Navy","OldLace","Olive","OliveDrab","Orange","OrangeRed","Orchid","PaleGoldenRod","PaleGreen","PaleTurquoise","PaleVioletRed","PapayaWhip","PeachPuff","Peru","Pink","Plum","PowderBlue","Purple","Red","RosyBrown","RoyalBlue","SaddleBrown","Salmon","SandyBrown","SeaGreen","SeaShell","Sienna","Silver","SkyBlue","SlateBlue","SlateGray","Snow","SpringGreen","SteelBlue","Tan","Teal","Thistle","Tomato","Turquoise","Violet","Wheat","White","WhiteSmoke","Yellow","YellowGreen"];

  static int sincelastbg = 0;
  static String currentSong;
  static Map<String, int> songs = new Map<String, int>();
  static Stopwatch timeGoing = new Stopwatch()..start();
  static Stopwatch songTime = new Stopwatch()..start();
  
  /// Called to load up our disco with songs
  static void loadDisco () {
    // Fill our songs map with the song name and length in seconds.
    songs["justcantgetenough.mp3"] = 227; 
    songs["funkytown.mp3"] = 344;
    currentSong = DJManager.getRandomSong();
    new Timer.periodic (new Duration(milliseconds: 10), (t) { DJManager.tick(); });
    
  }
  
  /// Used to resync clients. Sends the current song and time.
  static void sendCurrSongAndTime (CursorClientServer cur) {
    cur.send("CHANGESONG ${currentSong} ${(songTime.elapsedMilliseconds / 1000)}");
  }
  
  /// Returns a random song file name
  static String getRandomSong () {
    Random r = new Random();
    int n = r.nextInt(songs.length);
    Iterable key = songs.keys;
    return key.elementAt(n);
  }
  
  /// Grabs a random song and sends it to the clients.
  static void changeSong () {
    String rkey = DJManager.getRandomSong();
    songTime.reset();    
    currentSong = rkey;
    CursorClientServer.sendToAll("CHANGESONG ${rkey} 0");
  }
  
  /// Used to sync clients up. Sends the current background.
  static void sendCurrBackground (CursorClientServer cur) {
    cur.send("CHANGEBG ${color}");
  }
  
  /// Changes the background (Randomly) and sends an update to all clients
  static void changeBackground () {
    Random r = new Random();
    int n = r.nextInt(colors.length);
    color = colors[n];
    CursorClientServer.sendToAll("CHANGEBG ${color}");
  }
  
  /// Called every 10 ms
  static void tick () {
    if ((songTime.elapsedMilliseconds / 1000).toInt() > songs[currentSong]) {
      DJManager.changeSong();
      songTime.reset();
    }
    if (sincelastbg > 500) {
       DJManager.changeBackground();
       sincelastbg = 0;
      
    }
    sincelastbg += timeGoing.elapsedMilliseconds;
    timeGoing.reset();
  }
}
