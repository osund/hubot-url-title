Helper = require('hubot-test-helper')
helper = new Helper('./../scripts/hubot-url-title.coffee')

Promise = require('bluebird')
co = require('co')
expect = require('chai').expect

describe 'hubot-url-title', ->
  this.timeout(22000)

  beforeEach ->
    @room = helper.createRoom(httpd: false)

  context "user posts link to youtube video", ->
    beforeEach ->
      co =>
        yield @room.user.say 'john', "https://www.youtube.com/watch?v=u-mRU44Q5u4"
        yield new Promise.delay(1000)

    it 'posts the title of the video', ->
      expect(@room.messages).to.eql [
        ['john', "https://www.youtube.com/watch?v=u-mRU44Q5u4"]
        ['hubot', "AWS re:Invent 2015 | (SEC316) Harden Your Architecture w/ Security Incident Response Simulations - YouTube"]
      ]

  context "user posts link to GitHub", ->
    beforeEach ->
      co =>
        yield @room.user.say 'john', "https://github.com"
        yield new Promise.delay(1000)

    it 'posts the title of the video', ->
      expect(@room.messages).to.eql [
        ['john', "https://github.com"]
        ['hubot', "GitHub · Where software is built"]
      ]

  context "user posts 2 links", ->
    beforeEach ->
      co =>
        yield @room.user.say 'john', "https://www.youtube.com/watch?v=u-mRU44Q5u4 https://github.com"
        yield new Promise.delay(2000)

    it 'posts the title of the video', ->
      expect(@room.messages[0]).to.eql ['john', "https://www.youtube.com/watch?v=u-mRU44Q5u4 https://github.com"]
      titles = [
        "AWS re:Invent 2015 | (SEC316) Harden Your Architecture w/ Security Incident Response Simulations - YouTube"
        "GitHub · Where software is built"
      ]
      expect(@room.messages[1][1]).to.be.oneOf titles
      expect(@room.messages[2][1]).to.be.oneOf titles

  context "user posts link to large ISO file", ->
    beforeEach ->
      co =>
        yield @room.user.say 'john', "http://cdimage.debian.org/debian-cd/8.3.0/amd64/iso-cd/debian-8.3.0-amd64-CD-1.iso"
        yield new Promise.delay(20000)

    it 'stops download because it exceeds the maximum size', ->
      expect(@room.messages).to.eql [
        ['john', "http://cdimage.debian.org/debian-cd/8.3.0/amd64/iso-cd/debian-8.3.0-amd64-CD-1.iso"]
        ['hubot', "Resource at http://cdimage.debian.org/debian-cd/8.3.0/amd64/iso-cd/debian-8.3.0-amd64-CD-1.iso exceeds the maximum size."]
      ]
