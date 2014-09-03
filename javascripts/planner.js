// Generated by CoffeeScript 1.8.0
(function() {
  var FPS, c, clamp, ctx, daysPerYear, draw, durationString, hms, hmsString, hoursPerDay, map, o, prev_time, root, t, warp_factor, warp_index, ydhms, zoomValue;

  FPS = 24;

  t = 0;

  zoomValue = 0.25;

  ctx = null;

  c = null;

  prev_time = Date.now();

  warp_index = 0;

  warp_factor = [1, 5, 10, 50, 100, 1000, 10000, 100000];

  root = Bodies.Kerbin;

  o = Orbit.fromApoapsisAndPeriapsis(root, root.radius + 100000, root.radius + 100000, 0.0, 0.0, 0.0, 0.0, 0.0);

  root.network = new Network($('#networkSatellites').val(), o, root, Antennas[0]);

  clamp = function(n, min, max) {
    return Math.max(min, Math.min(n, max));
  };

  map = function(val, x0, x1, y0, y1) {
    return y0 + (y1 - y0) * ((val - x0) / (x1 - x0));
  };

  (typeof exports !== "undefined" && exports !== null ? exports : this).s = function(x) {
    var a, b, meters_per_pixel, zoom;
    a = root.radius / c.height * 4;
    b = root.sphereOfInfluence / c.height * 2;
    zoom = zoomValue * zoomValue * zoomValue;
    meters_per_pixel = map(zoom, 0.0, 1.0, a, b);
    return x / meters_per_pixel;
  };

  hoursPerDay = 6;

  daysPerYear = 426;

  hms = function(t) {
    var hours, mins, secs;
    hours = (t / 3600) | 0;
    t %= 3600;
    mins = (t / 60) | 0;
    secs = t % 60;
    return [hours, mins, secs];
  };

  ydhms = function(t) {
    var days, hours, mins, secs, years, _ref;
    _ref = hms(+t), hours = _ref[0], mins = _ref[1], secs = _ref[2];
    days = (hours / hoursPerDay) | 0;
    hours = hours % hoursPerDay;
    years = (days / daysPerYear) | 0;
    days = days % daysPerYear;
    return [years, days, hours, mins, secs];
  };

  hmsString = function(hour, min, sec) {
    if (min < 10) {
      min = "0" + min;
    }
    if (sec < 10) {
      sec = "0" + sec;
    }
    return "" + hour + ":" + min + ":" + sec;
  };

  durationString = function(t) {
    var days, hours, mins, result, secs, years, _ref;
    _ref = ydhms(t.toFixed()), years = _ref[0], days = _ref[1], hours = _ref[2], mins = _ref[3], secs = _ref[4];
    result = "";
    if (years > 0) {
      result += years + " years ";
    }
    if (years > 0 || days > 0) {
      result += days + " days ";
    }
    return result + hmsString(hours, mins, secs);
  };

  draw = function() {
    setTimeout((function() {
      var cur_time;
      requestAnimationFrame(draw);
      ctx.save();
      ctx.fillStyle = "#000000";
      ctx.fillRect(0, 0, c.width, c.height);
      ctx.translate(c.width / 2, c.height / 2);
      root.draw(ctx, t);
      ctx.restore();
      cur_time = Date.now();
      t = t + ((cur_time - prev_time) / 1000 * warp_factor[warp_index]);
      prev_time = Date.now();
      ctx.fillStyle = "#FFFFFF";
      ctx.fillText(durationString(t), 10, c.height - 10);
    }), 1000 / FPS);
  };

  $(document).ready(function() {
    var antenna, body, i, name, _i, _len;
    c = document.getElementById('myCanvas');
    ctx = c.getContext('2d');
    c.setAttribute('width', $("#canvasDiv").width());
    ctx.font = "12px Arial";
    $('#myCanvas').mousewheel(function(event) {
      event.preventDefault();
      event.stopPropagation();
      zoomValue -= event.deltaY * map(zoomValue * zoomValue, 0.0, 1.0, 0.04, 0.005);
      zoomValue = clamp(zoomValue, 0.0, 1.0);
    });
    $('#myCanvas').keypress(function(event) {
      var keyCode;
      keyCode = event.keyCode || event.which;
      switch (keyCode) {
        case 44:
          event.preventDefault();
          event.stopPropagation();
          if (warp_index !== 0) {
            --warp_index;
          }
          break;
        case 46:
          event.preventDefault();
          event.stopPropagation();
          if (warp_index !== warp_factor.length - 1) {
            ++warp_index;
          }
      }
    });
    for (name in Bodies) {
      body = Bodies[name];
      if (body === Bodies.Kerbol) {
        continue;
      }
      if (body === root) {
        $("#originSelect").append($('<option>', {
          value: name,
          selected: "selected"
        }).text(name));
      } else {
        $("#originSelect").append($('<option>', {
          value: name
        }).text(name));
      }
    }
    $("#originSelect").change(function() {
      var prev;
      prev = root;
      root = Bodies[this.value];
      root.network = prev.network;
      prev.network = null;
      root.network.referenceBody = root;
      root.network.orbit.referenceBody = root;
      return root.network.orbit.semiMajorAxis = root.radius + $('#orbitAltitude').val().trim() * 1000;
    });
    $("#orbitAltitude").on('input', function() {
      var n;
      n = $('#orbitAltitude').val().trim();
      if (!isNaN(parseFloat(n)) && isFinite(n)) {
        root.network.orbit.semiMajorAxis = root.radius + n * 1000;
      }
    });
    $("#networkSatellites").on('input', function() {
      var n;
      n = $('#networkSatellites').val().trim();
      if (!isNaN(parseFloat(n)) && isFinite(n)) {
        root.network.n = n;
      }
    });
    for (i = _i = 0, _len = Antennas.length; _i < _len; i = ++_i) {
      antenna = Antennas[i];
      $("#antennaSelect").append($('<option>', {
        value: i
      }).text(antenna.name));
    }
    $("#antennaSelect").change(function() {
      root.network.antenna = Antennas[this.value];
    });
    draw();
  });

}).call(this);
