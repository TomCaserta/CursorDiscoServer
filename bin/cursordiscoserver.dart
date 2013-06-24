library CursorDiscoServer;

import 'dart:io';
import 'dart:async';
import 'dart:math';

part 'dj_manager.dart';

int port = 8000;

void main() {
  DJManager.loadDisco();
  /// Start a new websocket server on [port]
  HttpServer.bind('0.0.0.0', port).then((HttpServer server) { 
    print('Starting CursorDisco on port: $port');
      server.listen((req) {
        WebSocketTransformer.upgrade(req).then((websocket) => CursorClientServer.onConnection(websocket)).catchError((e) { print("Transform Error: $e"); });
      }, onError: (e) { print("ERROR: $e"); });

  }).catchError((e) => print(e));;
 
}


/// Holds all our websocket clients
class CursorClientServer {
  static Map<String, CursorClientServer> connections = new Map<String, CursorClientServer>();
  dynamic ws;
  double x = 0.0, y = 0.0;
  int currentPlayback = 0;
  
  CursorClientServer (this.ws) { if (!connections.containsKey(this.ws.hashCode.toString())) { connections[this.ws.hashCode.toString()] = this; } }
  
  /// Sends a [message] to the client
  void send (String message) {
    print("> Sent: ${message}");
    this.ws.add(message); 
  }
   
  //Static Methods
  
  
  /// Sends a disconnect message to all clients and destroys the connection [conn]
  static void destroy (conn) {
    print("User disconnected");
    CursorClientServer.sendToAll("DISCONNECT ${conn.hashCode}", conn);
    connections.remove(conn.hashCode.toString());
  }

  /// Sends a message to all clients with an open WebSocket
  static void sendToAll (String message, [WebSocket self]) {
    CursorClientServer.connections.forEach((String hash, CursorClientServer connection) {
      if (self != null) {
        if (self.hashCode.toString() != hash) {
          connection.send(message);
        }
      } else connection.send(message);
    });
  }

  /// Fetches the instance of CursorClientServer which matches the WebSocket [conn]
  static CursorClientServer getCCC (WebSocket conn) {
    return CursorClientServer.connections[conn.hashCode.toString()];
  }
  
  /// Is called every time there is a new connection to the server
  /// Creates the associated CursorClientServer and sends a message
  /// to all clients with the hashcode.
  static void onConnection (conn) {
    print("New Connection :)");
    
    CursorClientServer current = new CursorClientServer(conn);
   
    CursorClientServer.sendToAll("NEWCONNECTION ${conn.hashCode} ${current.x} ${current.y}", conn);
    
    // Sync client up with the current background and song
    DJManager.sendCurrBackground(current);
    DJManager.sendCurrSongAndTime(current);
    CursorClientServer.connections.forEach((String k,CursorClientServer v) {
      print("$k == ${conn.hashCode}");
      if (k != conn.hashCode.toString()) current.send("NEWCONNECTION $k ${v.x} ${v.y}");    
    });
    conn.listen((message) {
      CursorClientServer CCC = CursorClientServer.getCCC(conn);
      print('< Recieved: $message FROM ID: ${CCC.ws.hashCode}');
      CursorClientServer.handleResponse(CCC, message);
    },
        onDone: () => CursorClientServer.destroy(conn),
        onError: (e) => CursorClientServer.destroy(conn)
    );
  }
 
  /// Response handler for the connected clients
  static void handleResponse (CursorClientServer self, String message) {
      var splitMsg = message.split(" ");
      switch (splitMsg[0]) {
        case "MOVECURSOR": 
          
          // iPads like to send null values when they click the home button!
          bool isErrored = false;
          double x = double.parse(splitMsg[1],(error) { 
            isErrored = true;            
          });
          double y = double.parse(splitMsg[2],(error) { 
            isErrored = true;             
          });
          if (!isErrored) {
              // Convert the X Y co-ordinates sent by the client into a percentage of the screen
              double screen_width = double.parse(splitMsg[3]);
              double screen_height = double.parse(splitMsg[4]);
             
              double percent_width = (x /screen_width) * 100;
              double percent_height = (y / screen_height) * 100;
              self.x = x;
              self.y = y;
              // Send cursor update to all clients
              CursorClientServer.sendToAll("MOVECURSOR ${self.ws.hashCode} $percent_width $percent_height",self.ws);
          }
          else print("Malicious value sent from client intercepted (basically not a double).");
          break;
        case  "TIMEUPD": 
          bool isErrored = false;
          // This message is sent every time a clients music progresses. 
          double songTime = double.parse(splitMsg[1], (error) { isErrored = true; });
          if (!isErrored) {
            int songSync = (songTime - (DJManager.songTime.elapsedMilliseconds / 1000)).toInt();
            // If the music is out of sync then we should resend the song and time
            if (!(songSync < 5 && songSync > -5)) DJManager.sendCurrSongAndTime(self); 
          }
          else print ("Malicious value sent from client intercepted (basically not a double).");
         break;
      }
      
  } 
}