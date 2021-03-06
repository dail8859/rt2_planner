// Generated by CoffeeScript 1.8.0
(function() {
  var FPS, c, clamp, ctx, daysPerYear, distanceString, draw, durationString, grd, hms, hmsString, hoursPerDay, map, measureEnd, measureStart, measuring, metersPerPixel, numberWithCommas, o, prev_time, root, t, warp_factor, warp_index, ydhms, zoomValue;

  FPS = 24;

  t = 0;

  zoomValue = 0.25;

  ctx = null;

  c = null;

  grd = null;

  prev_time = Date.now();

  warp_index = 0;

  warp_factor = [1, 5, 10, 50, 100, 1000, 10000, 100000];

  $('#orbitApoapsis').val(100);

  $('#orbitPeriapsis').val(100);

  $("#networkSatellites").val(6);

  root = Bodies.Kerbin;

  o = Orbit.fromApoapsisAndPeriapsis(root, root.radius + 100000, root.radius + 100000, 0.0, 0.0, 0.0, 0.0, 0.0);

  root.network = new Network($('#networkSatellites').val(), o, root, Antennas[0]);

  clamp = function(n, min, max) {
    return Math.max(min, Math.min(n, max));
  };

  map = function(val, x0, x1, y0, y1) {
    return y0 + (y1 - y0) * ((val - x0) / (x1 - x0));
  };

  metersPerPixel = function() {
    var a, b, zoom;
    a = root.radius / c.height * 4;
    b = root.sphereOfInfluence / c.height * 2;
    zoom = zoomValue * zoomValue * zoomValue;
    return map(zoom, 0.0, 1.0, a, b);
  };

  (typeof exports !== "undefined" && exports !== null ? exports : this).s = function(x) {
    return x / metersPerPixel();
  };

  numberWithCommas = function(n) {
    return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  };

  distanceString = function(d) {
    if (Math.abs(d) > 1e12) {
      return numberWithCommas((d / 1e9).toFixed()) + " Gm";
    } else if (Math.abs(d) >= 1e9) {
      return numberWithCommas((d / 1e6).toFixed()) + " Mm";
    } else if (Math.abs(d) >= 1e6) {
      return numberWithCommas((d / 1e3).toFixed()) + " km";
    } else {
      return numberWithCommas(d.toFixed()) + " m";
    }
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
    result += "Y" + (years + 1) + ", ";
    result += "D" + (days + 1) + ", ";
    return result + hmsString(hours, mins, secs);
  };

  draw = function() {
    setTimeout((function() {
      var cur_time, distance, i, w, x, _i, _len;
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
      ctx.fillStyle = grd;
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(120, 0);
      ctx.lineTo(120, 20);
      ctx.lineTo(110, 40);
      ctx.lineTo(0, 40);
      ctx.fill();
      ctx.fillStyle = "lime";
      for (i = _i = 0, _len = warp_factor.length; _i < _len; i = ++_i) {
        w = warp_factor[i];
        x = 10 + i * 12 + i;
        ctx.beginPath();
        ctx.moveTo(x, 4);
        ctx.lineTo(x, 16);
        ctx.lineTo(x + 12, 10);
        ctx.fill();
        if (i === warp_index) {
          ctx.fillStyle = "black";
        }
      }
      ctx.fillStyle = "lime";
      ctx.fillText(durationString(t), 10, 34);
      if (measuring) {
        ctx.strokeStyle = "lime";
        ctx.beginPath();
        ctx.moveTo(measureStart[0], measureStart[1]);
        ctx.lineTo(measureEnd[0], measureEnd[1]);
        ctx.stroke();
        distance = Math.sqrt(Math.pow(measureStart[0] - measureEnd[0], 2) + Math.pow(measureStart[1] - measureEnd[1], 2)) * metersPerPixel();
        ctx.fillText(distanceString(distance), 10, c.height - 10);
      }
    }), 1000 / FPS);
  };

  measureStart = [0, 0];

  measureEnd = [0, 0];

  measuring = false;

  $(document).ready(function() {
    var antenna, body, i, name, _i, _len;
    c = document.getElementById('myCanvas');
    ctx = c.getContext('2d');
    c.setAttribute('width', $("#canvasDiv").width());
    ctx.font = "12px Arial";
    grd = ctx.createLinearGradient(0, 0, 0, 40);
    grd.addColorStop(0.0, "#8A939C");
    grd.addColorStop(0.45, "#8A939C");
    grd.addColorStop(0.55, "#4C555E");
    grd.addColorStop(1.0, "#4C555E");
    $('#myCanvas').mousewheel(function(event) {
      event.preventDefault();
      event.stopPropagation();
      zoomValue -= event.deltaY * map(zoomValue * zoomValue, 0.0, 1.0, 0.04, 0.005);
      zoomValue = clamp(zoomValue, 0.0, 1.0);
    });
    $('#myCanvas').mousedown(function(event) {
      measureStart = [event.pageX - $(this).offset().left, event.pageY - $(this).offset().top];
      if (measureStart[0] < 120 && measureStart[1] < 20) {
        warp_index = Math.min(Math.floor(Math.max(0, measureStart[0] - 10) / 13), warp_factor.length - 1);
      } else {
        measureEnd = measureStart;
        measuring = true;
      }
    });
    $('#myCanvas').mousemove(function(event) {
      if (measuring) {
        measureEnd = [event.pageX - $(this).offset().left, event.pageY - $(this).offset().top];
      }
    });
    $('#myCanvas').mouseup(function(event) {
      measuring = false;
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
      $('#orbitApoapsis').val(100);
      $('#orbitPeriapsis').val(100);
      root.network.orbit.setApoapsis(root.radius + 100000);
      return root.network.orbit.setPeriapsis(root.radius + 100000);
    });
    $("#orbitApoapsis").on('input', function() {
      var n;
      $("#orbitApoapsis").closest('.form-group').removeClass('has-error').find('.help-block').text('');
      n = $('#orbitApoapsis').val().trim();
      if (isNaN(parseFloat(n)) || !isFinite(n)) {
        $("#orbitApoapsis").closest('.form-group').addClass('has-error').find('.help-block').text('A valid number is required.');
        return;
      }
      if (n * 1000 < root.network.orbit.periapsisAltitude()) {
        $("#orbitApoapsis").closest('.form-group').addClass('has-error').find('.help-block').text('Apoapsis must be greater than or equal to periapsis.');
        return;
      }
      root.network.orbit.setApoapsis(root.radius + n * 1000);
    });
    $("#orbitPeriapsis").on('input', function() {
      var n;
      $("#orbitPeriapsis").closest('.form-group').removeClass('has-error').find('.help-block').text('');
      n = $('#orbitPeriapsis').val().trim();
      if (isNaN(parseFloat(n)) || !isFinite(n)) {
        $("#orbitPeriapsis").closest('.form-group').addClass('has-error').find('.help-block').text('A valid number is required.');
        return;
      }
      if (n * 1000 > root.network.orbit.apoapsisAltitude()) {
        $("#orbitPeriapsis").closest('.form-group').addClass('has-error').find('.help-block').text('Periapsis must be less than or equal to apoapsis.');
        return;
      }
      root.network.orbit.setPeriapsis(root.radius + n * 1000);
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
