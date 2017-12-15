// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* SETTINGS BEGIN */

// Serial port to connect to
String serialPortName = "/dev/cu.usbserial-DN03FBWO";

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = false;

/* SETTINGS END */

Serial serialPort; // Serial port object

// interface stuff
ControlP5 cp5;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

// plots

Graph LineGraph = new Graph(265, 140, 650, 400, color (20, 20, 200));

float[][] lineGraphValues = new float[2][500];
float[] lineGraphSampleNumbers = new float[500];
ArrayList<Float> fLineGraphSampleNumbers = new ArrayList<Float>();
ArrayList<Float> fLineGraphValues = new ArrayList<Float>();
float[] reversenumbers = new float[36000];
color[] graphColors = new color[2];
PrintWriter output;
boolean scroll = true;
boolean start = false;
int maxY = 50;
int minY = 0;
int minx = 0;
int dArraySize = 0;
String maxT = "0.00";
String maxP = "0.00";
int time = 0;
int readCount = 0;
Textlabel tDisplay;
Textlabel mTDisplay;
Textlabel pDisplay;
Textlabel mPDisplay;
Textfield path;
Textfield fileName;
Toggle scrollToggle;
// helper for saving the executing path
String topSketchPath = "";

void setup() {
  //println(fLineGraphSampleNumbers);
  frame.setTitle("Realtime plotter");
  size(980, 620);

  // set line graph colors
  addNumbers();  
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);

  // settings save file
  topSketchPath = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  cp5 = new ControlP5(this);
  
  // init charts


  //ArrayList test
 

  // build x axis values for the line graph
  for (int i=0; i<lineGraphValues.length; i++) {
    for (int k=0; k<lineGraphValues[0].length; k++) {
      lineGraphValues[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbers[k] = k;
   
    }
  }
  
  // start serial communication
  if (!mockupSerial) {
    //String serialPortName = Serial.list()[3];
    serialPort = new Serial(this, serialPortName, 115200);
  }
  else
    serialPort = null;

  // build the gui
  int x = 4;
  int y = 15;
 //font testing

 //
  
  
  path = cp5.addTextfield("FilePath").setPosition(x=125, y).setWidth(300).setAutoClear(false).setText("~/Documents/Graphs/");
  cp5.addButton("Path").setPosition(x = x+305, y).setWidth(40);
  fileName = cp5.addTextfield("FileName").setPosition(x=x+70, y).setText("NewFile").setWidth(100).setAutoClear(false);
  cp5.addButton("Save").setPosition(x = x+110, y).setWidth(40);
  cp5.addButton("Start").setPosition(x=x+90, y).setWidth(60);
  cp5.addButton("Stop").setPosition(x+80, y).setWidth(60);
  
  cp5.addToggle("scroll").setPosition(x=110, y=105).setMode(ControlP5.SWITCH);
  cp5.addTextlabel("label6").setText("Scroll [on/0ff]").setPosition(x=4, y= 105).setColor(0).setFont(createFont("Georgia",12));
  
  
  cp5.addTextlabel("label").setText("Temperature").setPosition(x=4, y= 150).setColor(0).setFont(createFont("Georgia",12));
  cp5.addTextlabel("label2").setText("Current Value").setPosition(x=10, y= 180).setColor(0).setFont(createFont("Georgia",10));
  cp5.addTextlabel("label3").setText("Max Value").setPosition(x=10, y= 208).setColor(0).setFont(createFont("Georgia",10));
  tDisplay = cp5.addTextlabel("digital").setText("45").setPosition(x=106, y = 179).setColor(0).setFont(createFont("Digital-7",18));
  mTDisplay = cp5.addTextlabel("digital2").setText("45").setPosition(x=106, y = 205).setColor(0).setFont(createFont("Digital-7",18));
  cp5.addToggle("lgVisible1").setPosition(x=110, y=150).setValue(int(getPlotterConfigString("lgVisible1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  cp5.addButton("reset").setPosition(x=70, y= 348).setWidth(35).setHeight(12);
  
  cp5.addTextlabel("multipliers").setText("Pressure").setPosition(x=4, y = 260).setColor(0).setFont(createFont("Georgia",12));
  cp5.addTextlabel("label4").setText("Current Value").setPosition(x=10, y= 290).setColor(0).setFont(createFont("Georgia",10));
  cp5.addTextlabel("label5").setText("Max Value").setPosition(x=10, y= 318).setColor(0).setFont(createFont("Georgia",10));
  pDisplay = cp5.addTextlabel("digital3").setText("45").setPosition(x=106, y = 289).setColor(0).setFont(createFont("Digital-7",18));
  mPDisplay = cp5.addTextlabel("digital4").setText("45").setPosition(x=106, y = 315).setColor(0).setFont(createFont("Digital-7",18));
  
  cp5.addToggle("lgVisible2").setPosition(x, y=258).setValue(int(getPlotterConfigString("lgVisible2"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[1]);
 
  Label label = path.getCaptionLabel();
  label.setColor(color(192, 192, 192));
  label = fileName.getCaptionLabel();
  label.setColor(color(192, 192, 192));
}

byte[] inBuffer = new byte[100]; // holds serial message
int i = 0; // loop variable
void draw() {
  background(255);
  /* Read serial and update values */
  if (mockupSerial || serialPort.available() > 0) {
    String myString = "";
    if (!mockupSerial) {
      try {
        serialPort.readBytesUntil('\r', inBuffer);
        readCount++;
        if (readCount % 10 == 0){
           time++;
             if (time > 50){
          minx++;
            if(scroll){
             
             updateTimeAxis();
           }
        }
        }
        if (!scroll){
        if (time % 10 == 0){
          updateTimeAxis();
        }
        }
        
      
        if (readCount % 500 == 0){
         addNumbers();
        }
      }
      catch (Exception e) {
      }
      myString = new String(inBuffer);
    }
    else {
      myString = mockupSerialFunction();
    }

    //println(myString);
  //  println(scroll);
    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');
    
    // check max y from serial
   // output.println(nums[0]);
    for (int i = 0; i<nums.length-2; i++){
      if (int(nums[i]) > int(maxY)){
        maxY = int(nums[i]);
      }
      if (int(nums[i]) < minY){
       minY = int(nums[i]); 
      }
    }
    
    
    if (nums.length > 2){
      tDisplay.setText(nums[0]);
         pDisplay.setText(nums[1]);
    if(float(nums[0]) > float(maxT)){
      maxT = nums[0];
    }
    if(float(nums[1]) > float(maxP)){
      maxP = nums[1];
    }
    }
     
     mTDisplay.setText(maxT);
     mPDisplay.setText(maxP);
     LineGraph.yMax=maxY;
     LineGraph.yMin=minY;
   

    for (i=0; i<nums.length - 1; i++) {
      // update line graph
      try {
        if (i<lineGraphValues.length) {
          for (int k=0; k<lineGraphValues[i].length-1; k++) {
            lineGraphValues[i][k] = lineGraphValues[i][k+1];
          }
          if (i == 0){
            fLineGraphValues.add(float(nums[0]));
             
          }
          lineGraphValues[i][lineGraphValues[i].length-1] = float(nums[i]);
         
      }
        if (start){
            
            output.print(float(nums[i])+" "); 
            if (i == nums.length-2){
            output.print("\n");
            }
           }
      }
      
      catch (Exception e) {
      }
    }
  }

//println(lineGraphValues[1]);
  // draw the bar chart
  
  // draw the line graphs
  fill(220,220,220);
  stroke(0);
  rect(0,0,978,618);//backgorund
  fill(255,255,255);
  rect(4,81,161,518); //tools
  fill(192,192,192);
  rect(0,0,978,48); //top
  
  LineGraph.DrawAxis();
  for (int i=0;i<lineGraphValues.length; i++) {
    LineGraph.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      if (scroll){
        LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
      }
      else{
        LineGraph.FLineGraph(fLineGraphSampleNumbers, fLineGraphValues);
      }
  }
}

void addNumbers(){
   dArraySize = fLineGraphSampleNumbers.size() + 500;
  for (int fi=fLineGraphSampleNumbers.size();  fi < dArraySize; fi++){
               fLineGraphSampleNumbers.add(fi,float(fi));
             }
  
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  LineGraph.xLabel=" Time [s] ";
  LineGraph.yLabel="Value";
  LineGraph.Title="Test";  
  LineGraph.xDiv=10;  
  LineGraph.xMax=50; 
  LineGraph.xMin=0;  
  LineGraph.yMax=maxY; 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}


void updateTimeAxis(){
  
    LineGraph.xMax = time;
    if (scroll){
    LineGraph.xMin = minx;
    }
  
}

void CreateFile(){
  String p = path.getText()+"/"+fileName.getText();
 
  if(!p.contains(".txt")){
    p = p+ ".txt"; 
  }
  if (start){
    println("cretedOutput");
    output = createWriter(p);
  }
  
}

void CloseFile(){
  output.flush();
  output.close();
  println("closedFile");
}


// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";

    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}

public void reset(){
  
 maxT = "0.00";
 maxP = "0.00";
}

public void Path(){
  
   selectFolder("Select a folder to save graph:", "folderSelected"); 
}

void Start(){
   start = true;
 CreateFile(); 
  
}

void Stop(){
  
 CloseFile(); 
  
}

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    path.setText(selection.getAbsolutePath());
  }
}