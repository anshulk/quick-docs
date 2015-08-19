{ Point
, View
} = require 'atom'

module.exports =
    
    activate: (state) ->
      atom.commands.add 'atom-text-editor',
        'quick-docs:toggle': (event) =>
          @toggle()
    
      @messenger = null
      @messages = []
      @ranges = []
      @json = require './php.json'
      
    deactivate: ->
      @messages.map (msg) -> msg.destroy()

    serialize: ->
      return "{}"

    consumeInlineMessenger: (messenger) ->
      @messenger = messenger

    toggle: ->
        console.log 'QuickDocs was toggled!'
        editor = atom.workspace.getActiveTextEditor()
        editor.selectWordsContainingCursors()
        
        fun = editor.getSelectedText()
        range = editor.getSelectedBufferRange()
        
        if fun?.length && @messages[range.toString()+fun] == undefined
            @get_info(fun, range)
        else
            @messages[range.toString()+fun].destroy()
            @messages[range.toString()+fun] = undefined
            
    get_info: (fun, range) ->
        
        if @json[fun] == undefined 
            @messages[range.toString()+fun] = @messenger.message
                    range: range
                    text: 'Not a PHP function ?'
        else
            desc = @json[fun]['s'].replace(/(\n\s\s+|\s\s+)/g, " ")+"\n\n"+@json[fun]['r'].replace(/(\n\s\s+|\s\s+)/g, " ")
            @messages[range.toString()+fun] = @messenger.message
                range: range
                text: desc
                suggestion: @json[fun]['y'].replace(/(\n\s\s+|\s\s+)/g, " ")
