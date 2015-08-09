{ Point
, View
} = require 'atom'

request = require 'request'
cheerio = require 'cheerio'

path = require 'path'

module.exports =
    
    activate: (state) ->
      atom.commands.add 'atom-text-editor',
        'quick-docs:toggle': (event) =>
          @toggle()
    
      @messenger = null
      @messages = []

    deactivate: ->
      @messages.map (msg) -> msg.destroy()

    serialize: ->
      return "{}"

    consumeInlineMessenger: (messenger) ->
      console.log "Called"
      @messenger = messenger

    toggle: ->
        console.log 'QuickDocs was toggled!'
        editor = atom.workspace.getActiveTextEditor()
        editor.selectWordsContainingCursors()
        
        funx = editor.getSelectedText()
        range = editor.getSelectedBufferRange()

        if funx?.length
            console.log funx
            resp = @get_info(funx, range)
            
        else
            @messages.push @messenger.message
                range: range
                text: "Not a PHP function ?"
        
    get_info: (fun, range) ->

      resp = { search: fun, is_ok: false, title: '', desc: '', call: ''}
      resp.url = "http://php.net/manual/en/function.#{fun.replace /_/g, '-'}.php"

      r = request resp.url, (error, response, html) =>

        if error or response.statusCode is 404

          resp.desc = "Error: #{error}"

        else

          $ = cheerio.load(html);

          resp.title = $('h1').text()
          resp.call = $('.methodsynopsis.dc-description').text().replace(/\s\s+/g, "")
          resp.desc = $('.para.rdfs-comment').text().replace(/\s\s+/g, "");
          resp.response = response

          until resp?.call
            resp.call = $('.refname').text().replace(/\s\s+/g, "")

          until resp?.desc
            resp.desc = $('.dc-title').text().replace(/\s\s+/g, "")

          if resp.response.statusCode is 200
            resp.is_ok = true
            console.log resp.call
            console.log resp.desc
             
            @messages.push @messenger.message
                range: range
                text: resp.desc
                suggestion: resp.call

      return [r.call, r.desc]
