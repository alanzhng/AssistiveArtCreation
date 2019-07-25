import processing.sound.*;

static final int NONE = 0;
static final int PARTICLE = 1;
static final int WAVEFORM = 2;
static final int ALL = 9;
int drawMode = 0;

ArrayList<Particle> pts;
float ampt, freq, centerx, centery;
boolean showInstruction;
int bands = 256;
float[] spectrum = new float[bands];
PFont f;
FFT fft;
Amplitude amp;
Waveform waveform;
AudioIn in;

void setup() {

  fullScreen();
  centerx = width/2;
  centery = height/2;
  frameRate(350);
  colorMode(RGB); 
  showInstruction = true;
  //f = createFont("Arial", 24);
  pts = new ArrayList<Particle>();
  
  amp = new Amplitude(this);
  fft = new FFT(this, bands);
  waveform = new Waveform(this, bands);
  
  in = new AudioIn(this, 0);
  in.start();
  amp.input(in);
  waveform.input(in);
  fft.input(in);
  background(209);
}

void draw() {
  
  if (showInstruction) {
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(24);
    textLeading(36);
    text("Assistive Art Creation" + "\n" +
      "'1': Particles" + "\n" + "'2': Waveforms" + "\n" + "'9': All" + 
      "\n" + "'0': Pause"
      , width*0.5, height*0.5);
  }
  
  // Check this nice little trick:
  //translate(width/2, height/2);
  //scale(0.75);
  //rotate(radians(frameCount/50));
  ampt = amp.analyze();
  waveform.analyze();
  fft.analyze(spectrum);
  freq = max(spectrum);
  //println("amp:"+ampt);
  //println("freq:"+freq);
  //printArray(spectrum);

  keyPress();
  
  switch(drawMode) {
    case(NONE):
      break;
    case(PARTICLE):
      particle();
      break;
    case(WAVEFORM):
      waveform();
      break;
    case(ALL):
      particle();
      waveform();
      break;
  }
}  

void keyPress() {
  if (keyPressed == true) {
    if (key == 'r') {
      drawMode = NONE;
      setup();
    }
    switch(key) {
      case('0'): 
        if (showInstruction == true) {
          break;
        }
        drawMode = NONE;
        break;
      case('1'):
        if (showInstruction == true) {
          showInstruction = false;
          background(209);
        }
        drawMode = PARTICLE; 
        break;
      case('2'): 
        if (showInstruction == true) {
          showInstruction = false;
          background(209);
        }
        drawMode = WAVEFORM; 
        break;
      case('9'): 
        if (showInstruction == true) {
          showInstruction = false;
          background(209);
        }
        drawMode = ALL; 
        break;
    }
}
}

void waveform() {
  //translate(width/random(1,3), height/random(1,3));
  translate(random(width), random(height));
  rotate(random(1,360));
  noFill();
  float maxwf = max(waveform.data);
  if (maxwf > 0) {
    stroke(255, 125, 255-map(maxwf, 0, 1, 0, 255));
    strokeWeight(map(maxwf, 0, 1, 1, 3));
  }
  else if (maxwf < 0) {
    stroke(255, 125, 255-map(maxwf, 0, -1, 0, 255));
    strokeWeight(map(maxwf, 0, -1, 1, 3));
  }
  beginShape();
  for(int i = 0; i < bands; i++){
    if (abs(maxwf) < 0.3) {
      endShape();
    }
    vertex(
      map(i, 0, bands, width*0.4, width*0.6),
      map(waveform.data[i], -1, 1, height*0.47, height*0.53)
    );
  }
  endShape();
}

void particle() {
  if (ampt > 0.03) {
    Particle newP = new Particle(centerx, centery, random(10)+pts.size(), random(10)+pts.size());
    newP.loc.x = constrain(newP.loc.x, 100, width);
    newP.loc.y = constrain(newP.loc.y, 100, height);
    // If we RESET the values once they reached a certain limit, then we can restart the code
    if (newP.loc.x >= width) newP.loc.x = 0;
    if (newP.loc.y >= height) newP.loc.y = 0;

    pts.add(newP);

    for (int i=0; i<pts.size(); i++) {
      Particle p = pts.get(i);
      p.update();
      p.display();
    }

    for (int i=pts.size()-1; i>-1; i--) {
      Particle p = pts.get(i);
      if (p.dead) {
        centerx = pts.get(i).loc.x;
        centery = pts.get(i).loc.y;
        pts.remove(i);
      }
    }
  }
}

