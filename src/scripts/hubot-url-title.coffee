# Description:
#   Returns the title when a link is posted
#
# Dependencies:
#   "cheerio": "^0.19.0",
#   "underscore": "~1.3.3"
#   "request": "~2.30.0"
#   "iconv": "2.1.11"
#   "jschardet": "1.4.1"
#   "charset": "1.0.0"
#
# Configuration:
#   HUBOT_URL_TITLE_IGNORE_URLS - RegEx used to exclude Urls
#   HUBOT_URL_TITLE_IGNORE_USERS - Comma-separated list of users to ignore
#
# Commands:
#   http(s)://<site> - prints the title for site linked
#
# Author:
#   ajacksified, dentarg, impca

cheerio    = require 'cheerio'
_          = require 'underscore'
request    = require 'request'
charset    = require 'charset'
jschardet  = require 'jschardet'
Iconv      = require 'iconv'
httpAgent  = require 'socks5-http-client/lib/Agent'
httpsAgent = require 'socks5-https-client/lib/Agent'
utf8       = require 'utf8'

MAX_SIZE_DOWNLOADED_FILES = 1000000

module.exports = (robot) ->

  ignoredusers = []
  if process.env.HUBOT_URL_TITLE_IGNORE_USERS?
    ignoredusers = process.env.HUBOT_URL_TITLE_IGNORE_USERS.split(',')

  robot.hear /(http(?:s?):\/\/(\S*))/gi, (msg) ->
    for url in msg.match
      username = msg.message.user.name
      if _.some(ignoredusers, (user) -> user == username)
        console.log 'ignoring user due to blacklist:', username
        return

      # filter out some common files from trying
      ignore = url.match(/\.(png|jpg|jpeg|gif|txt|zip|tar\.bz|js|css|pdf)/)

      ignorePattern = process.env.HUBOT_URL_TITLE_IGNORE_URLS
      if !ignore && ignorePattern
        ignore = url.match(ignorePattern)

      unless ignore
        size = 0
        socksAgent = false
        socksAgentOptions = { socksHost: null, socksPort: null }
        process.env.NODE_TLS_REJECT_UNAUTHORIZED = "1"

        if process.env.HUBOT_URL_TITLE_SOCKS_HOST?
          socksAgentOptions['socksHost'] = process.env.HUBOT_URL_TITLE_SOCKS_HOST

        if process.env.HUBOT_URL_TITLE_SOCKS_PORT?
          socksAgentOptions['socksPort'] = process.env.HUBOT_URL_TITLE_SOCKS_PORT

        if process.env.HUBOT_URL_TITLE_USESOCKS?
          if url.match /http:\/\//
            socksAgent = httpAgent
          else
            socksAgent = httpsAgent

          if url.match /https:\/\/facebookcorewwwi\.onion/
            process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

        request (url: url, header: {encoding:null}, agentClass: socksAgent, agentOptions: socksAgentOptions), (error, response, body) ->
          console.log(error)
          if (!error && response.statusCode == 200)
            enc = charset(response.headers, body)
            enc = enc || jschardet.detect(body).encoding.toLowerCase()
            robot.logger.debug "webpage encoding is #{enc}"
            expandedurl = ""
            if (response.request.uri.href != url)
              expandedurl = " - " + response.request.uri.href
            if enc != 'utf-8'
              iconv = new Iconv.Iconv(enc, 'UTF-8//TRANSLIT//IGNORE')
              html = utf8.encode(body)
              document = cheerio.load(html)
              title = utf8.decode(document('head title').first().text().trim().replace(/\s+/g, " "))
              msg.send "#{title}#{expandedurl}"
            else
              document = cheerio.load(body)
              title = utf8.decode(document('head title').first().text().trim().replace(/\s+/g, " "))
              msg.send "#{title}#{expandedurl}"
        .on 'data', (chunk) ->
          size += chunk.length
          if size > MAX_SIZE_DOWNLOADED_FILES
            this.abort()
            msg.send "Resource at #{url} exceeds the maximum size."
