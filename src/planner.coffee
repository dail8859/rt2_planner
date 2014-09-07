FPS = 24
t = 0
zoomValue = 0.25
ctx = null
c = null
grd = null

prev_time = Date.now()
warp_index = 0
warp_factor = [1, 5, 10, 50, 100, 1000, 10000, 100000]

# Default network to start with
$('#orbitApoapsis').val(100)
$('#orbitPeriapsis').val(100)
$("#networkSatellites").val(6)
root = Bodies.Kerbin
o = Orbit.fromApoapsisAndPeriapsis(root, root.radius + 100000, root.radius + 100000, 0.0, 0.0, 0.0, 0.0, 0.0)
root.network = new Network($('#networkSatellites').val(), o, root, Antennas[0])

# Clamps n between min and max
clamp = (n, min, max) -> Math.max(min, Math.min(n, max))

# Re-maps a number from one range to another
map = (val, x0, x1, y0, y1) ->
  y0 + (y1 - y0) * ((val - x0)/(x1 - x0))

metersPerPixel = () ->
  a = root.radius / c.height * 4
  b = root.sphereOfInfluence / c.height * 2
  zoom = zoomValue * zoomValue * zoomValue
  map(zoom, 0.0, 1.0, a, b)

# Scale a distance based on zoom value
(exports ? this).s = (x) ->
  x / metersPerPixel()

# From https://github.com/alexmoon/ksp
numberWithCommas = (n) ->
  n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')
distanceString = (d) ->
  if Math.abs(d) > 1e12
    numberWithCommas((d / 1e9).toFixed()) + " Gm"
  else if Math.abs(d) >= 1e9
    numberWithCommas((d / 1e6).toFixed()) + " Mm"
  else if Math.abs(d) >= 1e6
    numberWithCommas((d / 1e3).toFixed()) + " km"
  else
    numberWithCommas(d.toFixed()) + " m"
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
  result += "Y" + (years + 1) + ", "
  result += "D" + (days + 1) + ", "
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
    
    # Top left box
    ctx.fillStyle = grd
    ctx.beginPath()
    ctx.moveTo(0, 0)
    ctx.lineTo(120, 0)
    ctx.lineTo(120, 20)
    ctx.lineTo(110, 40)
    ctx.lineTo(0, 40)
    ctx.fill()
    
    # Timewarp arrows
    ctx.fillStyle = "lime"
    for w, i in warp_factor
      x = 10 + i * 12 + i
      ctx.beginPath()
      ctx.moveTo(x, 4)
      ctx.lineTo(x, 16)
      ctx.lineTo(x + 12, 10)
      ctx.fill()
      if i == warp_index
        ctx.fillStyle = "black"
    
    # Time
    ctx.fillStyle = "lime"
    ctx.fillText(durationString(t), 10, 34)
    
    if measuring
      ctx.strokeStyle = "lime"
      ctx.beginPath()
      ctx.moveTo(measureStart[0], measureStart[1])
      ctx.lineTo(measureEnd[0], measureEnd[1])
      ctx.stroke()
      distance = Math.sqrt(Math.pow(measureStart[0] - measureEnd[0], 2) + Math.pow(measureStart[1] - measureEnd[1], 2)) * metersPerPixel()
      ctx.fillText(distanceString(distance), 10, c.height - 10)
    return
  ), 1000 / FPS
  return

measureStart = [0, 0]
measureEnd = [0, 0]
measuring = false
$(document).ready ->
  c = document.getElementById('myCanvas')
  ctx = c.getContext('2d')
  
  # Resize canvas to take up as much width has the div has allowed
  c.setAttribute('width', $("#canvasDiv").width())
  
  ctx.font = "12px Arial"
  
  # Gradient for top left menu
  grd=ctx.createLinearGradient(0, 0, 0, 40);
  grd.addColorStop(0.0, "#8A939C");
  grd.addColorStop(0.45, "#8A939C");
  grd.addColorStop(0.55, "#4C555E");
  grd.addColorStop(1.0, "#4C555E");
  
  $('#myCanvas').mousewheel (event) ->
    event.preventDefault()
    event.stopPropagation()
    
    # Cubic interpolation. Slow zooming when zoomed in, fast zooming when zoomed out
    zoomValue -= (event.deltaY * map(zoomValue*zoomValue, 0.0, 1.0, 0.04, 0.005))
    zoomValue = clamp(zoomValue, 0.0, 1.0)
    return
  
  $('#myCanvas').mousedown (event) ->
    measureStart = [event.pageX - $(this).offset().left, event.pageY - $(this).offset().top]
    
    # See if the click was on the warp menu or click+drag to measure
    if measureStart[0] < 120 and measureStart[1] < 20
      warp_index = Math.min(Math.floor(Math.max(0, measureStart[0] - 10) / 13), warp_factor.length - 1)
    else
      measureEnd = measureStart
      measuring = true
    return
  
  $('#myCanvas').mousemove (event) ->
    if measuring
      measureEnd = [event.pageX - $(this).offset().left, event.pageY - $(this).offset().top]
    return
  
  $('#myCanvas').mouseup (event) ->
    measuring = false
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
    $('#orbitApoapsis').val(100)
    $('#orbitPeriapsis').val(100)
    root.network.orbit.setApoapsis(root.radius + 100000)
    root.network.orbit.setPeriapsis(root.radius + 100000)
  
  $("#orbitApoapsis").on 'input', ->
    $("#orbitApoapsis").closest('.form-group').removeClass('has-error').find('.help-block').text('')
    
    n = $('#orbitApoapsis').val().trim()
    if isNaN(parseFloat(n)) or !isFinite(n)
      $("#orbitApoapsis").closest('.form-group').addClass('has-error').find('.help-block').text('A valid number is required.')
      return
    if n * 1000 < root.network.orbit.periapsisAltitude()
      $("#orbitApoapsis").closest('.form-group').addClass('has-error').find('.help-block').text('Apoapsis must be greater than or equal to periapsis.')
      return
    root.network.orbit.setApoapsis(root.radius + n * 1000)
    
    return
  
  $("#orbitPeriapsis").on 'input', ->
    $("#orbitPeriapsis").closest('.form-group').removeClass('has-error').find('.help-block').text('')
    
    n = $('#orbitPeriapsis').val().trim()
    if isNaN(parseFloat(n)) or !isFinite(n)
      $("#orbitPeriapsis").closest('.form-group').addClass('has-error').find('.help-block').text('A valid number is required.')
      return
    if n * 1000 > root.network.orbit.apoapsisAltitude()
      $("#orbitPeriapsis").closest('.form-group').addClass('has-error').find('.help-block').text('Periapsis must be less than or equal to apoapsis.')
      return
    root.network.orbit.setPeriapsis(root.radius + n * 1000)
    
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