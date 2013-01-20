// Generated by CoffeeScript 1.4.0
var Couch, request;

request = require('request');

Couch = (function() {

  function Couch(hostname, db, design) {
    this.hostname = hostname;
    this.db = db;
    this.design = design;
  }

  Couch.prototype.view = function(options, callback) {
    var keystr;
    if (options.key != null) {
      keystr = 'key=%22' + options.key + '%22';
    } else {
      keystr = '';
    }
    return request({
      url: this.hostname + '/' + this.db + '/_design/' + this.design + '/_view/' + options.view + '?' + keystr,
      method: 'GET',
      json: true
    }, function(err, res, body) {
      if (!err) {
        if (body.error != null) {
          return callback(body);
        } else {
          return callback(null, body.rows);
        }
      } else {
        return callback('could not connect to database!');
      }
    });
  };

  Couch.prototype.doc = function(docid, callback) {
    return request({
      url: this.hostname + '/' + this.db + '/' + docid,
      method: 'GET',
      json: true
    }, function(err, res, body) {
      if (!err) {
        if (body.error != null) {
          return callback(body);
        } else {
          return callback(null, body);
        }
      } else {
        return callback('could not connect to database!');
      }
    });
  };

  Couch.prototype.saveDoc = function(doc, callback) {
    var id, reqmethod;
    if (doc._id != null) {
      reqmethod = 'PUT';
      id = doc._id;
    } else {
      reqmethod = 'POST';
      id = '';
    }
    return request({
      url: this.hostname + '/' + this.db + '/' + id,
      method: reqmethod,
      json: true,
      body: doc
    }, function(err, res, body) {
      if (!err) {
        if (body.error != null) {
          return callback(body);
        } else {
          return callback(null, body);
        }
      } else {
        return callback('could not connect to database!');
      }
    });
  };

  Couch.prototype.removeDoc = function(doc, callback) {
    if ((doc._id != null) && (doc._rev != null)) {
      return request({
        url: this.hostname + '/' + this.db + '/' + doc._id + '?rev=' + doc._rev,
        method: 'DELETE',
        json: true
      }, function(err, res, body) {
        if (!err) {
          if (body.error != null) {
            return callback(body);
          } else {
            return callback(null, body);
          }
        } else {
          return callback('could not connect to database!');
        }
      });
    }
  };

  return Couch;

})();

module.exports = Couch;
