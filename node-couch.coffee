#TODO rereduces ??
#TODO do the error callbacks really work??

request = require 'request'
mime = require 'mime'
http = require 'http'

parseParams = (params) ->
  i = 0
  paramString = ''
  for key, value of params
    if typeof(value) == 'string' and (key.localeCompare('key') == 0 or key.localeCompare('startkey') == 0 or key.localeCompare('endkey') == 0)
      squotes = '%22'
    else
      squotes = ''
    if i == 0
      delimiter = '?'
    else
      delimiter = '&'
    # TODO +=
    paramString = paramString + delimiter + key + '=' + squotes + value + squotes
    i++
  return paramString


class Couch
  constructor: (@hostname, @port, @db, @design) ->
    @dbroot = 'http://' + @hostname + ':' + @port + '/' + @db

  head: (docid, callback) ->
    request
      url: @dbroot + '/' + docid
      method: 'HEAD'
      (err, res, body) ->
        if !err
          console.log('HEAD:' + JSON.stringify(res.headers))
          callback null, res.headers

  view: (options, callback) ->
    if options.params?
      paramstr = parseParams(options.params)
    else paramstr = ''
    request 
      url: @dbroot + '/_design/' + @design + '/_view/' + options.view + paramstr
      method: 'GET'
      json: true, 
      (err, res, body) ->
        if !err
          if body.error?
            callback body
          else
            callback null, body.rows
        else
          callback 'could not connect to database - ' + err

  list: (options, callback) ->
    # TODO: list params take no surrounding "" for strings
    if options.params?
      paramstr = parseParams(options.params)
    else paramstr = ''
    request 
      url: @dbroot + '/_design/' + @design + '/_list/' + options.list + '/' + options.view + paramstr
      method: 'GET'
      json: true,
      (err, res, body) ->
        if !err
          if body.error?
            callback body
          else
            callback null, body
        else
          callback 'could not connect to database!'

  doc: (docid, callback) ->
    request
      url: @dbroot + '/' + docid
      method: 'GET'
      json: true,
      (err, res, body) ->
        if !err
          if body.error?
            callback body
          else
            callback null, body
        else
          callback 'could not connect to database!'

  saveDoc: (doc, callback) ->
    if doc._id?
      reqmethod = 'PUT'
      id = doc._id
    else
      reqmethod = 'POST'
      id = ''
    request
      url: @dbroot + '/' + id
      method: reqmethod
      json: true
      body: doc,
      (err, res, body) ->
        if !err
          if body.error?
            callback body
          else
            callback null, body
        else
          callback 'could not connect to database!'

  removeDoc: (doc, callback) ->
    if doc._id? && doc._rev?
      request
        url: @dbroot + '/' + doc._id + '?rev=' + doc._rev
        method: 'DELETE'
        json: true,
        (err, res, body) ->
          if !err
            if body.error?
              callback body
            else
              callback null, body
          else
            callback 'could not connect to database!'

  attachment: (docid, filename) ->
    attach = request
      method: 'GET'
      url: @dbroot + '/' + docid + '/' + filename
    return attach

  saveAttachment: (options, callback) ->
    #TODO: it's probably better to use the request module as well
    self = this
    doPutRequest = (docid, rev, fileStream, fileName, cb) ->
      putopts =
        hostname: self.hostname,
        port: parseInt(self.port)
        path: '/' + self.db + '/' + docid + '/' + fileName + '?rev=' + rev
        method: 'PUT'
        headers:
          'Content-Type': mime.lookup(fileName)
      putreq = http.request(putopts) # TODO: throw error if rev check fails
      fileStream.pipe(putreq)
      fileStream.on('end', () ->
        cb null, 'OK'
      )

    if options.rev?
      doPutRequest(options.docid, options.rev, options.fileStream, options.fileName, (err, msg) ->
        if !err
          callback null, msg
      )
    else
      #TODO: throw some errors if anything fails? how about that? could be easier by using request module
      options.fileStream.pause()
      headopts = 
        hostname: @hostname
        port: parseInt(@port)
        path: '/' + @db + '/' + options.docid
        method: 'HEAD'
      headreq = http.request(headopts, (headres) ->
        rev = headres.headers.etag.slice(1,headres.headers.etag.length-1)
        options.fileStream.resume()
        doPutRequest(options.docid, rev, options.fileStream, options.fileName, (err, msg) ->
          if !err
            callback null, msg
        )
      )
      headreq.end()


module.exports = Couch