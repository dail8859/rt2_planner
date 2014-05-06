G = 6.674e-11
TWO_PI = 2 * Math.PI
HALF_PI = 0.5 * Math.PI

(exports ? this).Bodies = {}

drawEllipse = (ctx, centerX, centerY, width, height) ->
  ctx.save()
  ctx.beginPath()
  ctx.scale(1, height/width)
  ctx.arc(0, 0, width, 0, 2 * Math.PI)
  ctx.closePath()
  ctx.restore()
  return

class CelestialBody
  constructor: (@mass, @radius, @siderealRotation, @color, @orbit, @atmPressure) ->
    @gravitationalParameter = G * @mass
    @sphereOfInfluence = @orbit.semiMajorAxis * Math.pow(@mass / @orbit.referenceBody.mass, 0.4) if @orbit?
    @atmPressure ?= 0
    @network = null
  
  circularOrbitVelocity: (altitude) ->
    Math.sqrt(@gravitationalParameter / (altitude + @radius))
  
  siderealTimeAt: (longitude, time) ->
    result = ((time / @siderealRotation) * TWO_PI + HALF_PI + longitude) % TWO_PI
    if result < 0 then result + TWO_PI else result
  
  name: -> return k for k, v of Bodies when v == this
  
  children: ->
    result = {}
    result[k] = v for k, v of Bodies when v?.orbit?.referenceBody == this
    result
  
  drawAtmosphere: (ctx) ->
    r = s(@radius)
    
    # Don't need to draw if view is zoomed out
    return if r < 10
    
    grd = ctx.createRadialGradient(0, 0, r, 0, 0, r * 1.1)
    grd.addColorStop(0, "rgba(135, 205, 250, 1.0)")
    grd.addColorStop(1, "rgba(135, 205, 250, 0.0)")
    
    ctx.fillStyle = grd
    
    ctx.beginPath()
    ctx.arc(0, 0, r * 1.1, 0, Math.PI * 2)
    ctx.fill()
    
    return
  
  drawBody: (ctx, time) ->
    # Main body
    r = Math.max(s(@radius), 3)
    ctx.beginPath()
    ctx.arc(0, 0, r, 0, 2 * Math.PI)
    ctx.fillStyle = @color
    ctx.strokeStyle = @color
    ctx.fill()
    ctx.stroke()
    
    # Rotational marker showing 0 longitude
    ctx.save()
    ctx.rotate(-@siderealTimeAt(0.0, time))
    ctx.beginPath()
    ctx.moveTo(0, 0)
    ctx.lineTo(r, 0)
    ctx.strokeStyle = "#FFFFFF"
    ctx.stroke()
    ctx.restore()
    
    return
  
  draw: (ctx, time) ->
    r = Math.max(s(@radius), 3)
    
    if @atmPressure > 0
      @drawAtmosphere(ctx)
    @network?.draw(ctx, time)
    @drawBody(ctx, time)
    
    # Name label
    ctx.fillStyle = "#FFFFFF"
    ctx.fillText(@name(),r, -r)
    
    for name, child of @children()
      ctx.strokeStyle = child.color
      ctx.fillStyle = child.color

      # argumentOfPeriapsis + longitudeOfAscendingNode = longitude of periapsis
      ctx.save()
      ctx.rotate(-(child.orbit.argumentOfPeriapsis + child.orbit.longitudeOfAscendingNode))

      # Draw the orbit
      ctx.save()
      ctx.translate(s(child.orbit.apoapsis() - child.orbit.semiMajorAxis), 0.0)
      drawEllipse(ctx, 0, 0, s(child.orbit.semiMajorAxis), s(child.orbit.semiMinorAxis()))
      ctx.stroke()
      
      # Debugging: Line from center of orbit (not body!) to apoapsis
      #ctx.beginPath()
      #ctx.moveTo(0,0)
      #ctx.lineTo(s(child.orbit.semiMajorAxis), 0)
      #ctx.stroke()
      
      ctx.restore()
      
      # Draw child on orbit at given time
      # TODO: handle child.siderealTimeAt()?
      ctx.save()
      ta = child.orbit.trueAnomalyAt(time)
      ctx.rotate(Math.PI - ta) # PI since ta is in reference to periapsis, subtract since we are viewing from "above", 
      ctx.translate(s(child.orbit.radiusAtTrueAnomaly(ta)), 0.0)
      
      ctx.beginPath()
      cr = Math.max(s(child.radius), 3)
      ctx.arc(0, 0, cr, 0, 2 * Math.PI)
      ctx.fill()
      
      # Name label
      # Rotate to keep the name level
      ctx.rotate(child.orbit.argumentOfPeriapsis + child.orbit.longitudeOfAscendingNode + Math.PI + ta)
      ctx.fillStyle = "#FFFFFF"
      ctx.fillText(child.name(), cr, -cr)
      ctx.restore()
      
      ctx.restore()
    
    return

