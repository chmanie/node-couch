expect = require('chai').expect

Couch = require '../build/node-couch'

settings =
  hostname: 'localhost'
  port: '5984'
  database: 'testdb'
  designDoc: 'test'
  testDoc: 'testdoc'
  view: 'all-docs'

db = new Couch(settings.hostname, settings.port, settings.database, settings.designDoc)

describe 'Connection to DB', ->
  it 'should say hello', (done) ->
    db.greet(
      (err, res) ->
        return done(err) if err
        expect(res.couchdb).to.exist
        expect(res.couchdb).to.equal('Welcome')
        done()
    )

describe 'List of databases', ->
  describe 'Length', ->
    it 'should not be zero', (done) ->
      db.listDBs(
        (err, res) ->
          return done(err) if err
          expect(res).to.be.a('array')
          expect(res).to.have.length.of.at.least(2)
          done()
      )

describe 'head method', ->
  it 'should get document headers', (done) ->
    db.head(settings.testDoc, 
      (err, res) ->
        return done(err) if err
        expect(res.server).to.exist
        expect(res.etag).to.exist
        done()
    )

describe 'view method', ->
  it 'should work with object as first argument', (done) ->
    viewOptions =
      view: settings.view
    db.view(viewOptions,
      (err, res) ->
        return done(err) if err
        expect(res).to.have.length.of.at.least(1)
        expect(res[0]).to.include.keys('value')
        done()
    )
  it 'should work with string as first argument', (done) ->
    view = settings.view
    db.view(view,
      (err, res) ->
        return done(err) if err
        expect(res).to.have.length.of.at.least(1)
        expect(res[0]).to.include.keys('value')
        done()
    )
  it 'should work with parameters', (done) ->
    viewOptions =
      view: settings.view
      params:
        startkey: 2
    db.view(viewOptions,
      (err, res) ->
        return done(err) if err
        expect(res).to.have.length.of(0)
        done()
    )
