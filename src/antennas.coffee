(exports ? this).Antennas = []

dashedArc = (ctx, radius, dash, start, stop) ->
  ctx.beginPath()
  for theta in [start..stop] by dash * 2
    ctx.moveTo(Math.cos(theta) * radius, Math.sin(theta) * radius)
    ctx.lineTo(Math.cos(theta + dash) * radius, Math.sin(theta + dash) * radius)
  return


class Antenna
  constructor: (@name, @range, @energy, @angle) ->
    @angle = @angle * (Math.PI/180) if angle? #convert to radians

  isOmni: ->
    not @isDish()

  isDish: ->
    @angle?

  drawRange: (ctx) ->
    ctx.save()
    ctx.strokeStyle = "#AAAAAA"
    if @isDish()
      # TODO: handle dishes eventually
      #dashedArc(ctx, s(range), radians(1.0), PI - cone_angle/2, PI + cone_angle/2)
      #ctx.beginPath()
      #ctx.moveTo(0, 0)
      #ctx.lineTo(42, 0)
      #ctx.rotate(@angle)
      #ctx.moveTo(0, 0)
      #ctx.lineTo(42, 0)
      #ctx.stroke()
    else
      dashedArc(ctx, s(@range), 0.1, 0, Math.PI * 2)
      ctx.stroke()
    ctx.restore()

Antennas.push(new Antenna(   "Reflectron DP-10", 500.0e3, 0.01))
Antennas.push(new Antenna(     "Communotron 16", 2.500e6, 0.13))
Antennas.push(new Antenna( "CommTech EXP-VR-2T",   3.0e6, 0.18))
Antennas.push(new Antenna(     "Communotron 32",   5.0e6, 0.60))
#Antennas.push(new Antenna(       "Comms DTS-M1",  50.0e6, 0.82, 45.0))
#Antennas.push(new Antenna(    "Reflectron KR-7",  90.0e6, 0.92, 25.0))
#Antennas.push(new Antenna(  "Communotron 88-88",  40.0e9, 0.93, 1.06))
#Antennas.push(new Antenna(   "Reflectron KR-14",  60.0e9, 0.93, 0.04))
#Antennas.push(new Antenna(         "Commtech 1", 350.0e9, 2.80, 0.006))
#Antennas.push(new Antenna(  "Reflectron GX-128", 400.0e9, 2.80, 0.005))