# Ignore for now
#CelestialBody.fromJSON = (json) ->
#  orbit = Orbit.fromJSON(json.orbit) if json.orbit?
#  new CelestialBody(json.mass, json.radius, json.siderealRotation, orbit, json.atmPressure)

Bodies.Kerbol = new CelestialBody(1.756567e+28, 2.616e+08, 432000, "#FAE6BE", null)
Bodies.Moho = new CelestialBody(3.6747079e21, 250000, 1210000, "#695A50", new Orbit(Bodies.Kerbol, 5263138304, 0.2, 7.0, 70.0, 15.0, 3.14))
Bodies.Eve = new CelestialBody(1.2244127e23, 700000, 80500, "#503C5A", new Orbit(Bodies.Kerbol, 9832684544, 0.01, 2.1, 15.0, 0, 3.14), 5)
Bodies.Gilly = new CelestialBody(1.2420512e17, 13000, 28255, "#695A50", new Orbit(Bodies.Eve, 31500000, 0.55, 12.0, 80.0, 10.0, 0.9))
Bodies.Kerbin = new CelestialBody(5.2915793e22, 600000, 21600, "#1E283C", new Orbit(Bodies.Kerbol, 13599840256, 0.0, 0, 0, 0, 3.14), 1)
Bodies.Mun = new CelestialBody(9.7600236e20, 200000, 138984.38, "#7D7D7D", new Orbit(Bodies.Kerbin, 12000000, 0.0, 0, 0, 0, 1.7))
Bodies.Minmus = new CelestialBody(2.6457897e19, 60000, 40400, "#A0C8AA", new Orbit(Bodies.Kerbin, 47000000, 0.0, 6.0, 78.0, 38.0, 0.9))
Bodies.Duna = new CelestialBody(4.5154812e21, 320000, 65517.859, "#82281E", new Orbit(Bodies.Kerbol, 20726155264, 0.051, 0.06, 135.5, 0, 3.14), 0.2)
Bodies.Ike = new CelestialBody(2.7821949e20, 130000, 65517.862, "#414141", new Orbit(Bodies.Duna, 3200000, 0.03, 0.2, 0, 0, 1.7))
Bodies.Dres = new CelestialBody(3.2191322e20, 138000, 34800, "#878787", new Orbit(Bodies.Kerbol, 40839348203, 0.145, 5.0, 280.0, 90.0, 3.14))
Bodies.Jool = new CelestialBody(4.2332635e24, 6000000, 36000, "#326E28", new Orbit(Bodies.Kerbol, 68773560320, 0.05, 1.304, 52.0, 0, 0.1), 15)
Bodies.Laythe = new CelestialBody(2.9397663e22, 500000, 52980.879, "#2D323C", new Orbit(Bodies.Jool, 27184000, 0, 0, 0, 0, 3.14), 0.8)
Bodies.Vall = new CelestialBody(3.1088028e21, 300000, 105962.09, "#697D7D", new Orbit(Bodies.Jool, 43152000, 0, 0, 0, 0, 0.9))
Bodies.Tylo = new CelestialBody(4.2332635e22, 600000, 211926.36, "#BEB9AA", new Orbit(Bodies.Jool, 68500000, 0, 0.025, 0, 0, 3.14))
Bodies.Bop = new CelestialBody(3.7261536e19, 65000, 544507.4, "#4B3C37", new Orbit(Bodies.Jool, 128500000, 0.235, 15.0, 10.0, 25.0, 0.9))
Bodies.Pol = new CelestialBody(1.0813636e19, 44000, 901902.62, "#C3A078", new Orbit(Bodies.Jool, 179890000, 0.17085, 4.25, 2.0, 15.0, 0.9))
Bodies.Eeloo = new CelestialBody(1.1149358e21, 210000, 19460, "#C8D2D2", new Orbit(Bodies.Kerbol, 90118820000, 0.26, 6.15, 50.0, 260.0, 3.14))