class Particle {
  PVector loc, vel, acc;
  int lifeSpan, passedLife;
  boolean dead;
  float alpha, weight, weightRange, decay, xOffset, yOffset;
  color c;
  int particleDirectionCos, particleDirectionSin;

  Particle(float x, float y, float xOffset, float yOffset) {
    loc = new PVector(x, y);

    float randDegrees = random(360);
    vel = new PVector(cos(radians(randDegrees)), sin(radians(randDegrees)));
    vel.mult(random(5));


    acc = new PVector(0, 0);
    lifeSpan = int(random(30, 90));
    decay = map(ampt, 0, 1, 0.75, 0.9);
    //red shades
    c = color(random(255), map(freq, 0, 0.9, 0, 255), map(freq, 0, 0.9, 0, 255));
    //green shades
    //c = color(map(freq, 0, 0.2, 0, 255), 255, map(freq, 0, 0.2, 0, 255));
    //blue shades
    //c = color(map(freq, 0, 0.2, 0, 255), map(freq, 0, 0.2, 0, 255), random(255));
    weightRange = map(ampt, 0, 1, 3, 50);

  
    this.xOffset = xOffset;
    this.yOffset = yOffset;
    
    this.particleDirectionCos = 1;
    if(random(2)>1)this.particleDirectionCos = -1;
    this.particleDirectionSin = 1;
    if(random(2)>1)this.particleDirectionSin = -1;
  }

  void update() {

    if (passedLife>=lifeSpan) {
      dead = true;
    } else {
      passedLife++;
    }

    weight = (float(lifeSpan-passedLife)/lifeSpan * weightRange)/2;


    acc.set(0, 0);

    /* Original Code 
     float rn = (noise((loc.x-frameCount-xOffset)*0.01, (loc.y-frameCount-yOffset)*0.01)-0.5)*4*PI;
     float mag = noise((loc.y+frameCount)*0.01, (loc.x+frameCount)*0.01);
     */
    // MODIFIED VERSION:
    // Not sure this has a big effect on the code
    float noisernX;
    if (random(2)>1) {
      noisernX = (loc.x-frameCount-xOffset)*0.01;
    } else {
      noisernX = (loc.x+frameCount+xOffset)*0.01;
    }
    float noisernY;
    if (random(2)>1) {
      noisernY = (loc.y-frameCount-yOffset)*0.01;
    } else {
      noisernY = (loc.y+frameCount+yOffset)*0.01;
    }
    float magY;
    if (random(2)>1) {
      magY = (loc.y-frameCount)*0.01;
    } else {
      magY = (loc.y+frameCount)*0.01;
    }
    float magX;
    if (random(2)>1) {
      magX = ((loc.x-frameCount)*0.01) * -1;
    } else {
      magX = (loc.x+frameCount)*0.01;
    }
    float addOrNot = 0.5;
    if (random(2)>1) addOrNot = -0.5;
    // Switches will affect direction:
    float rn = (noise(noisernX, noisernY)-addOrNot)*4*PI;
    float mag = noise(-magY, magX);


    PVector dir = new PVector(cos(rn)*particleDirectionCos, sin(rn)*particleDirectionSin);

    acc.add(dir);
    acc.mult(mag);

    float randDegrees = random(360);
    PVector randV = new PVector(cos(radians(randDegrees)), sin(radians(randDegrees)));
    randV.mult(0.5);
    acc.add(randV);

    vel.add(acc);
    vel.mult(decay);
    vel.limit(3);
    loc.add(vel);
  }

  void display() {
    //pushMatrix();
    //translate(-width/2, -height/2);
    strokeWeight(weight+1.5);
    //stroke(0, alpha);
    stroke(c);
    point(loc.x, loc.y);

    strokeWeight(weight);
    //stroke(c);
    stroke(c);
    point(loc.x, loc.y);
    //popMatrix();
  }
}
