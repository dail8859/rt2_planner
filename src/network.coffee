drawEllipse = (ctx, centerX, centerY, width, height) ->
  ctx.save()
  ctx.beginPath()
  ctx.scale(1, height/width)
  ctx.arc(0, 0, width, 0, 2 * Math.PI)
  ctx.closePath()
  ctx.restore()

(exports ? this).Network = class Network
  constructor: (@n, @orbit, @referenceBody, @antenna) ->
    @positionCache = []
  
  updatePositions: (time) ->
    @positionCache = []
    period = @orbit.period()
    for i in [1..@n]
      # Offset part of the period so satellites are evenly spaced
      t = time + ((i - 1) * (period/@n))
      ta = @orbit.trueAnomalyAt(t)
      
      # PI since ta is in reference to periapsis, subtract since we are viewing from "above"
      pos = {trueAnomaly: Math.PI - ta, altitude: @orbit.radiusAtTrueAnomaly(ta)}
      
      @positionCache.push(pos)
    return
  
  draw: (ctx, time) ->
    @updatePositions(time)
    
    @drawSatellites(ctx, time)
    @drawConnections(ctx, time)
    @drawElements(ctx, time)
    return
  
  drawSatellites: (ctx, time) ->
    ctx.save()
    ctx.strokeStyle = "rgb(40, 130, 130)"
    ctx.rotate(-(@orbit.argumentOfPeriapsis + @orbit.longitudeOfAscendingNode))

    # Draw the orbit
    ctx.translate(s(@orbit.apoapsis() - @orbit.semiMajorAxis), 0.0)
    drawEllipse(ctx, 0, 0, s(@orbit.semiMajorAxis), s(@orbit.semiMinorAxis()))
    ctx.stroke()
    ctx.restore()
    
    ctx.fillStyle = "#FFFFFF"
    for pos in @positionCache
      ctx.save()
      ctx.rotate(pos.trueAnomaly) 
      ctx.translate(s(pos.altitude), 0.0)
      
      ctx.beginPath()
      ctx.arc(0, 0, 2, 0, 2 * Math.PI)
      ctx.fill()
      ctx.restore()
    
    return
  
  drawConnections: (ctx) ->
    # TODO: this currently only handles circular orbits
    alpha = (2 * Math.PI) / @n
    r = @orbit.apoapsis()
    l = 2 * Math.sin(0.5  * alpha) * r # distance between satellites
    h = Math.cos(0.5 * alpha) * r # closest point on the path to body
    
    if @antenna.isOmni() and l < @antenna.range
      ctx.save()
      ctx.lineWidth = 1.5
      
      if h < @referenceBody.radius # check line of sight
        ctx.strokeStyle = "rgb(200, 0, 0)" 
      else
        ctx.strokeStyle = "rgb(185, 255, 0)"
      
      r = s(r)
      
      ctx.beginPath()
      
      # Move to first satellite
      pos = @positionCache[0]
      ctx.save()
      ctx.rotate(pos.trueAnomaly)
      ctx.moveTo(s(pos.altitude), 0)
      ctx.restore()
      
      # Draw line to all the others
      for pos in @positionCache[1..]
        ctx.save()
        ctx.rotate(pos.trueAnomaly)
        ctx.lineTo(s(pos.altitude), 0)
        ctx.restore()
      
      # Draw connection to last satellite
      pos = @positionCache[0]
      ctx.save()
      ctx.rotate(pos.trueAnomaly)
      ctx.lineTo(s(pos.altitude), 0)
      ctx.restore()
      ctx.stroke()
    
    return
  
  drawElements: (ctx) ->
    ctx.strokeStyle = "#B4B4B4"
    
    for pos in @positionCache
      ctx.save()
      ctx.rotate(pos.trueAnomaly)
      #if drawCoverage coverageArea()
      #if drawRange
      ctx.translate(s(pos.altitude), 0)
      @antenna.drawRange(ctx)
      ctx.restore()
      #if !showAll break
    
    return
