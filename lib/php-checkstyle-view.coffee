{$$, Point, SelectListView} = require 'atom'
commands = require './commands'

# Sniffer view
class PhpCheckstyleView extends SelectListView

    # Initialise the view and register the sniffer command
    initialize: (serializeState) ->
        atom.workspaceView.command "php-checkstyle:sniff-this-file", => @sniffThisFile()
        super
        @addClass('php-checkstyle-error-view overlay from-top')

    #
    getFilterKey: ->
        'filterText'

    #
    viewForItem: (checkstyleError) ->
        checkstyleErrorRow = checkstyleError.line
        checkstyleErrorLocation = "untitled:#{checkstyleErrorRow + 1}"
        lineText = checkstyleError.message

        $$ ->
          if lineText
            @li class: 'php-checkstyle-error two-lines', =>
              @div checkstyleError, class: 'primary-line'
              @div lineText, class: 'secondary-line line-text'
          else
            @li class: 'php-checkstyle-error', =>
              @div checkstyleError, class: 'primary-line'

    # Sniff the open file with all of the commands we have
    sniffThisFile: ->
        editor = atom.workspace.getActiveEditor()

        unless editor.getGrammar().scopeName is 'text.html.php'
            console.warn "Cannot run for non php files"
            return

        executablePath = atom.config.get "php-checkstyle.phpcsExecutablePath"
        standard = atom.config.get "php-checkstyle.phpcsStandard"
        warnings = atom.config.get "php-checkstyle.phpcsDisplayWarnings"

        config = {
                'executablePath': executablePath,
                'standard': standard,
                'warnings': warnings
            }

        phpcs = new commands.CommandPhpcs(editor.getPath(), config)
        command = new commands.Shell(phpcs)
        self = this
        command.execute (err, stdout, stderr) ->
            self.display err, stdout, stderr, phpcs

    # Get the error list from the command and display the result
    display: (err, stdout, stderr, command) ->
        editor = atom.workspace.getActiveEditor()

        reportList = command.process(err, stdout, stderr)
        attributes = class: 'php-checkstyle-error'

        checkstyleList = []
        for row in reportList
            line = row[0]
            message = '(' + line + ') ' + row[1]
            range = [[line, 0], [line, 0]]
            displayBufferMarker = editor.displayBuffer.markBufferRange(range, attributes)

            checkstyleError = {line, message}
            checkstyleList.push(checkstyleError)

            displayBufferMarker.on 'changed', ({isValid}) ->
                displayBufferMarker.destroy() unless isValid

        @setItems(checkstyleList)
        @storeFocusedElement()
        atom.workspaceView.append(this)
        @focusFilterEditor()

    # Confirmed location
    # @param item The item that has been selected by the user
    confirmed: (item) ->
        editorView = atom.workspaceView.getActiveView()
        position = new Point(parseInt(item.line - 1))
        editorView.scrollToBufferPosition(position, center: true)
        editorView.editor.setCursorBufferPosition(position)
        editorView.editor.moveCursorToFirstCharacterOfLine()

module.exports = PhpCheckstyleView
