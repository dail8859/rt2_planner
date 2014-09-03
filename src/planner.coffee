FPS = 24
t = 0
zoomValue = 0.25
ctx = null
c = null

prev_time = Date.now()
warp_index = 0
warp_factor = [1, 5, 10, 50, 100, 1000, 10000, 100000]

# Default network to start with
root = Bodies.Kerbin
o = Orbit.fromApoapsisAndPeriapsis(root, root.radius + 100000, root.radius + 100000, 0.0, 0.0, 0.0, 0.0, 0.0)
root.network = new Network($('#networkSatellites').val(), o, root, Antennas[0])

# Clamps n between min and max
clamp = (n, min, max) -> Math.max(min, Math.min(n, max))

# Re-maps a number from one range to another
map = (val, x0, x1, y0, y1) ->
  y0 + (y1 - y0) * ((val - x0)/(x1 - x0))

# Scale a distance based on zoom value
(exports ? this).s = (x) ->
  a = root.radius / c.height * 4
  b = root.sphereOfInfluence / c.height * 2
  zoom = zoomValue * zoomValue * zoomValue
  meters_per_pixel = map(zoom, 0.0, 1.0, a, b)
  x / meters_per_pixel

#### Time ####
# From https://github.com/alexmoon/ksp

# Default to Kerbin time
hoursPerDay = 6
daysPerYear = 426
hms = (t) ->
  hours = (t / 3600) | 0
  t %= 3600
  mins = (t / 60) | 0
  secs = t % 60
  [hours, mins, secs]
ydhms = (t) ->
  [hours, mins, secs] = hms(+t)
  days = (hours / hoursPerDay) | 0
  hours = hours % hoursPerDay
  years = (days / daysPerYear) | 0
  days = days % daysPerYear
  [years, days, hours, mins, secs]
hmsString = (hour, min, sec) ->
  min = "0#{min}" if min < 10
  sec = "0#{sec}" if sec < 10
  "#{hour}:#{min}:#{sec}"
durationString = (t) ->
  [years, days, hours, mins, secs] = ydhms(t.toFixed())
  result = ""
  result += years + " years " if years > 0
  result += days + " days " if years > 0 or days > 0
  result + hmsString(hours, mins, secs)
##############

draw = ->
  setTimeout ( ->
    requestAnimationFrame(draw)
    
    ctx.save()
    ctx.fillStyle = "#000000"
    ctx.fillRect(0, 0, c.width, c.height)
    ctx.translate(c.width/2, c.height/2)
    root.draw(ctx, t)
    ctx.restore()
    
    # Update the current time including warp factor
    cur_time = Date.now()
    t = t + ((cur_time - prev_time) / 1000 * warp_factor[warp_index])
    prev_time = Date.now()
    
    ctx.fillStyle = "#FFFFFF"
    ctx.fillText(durationString(t), 10, c.height-10)
    return
  ), 1000 / FPS
  return

$(document).ready ->
  c = document.getElementById('myCanvas')
  ctx = c.getContext('2d')
  
  # Resize canvas to take up as much width has the div has allowed
  c.setAttribute('width', $("#canvasDiv").width())
  
  ctx.font = "12px Arial"
  
  $('#myCanvas').mousewheel (event) ->
    event.preventDefault()
    event.stopPropagation()
    
    # Cubic interpolation. Slow zooming when zoomed in, fast zooming when zoomed out
    zoomValue -= (event.deltaY * map(zoomValue*zoomValue, 0.0, 1.0, 0.04, 0.005))
    zoomValue = clamp(zoomValue, 0.0, 1.0)
    return
  
  $('#myCanvas').keypress (event) ->
    keyCode = event.keyCode || event.which
    switch keyCode
      #when 9
      #  event.preventDefault()
      #  event.stopPropagation()
      #  alert("tab " + event.shiftKey)
      #when 8
      #  event.preventDefault()
      #  event.stopPropagation()
      #  alert("backspace " + event.shiftKey)
      when 44
        event.preventDefault()
        event.stopPropagation()
        if warp_index != 0
          --warp_index
      when 46
        event.preventDefault()
        event.stopPropagation()
        if warp_index != warp_factor.length - 1
          ++warp_index
    return
  
  for name, body of Bodies
    if body == Bodies.Kerbol
      continue
    if body == root
      $("#originSelect")
        .append($('<option>', {value : name, selected : "selected"})
        .text(name))
    else
      $("#originSelect")
        .append($('<option>', {value : name})
        .text(name))
  
  $("#originSelect").change () ->
    # Move the network over to the new body
    prev = root
    root = Bodies[this.value]
    root.network = prev.network
    prev.network = null
    # Update references
    root.network.referenceBody = root
    root.network.orbit.referenceBody = root
    root.network.orbit.semiMajorAxis = root.radius + $('#orbitAltitude').val().trim() * 1000
  
  $("#orbitAltitude").on 'input', ->
    n = $('#orbitAltitude').val().trim()
    if !isNaN(parseFloat(n)) and isFinite(n)
      #root.network.orbit.setApoapsis(root.radius + n * 1000)
      root.network.orbit.semiMajorAxis = root.radius + n * 1000
    return
  
  $("#networkSatellites").on 'input', ->
    n = $('#networkSatellites').val().trim()
    if !isNaN(parseFloat(n)) and isFinite(n)
      root.network.n = n
    return
  
  for antenna, i in Antennas
    $("#antennaSelect")
      .append($('<option>', {value : i})
      .text(antenna.name))
  
  $("#antennaSelect").change () ->
    root.network.antenna = Antennas[this.value]
    return
  
  draw()
  
  return