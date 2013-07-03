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
    self = this

    doPutRequest = (docid, rev, fileStream, fileName, cb) ->
      dbFileStream = request
        method: 'PUT'
        url: self.dbroot + '/' + docid + '/' + fileName + '?rev=' + rev
        headers:
          'Content-Type': mime.lookup(fileName)
      , (err, res, body) ->
        cb(null, JSON.parse(body))

      fileStream.pipe(dbFileStream)

    if options.rev?
      doPutRequest(options.docid, options.rev, options.fileStream, options.fileName, (err, data) ->
        if !err
          callback(null, data)
        else
          callback(err)
      )
    else
      options.fileStream.pause()
      request.head(@dbroot + '/' + options.docid, (err, res, body) ->
        rev = res.headers.etag.slice(1,res.headers.etag.length-1)
        options.fileStream.resume()
        doPutRequest(options.docid, rev, options.fileStream, options.fileName, (err, data) ->
          if !err
            callback(null, data)
          else
            callback(err)
        )
      )

module.exports = Couch