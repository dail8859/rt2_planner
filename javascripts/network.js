// Generated by CoffeeScript 1.7.1
(function() {
  var Network, drawEllipse;

  drawEllipse = function(ctx, centerX, centerY, width, height) {
    ctx.save();
    ctx.beginPath();
    ctx.scale(1, height / width);
    ctx.arc(0, 0, width, 0, 2 * Math.PI);
    ctx.closePath();
    return ctx.restore();
  };

  (typeof exports !== "undefined" && exports !== null ? exports : this).Network = Network = (function() {
    function Network(n, orbit, referenceBody, antenna) {
      this.n = n;
      this.orbit = orbit;
      this.referenceBody = referenceBody;
      this.antenna = antenna;
      this.positionCache = [];
    }

    Network.prototype.updatePositions = function(time) {
      var i, period, pos, t, ta, _i, _ref;
      this.positionCache = [];
      period = this.orbit.period();
      for (i = _i = 1, _ref = this.n; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
        t = time + ((i - 1) * (period / this.n));
        ta = this.orbit.trueAnomalyAt(t);
        pos = {
          trueAnomaly: Math.PI - ta,
          altitude: this.orbit.radiusAtTrueAnomaly(ta)
        };
        this.positionCache.push(pos);
      }
    };

    Network.prototype.draw = function(ctx, time) {
      this.updatePositions(time);
      this.drawSatellites(ctx, time);
      this.drawConnections(ctx, time);
      this.drawElements(ctx, time);
    };

    Network.prototype.drawSatellites = function(ctx, time) {
      var pos, _i, _len, _ref;
      ctx.save();
      ctx.strokeStyle = "rgb(40, 130, 130)";
      ctx.rotate(-(this.orbit.argumentOfPeriapsis + this.orbit.longitudeOfAscendingNode));
      ctx.translate(s(this.orbit.apoapsis() - this.orbit.semiMajorAxis), 0.0);
      drawEllipse(ctx, 0, 0, s(this.orbit.semiMajorAxis), s(this.orbit.semiMinorAxis()));
      ctx.stroke();
      ctx.restore();
      ctx.fillStyle = "#FFFFFF";
      _ref = this.positionCache;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pos = _ref[_i];
        ctx.save();
        ctx.rotate(pos.trueAnomaly);
        ctx.translate(s(pos.altitude), 0.0);
        ctx.beginPath();
        ctx.arc(0, 0, 2, 0, 2 * Math.PI);
        ctx.fill();
        ctx.restore();
      }
    };

    Network.prototype.drawConnections = function(ctx) {
      var alpha, h, l, pos, r, _i, _len, _ref;
      alpha = (2 * Math.PI) / this.n;
      r = this.orbit.apoapsis();
      l = 2 * Math.sin(0.5 * alpha) * r;
      h = Math.cos(0.5 * alpha) * r;
      if (this.antenna.isOmni() && l < this.antenna.range) {
        ctx.save();
        ctx.lineWidth = 1.5;
        if (h < this.referenceBody.radius) {
          ctx.strokeStyle = "rgb(200, 0, 0)";
        } else {
          ctx.strokeStyle = "rgb(185, 255, 0)";
        }
        r = s(r);
        ctx.beginPath();
        pos = this.positionCache[0];
        ctx.save();
        ctx.rotate(pos.trueAnomaly);
        ctx.moveTo(s(pos.altitude), 0);
        ctx.restore();
        _ref = this.positionCache.slice(1);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pos = _ref[_i];
          ctx.save();
          ctx.rotate(pos.trueAnomaly);
          ctx.lineTo(s(pos.altitude), 0);
          ctx.restore();
        }
        pos = this.positionCache[0];
        ctx.save();
        ctx.rotate(pos.trueAnomaly);
        ctx.lineTo(s(pos.altitude), 0);
        ctx.restore();
        ctx.stroke();
      }
    };

    Network.prototype.drawElements = function(ctx) {
      var pos, _i, _len, _ref;
      ctx.strokeStyle = "#B4B4B4";
      _ref = this.positionCache;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pos = _ref[_i];
        ctx.save();
        ctx.rotate(pos.trueAnomaly);
        ctx.translate(s(pos.altitude), 0);
        this.antenna.drawRange(ctx);
        ctx.restore();
      }
    };

    return Network;

  })();

}).call(this);
