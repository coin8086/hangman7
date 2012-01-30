"use strict"

function Set(s) {
  this._data = {};
  this._size = 0;

  if (s) {
    if (s instanceof Set)
      s = Object.keys(s._data);
    else if (!Array.isArray(s))
      s = Object.keys(s);

    s.forEach(function (e) {
      this._data[e] = true;
    }, this);
    this.size = s.length
  }
}

Set.prototype.size = function() {
  return this._size;
}

Set.prototype.contains = function(e) {
  return this._data[e];
}

Set.prototype.add = function(e) {
  var v = this._data[e];
  if (v) {
    return false;
  }
  else {
    this._data[e] = true;
    this._size++;
    return true;
  }
}

Set.prototype.addAll = function(s) {
  if (s instanceof Set)
    s = Object.keys(s._data);
  else if (!Array.isArray(s))
    s = Object.keys(s);

  s.forEach(function (e) {
    if (!this._data[e]) {
      this._data[e] = true;
      this._size++;
    }
  }, this);
  return this;
}

Set.prototype.forEach = function(f, o) {
  Object.keys(this._data).forEach(function (e) {
    f.call(o, e);
  });
}

exports.Set = Set;
