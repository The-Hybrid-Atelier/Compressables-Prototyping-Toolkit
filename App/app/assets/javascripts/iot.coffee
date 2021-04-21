# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

//= require clipper
//= require paper
//= require paper2
//= require audio-effects
//= require event-logger
//= require slider
//= require compressable
//= require gesture-canvas
window.api_handler = (event)->
  if command = $(this).data("command")
    message = 
      api: 
        command: command 
        params: {}
    if params = $(this).parents('.api').find('.param')
      _.each params, (p)->
        pI = parseInt($(p).val())
        if not _.isNaN(pI)
          message.api.params[$(p).attr('name')] = pI
        else
          message.api.params[$(p).attr('name')] = $(p).val()
    if not _.isUndefined window.socket
      window.socket.jsend(message)
fullscreen_toggle = ()->
  $('.fullscreen-toggle').click (event)->
    startFullscreen = not $(".fullscreen-mode").hasClass('active')
    if startFullscreen
      fullscreen_elements = $(this).parents(".ui.segment").children()
      $(".fullscreen-mode").toggleClass('active')
        .data("parent", $(this).parents(".ui.segment"))
        .append(fullscreen_elements)
      setup_smoothie
        mode: "fullscreen"
      $(".fullscreen-mode").find(".event-listener").css("background", "black")
      $(".fullscreen-mode").find(".event-listener").css("color", "white")
    else
      $(".fullscreen-mode").toggleClass('active').data("parent")
        .append($(".fullscreen-mode").children())
      setup_smoothie()

    $(this).find('.icon').toggleClass("expand").toggleClass("compress")

hexToRgb = (hex) ->
  result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  r = 
    r: parseInt(result[1], 16)
    g: parseInt(result[2], 16)
    b: parseInt(result[3], 16)
  return r

event_listener_binding =  ()->
  # EVENT LISTENER ANIMATION
  erode = ()->
    $(".event-listener").children().fadeOut 500, ()->
      if($(".event-listener").parent().hasClass("fullscreen-mode"))
        $(".event-listener").css("background", "black")
        $(".event-listener").css("color", "white")
      else
        $(".event-listener").css("background", "white")
        $(".event-listener").css("color", "black")


  erode()

  listeners = "listeners"+window.location.pathname
  if not _.isUndefined(window.DEFAULT_EVENTS)
    if _.isUndefined(localStorage[listeners])
      localStorage[listeners] = DEFAULT_EVENTS
    $(document).on localStorage[listeners], (event, stream)->
      if stream.color
        $(".event-listener").css("background", stream.bg)
        $(".event-listener").css("color", stream.color)
      _.each stream, (value, key)->
        $(".event-listener").find("."+key).html(stream.event)
        $(".event-listener").children().fadeIn(0);
        _.delay erode, 500
$ -> 
  window.elog = new EventLogger()
  $(".server-control").on "submit", (event)->
    $("button.connect").addClass('loading')
    sa = $(this).serializeArray()
    data = _.map sa, (element)-> [element.name, element.value]
    data = _.object(data)
    window.socket = start_socket(data.host, data.port)
    event.preventDefault()

  # COLLAPSE EDITOR
  $(".editor-toggle").click (event)->
    $('#editor').toggle()
  $(".editor-toggle").click() 

  # UPDATE HIDDEN FIELDS FOR BUTTON CHECKMARKS
  $('.button-checkmark button').click (event)->
    $(this).addClass("selected blue").siblings().removeClass("selected blue")
    input = $(this).parents(".button-checkmark").attr('name')
    console.log "INPUT", input, $(this).attr("value")
    input = $(this).parents(".api").find("input[name='"+input+"']")
    input.val($(this).attr("value"))
    $('slider').trigger('update')

  # UPDATE HIDDEN RGB COLOR FIELDS FOR COLOR INPUTS
  $('input[type="color"]').on "change input", (event)->
    console.log "COLOR CHANGE", $(this).val()
    hex = $(this).val()
    $(this).siblings("input[name='red']").val(hexToRgb(hex).r)
    $(this).siblings("input[name='green']").val(hexToRgb(hex).g)
    $(this).siblings("input[name='blue']").val(hexToRgb(hex).b)

  event_listener_binding()
  fullscreen_toggle()
window.setup_editor = ()->
  window.editor = ace.edit("editor");
  editor.setTheme("ace/theme/twilight")
  JavaScriptMode = ace.require("ace/mode/javascript").Mode
  editor.session.setMode(new JavaScriptMode())
  editor.setValue("// Server Response Log\n")

window.start_socket = (host, port)->
  url = 'ws://'+ host+':' + port
  console.log "Connecting to", url
  $("#url").html(url)
  socket = new WebSocket(url)
    
  $(document).unload ()->
    socket.close()

  socket.onopen = (event)->
    $("#control-panel").addClass('green').removeClass('red')
    $("button.api").addClass('green').removeClass("disabled")
    $(".panel.disabled").removeClass("disabled")
    $("button.connect").addClass('disabled').removeClass("blue loading")
    # $("#server-control").hide()
    $(".mobile").addClass("connected")
    message = 
        name: window.NAME
        version: window.VERSION
        event: "greeting"
    socket.send JSON.stringify(message)

  socket.onclose = (event)->
    # $("#server-control").show()
    $("#control-panel").addClass('red').removeClass('green')
    $("button.api").addClass('disabled').removeClass("green")
    $("button.connect").removeClass('disabled').addClass("blue")
    $(".mobile").removeClass("connected")
    # ATTEMPT RECONNECTION EVERY 5000 ms
    _.delay (()-> start_socket(host, port)), 5000

  socket.onmessage = (event)->
    stream = JSON.parse(event.data)
    if stream.event
      # console.log "event", stream.event
      $(document).trigger(stream.event, stream)
      $(document).trigger("event", stream)
    else if stream.api
      # console.log "api", stream.api
      $(document).trigger(stream.api.command, stream.api)
    else
      console.log("Client << ", event.data)
      if editor
        editor.session.insert({row: 1, col:0}, "\nClient << "+ JSON.stringify(stream)+"")

  socket.onerror = (event)->
    console.log("Client << ", event)
    alertify.error("<b>Error</b><p>Could not contact socket server at "+url+"</p>")

  socket.jsend = (message)->
    headers = 
      name: window.NAME
      version: window.VERSION
    message = _.extend headers, message
    if this.readyState == this.OPEN
      this.send JSON.stringify message
      console.log("Client >>", message)
      if editor
        editor.session.insert({row: 1, col:0}, "\nClient >> "+ JSON.stringify(message)+"")
    else
      alertify.error("Lost connection to server (State="+this.readyState+"). Refresh?")

  $("button.api").click api_handler
      
      
  return socket