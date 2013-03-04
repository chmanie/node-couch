// Generated by CoffeeScript 1.4.0
var Couch, http, mime, parseParams, request;

request = require('request');

mime = require('mime');

http = require('http');

parseParams = function(params) {
  var delimiter, i, key, paramString, squotes, value;
  i = 0;
  paramString = '';
  for (key in params) {
    value = params[key];
    if (typeof value === 'string' && (key.localeCompare('key') === 0 || key.localeCompare('startkey') === 0 || key.localeCompare('endkey') === 0)) {
      squotes = '%22';
    } else {
      squotes = '';
    }
    if (i === 0) {
      delimiter = '?';
    } else {
      delimiter = '&';
    }
    paramString = paramString + delimiter + key + '=' + squotes + value + squotes;
    i++;
  }
  return paramString;
};

Couch = (function() {

  function Couch(hostname, port, db, design) {
    this.hostname = hostname;
    this.port = port;
    this.db = db;
    this.design = design;
    this.dbroot = 'http://' + this.hostname + ':' + this.port + '/' + this.db;
  }

  Couch.prototype.head = function(docid, callback) {
    return request({
      url: this.dbroot + '/' + docid,
      method: 'HEAD'
    }, function(err, res, body) {
      if (!err) {
        console.log('HEAD:' + JSON.stringify(res.headers));
        return callback(null, res.headers);
      }
    });
  };

  Couch.prototype.view = function(options, callback) {
    var paramstr;
    if (options.params != null) {
      paramstr = parseParams(options.params);
    } else {
      paramstr = '';
    }
    return request({
      url: this.dbroot + '/_design/' + this.design + '/_view/' + options.view + paramstr,
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
        return callback('could not connect to database - ' + err);
      }
    });
  };

  Couch.prototype.list = function(options, callback) {
    var paramstr;
    if (options.params != null) {
      paramstr = parseParams(options.params);
    } else {
      paramstr = '';
    }
    return request({
      url: this.dbroot + '/_design/' + this.design + '/_list/' + options.list + '/' + options.view + paramstr,
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

  Couch.prototype.doc = function(docid, callback) {
    return request({
      url: this.dbroot + '/' + docid,
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
      url: this.dbroot + '/' + id,
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
        url: this.dbroot + '/' + doc._id + '?rev=' + doc._rev,
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

  Couch.prototype.attachment = function(docid, filename) {
    var attach;
    attach = request({
      method: 'GET',
      url: this.dbroot + '/' + docid + '/' + filename
    });
    return attach;
  };

  Couch.prototype.saveAttachment = function(options, callback) {
    var doPutRequest, headopts, headreq, self;
    self = this;
    doPutRequest = function(docid, rev, fileStream, fileName, cb) {
      var putopts, putreq;
      putopts = {
        hostname: self.hostname,
        port: parseInt(self.port),
        path: '/' + self.db + '/' + docid + '/' + fileName + '?rev=' + rev,
        method: 'PUT',
        headers: {
          'Content-Type': mime.lookup(fileName)
        }
      };
      putreq = http.request(putopts);
      fileStream.pipe(putreq);
      return fileStream.on('end', function() {
        return cb(null, 'OK');
      });
    };
    if (options.rev != null) {
      return doPutRequest(options.docid, options.rev, options.fileStream, options.fileName, function(err, msg) {
        if (!err) {
          return callback(null, msg);
        }
      });
    } else {
      options.fileStream.pause();
      headopts = {
        hostname: this.hostname,
        port: parseInt(this.port),
        path: '/' + this.db + '/' + options.docid,
        method: 'HEAD'
      };
      headreq = http.request(headopts, function(headres) {
        var rev;
        rev = headres.headers.etag.slice(1, headres.headers.etag.length - 1);
        options.fileStream.resume();
        return doPutRequest(options.docid, rev, options.fileStream, options.fileName, function(err, msg) {
          if (!err) {
            return callback(null, msg);
          }
        });
      });
      return headreq.end();
    }
  };

  return Couch;

})();

module.exports = Couch;
