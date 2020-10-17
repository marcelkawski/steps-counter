import ketai.data.*;
import ketai.sensors.*;

KetaiSensor sensor;
KetaiSQLite db;
int steps;
int counter;
final int MAG_MIN = 5;
final int MAG_MAX = 15;
final int STEP_CRITERION = 30;
final int DATA_STEP = 1;
final int SMALL_DOT_SIZE = 5;
final int BIG_DOT_SIZE = 10;
boolean isCapturing = false;
ArrayList<Integer> minMax;
ArrayList<Integer> times;
ArrayList<PVector> data;

String CREATE_DB_SQL = "CREATE TABLE data ( time INTEGER PRIMARY KEY, x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL);";

void setup()
{
  db = new KetaiSQLite(this);
  sensor = new KetaiSensor(this);
  frameRate(5);
  orientation(LANDSCAPE);
  textAlign(CENTER, CENTER);
  textSize(45);

  if (db.connect())
  {
    if (!db.tableExists("data"))
      db.execute(CREATE_DB_SQL);
  }
  sensor.start();
}

void draw() 
{
  background(0);
  if (isCapturing)
    text("Steps detecting...\nTap the screen to stop", width/2, height/5);
  else 
  { 
    readData();
    text("Displaying last " + width + " point(s) of data", width/2, height/7);
  }
  text("Current data counter: " + db.getDataCount(), width/5, height-height/9);
  pushStyle();
  textSize(90);
  text("Steps: " + steps, width-width/5, height-height/5);
  popStyle();
}

void mousePressed()
{
   if (isCapturing) 
     isCapturing = false;
   else 
     isCapturing = true;
}

void onAccelerometerEvent(float x, float y, float z, long time, int accuracy)
{
  if (db.connect() && isCapturing)
  {
    if (!db.execute("INSERT into data (`time`,`x`,`y`,`z`) VALUES ('"+System.currentTimeMillis()+"', '"+x+"', '"+y+"', '"+z+"')"))
      println("Failed to record data!" );
  }
}

void readData() 
{
  if (db.connect())
  {
     data = new ArrayList();
     times = new ArrayList();
     minMax = new ArrayList();
     pushStyle();
     noStroke();
     db.query( "SELECT * FROM data ORDER BY time DESC LIMIT " + width);
     int i = 0;   
     
     while (db.next())
     {

       float x = db.getFloat("x");
       float y = db.getFloat("y");
       float z = db.getFloat("z");
       long  t = db.getLong("time");

       data.add(new PVector(x, y, z));
       times.add((int)t);
     }
     
     detectCandidates();
     steps = 0;
     counter = 0;
     
     if(data.size() != 0) 
     {
        for (int j=0; j<minMax.size(); j++)
        {
          PVector d = data.get(j);
          int mm = minMax.get(j);
          
          fill(255, 0, 0);
          ellipse(i, map(d.mag(), -30, 30, 0, height/1.5), SMALL_DOT_SIZE, SMALL_DOT_SIZE);
          noFill();
          
          if (d.mag()>MAG_MAX || d.mag()<MAG_MIN)
          {
             if(mm==1)
             {
                fill(0, 255, 0);
                if(counter>STEP_CRITERION)
                {
                   steps++ ;
                   counter=0;
                }
             }
             else if (mm==-1)
               fill(0, 70, 255);
          }
          
          ellipse(i, map(d.mag(), -30, 30, 0, height/1.5), BIG_DOT_SIZE, BIG_DOT_SIZE);
          i += DATA_STEP;
          counter++;
        }
     }
     
     popStyle();
  }
}

void detectCandidates() 
{
   minMax = new ArrayList();
   minMax.add(0);
   for(int i=1; i<data.size()-1; i++) 
   {
      float previous, current, next;
      previous = data.get(i-1).mag();
      current = data.get(i).mag();
      next = data.get(i+1).mag();
      int aux = 0;
      
      if (current > max(previous, next))
        aux = 1;
      else if (current < min(previous, next))
        aux = -1;
        
      minMax.add(aux);
   } 
   minMax.add(0);
}
