//= require jquery
//= require jquery_ujs
//= require alertify
//= require underscore

//= require smoothie
//= require jquery.mobile-events.min.js
//= require inobounce.min
//= require jquery-ui/core
//= require jquery-ui/effects/effect-slide
//= require jquery-ui/widgets/draggable
//= require jquery-ui/widgets/droppable
//= require jquery.ui.touch-punch.min
//= require semantic-ui


//= require ace-rails-ap
//= require ace/theme-twilight
//= require ace/mode-javascript

$ -> 
  utility.appLinks()
  $(".dropdown").dropdown()
  # document.body.addEventListener 'touchmove', (event)-> event.preventDefault()
  custom_input_mechanims()
  audio.resolve_canvas $(".create-panel")
  bind_collection_events($('.collection-panel li'))
  

window.get_id = (el)-> return if el.id then el.id.$oid else el._id.$oid


window.utility = {}
window.utility.appLinks = ()->
   # For iOS Web apps, so they do not open in new window
  if 'standalone' of window.navigator and window.navigator.standalone
    # If you want to prevent remote links in standalone web apps opening Mobile Safari, change 'remotes' to true
    noddy = undefined
    remotes = false
    document.addEventListener 'click', ((event) ->
      noddy = event.target
      # Bubble up until we hit link or top HTML element. Warning: BODY element is not compulsory so better to stop on HTML
      while noddy.nodeName != 'A' and noddy.nodeName != 'HTML'
        noddy = noddy.parentNode
      if 'href' of noddy and noddy.href.indexOf('http') != -1 and (noddy.href.indexOf(document.location.host) != -1 or remotes)
        event.preventDefault()
        # do not redirect page on data-remote links
        (document.location.href = noddy.href) unless $(noddy).data('remote') == true
      return
    ), false

window.utility.resolve_template = (inject, obj, template)->
    if _.isUndefined(template)
      template = inject.find('li.template')
    
    template = template.clone().removeClass("template")
    _.each obj, (val, key, i)->
      if key == "oid"
        val = val["$oid"]
      $(template).find("*").andSelf().filter("[data-html='"+key+"']").html(val)
      $(template).find("*").andSelf().filter("[data-html-arr='"+key+"']").html(_.map val, (el)-> $("<span>").html(el))
      $(template).find("*").andSelf().filter("[data-encode='"+key+"']").data(key, val)
      $(template).find("*").andSelf().filter("[data-encode-attr='"+key+"']").attr(key, val)
      $(template).find("*").andSelf().filter("[data-href='"+key+"']").attr("href", val)
      $(template).find("*").andSelf().filter("[data-src='"+key+"']").attr("src", val)
    inject.append(template)

    # HANDLERS
    if $(template).data("obj")
      $(template).data("obj", obj)
    if fn = $(template).data("click")
      fn = eval(fn)
      fn($(template))
    return template

# url, data, template, inject, done
window.utility.load_entries = (request)->
  request.method = "GET"
  request.success = (entries)->
    request.inject.children(":not(.template)").remove()
    _.each entries, (entry)->
      if request.exclude and _.includes(request.exclude, entry.oid["$oid"])
        return
      result = utility.resolve_template(request.inject, entry, request.template)

    if request.done
      request.done(entries)
      
  $.ajax request

window.pills = {}

pills.make = (label, inject)->
  if _.isUndefined(inject)
    inject = $(".fieldset." + label.timing)
  template = $('.pill.template')

  template = utility.resolve_template(inject, label, template) 

  if not inject.hasClass("selectable")
    template.addClass(label.type.toLowerCase())
  else
    template.on "tap", (event)->
      $(this).toggleClass("selected")
  if inject.hasClass('small')
    template.addClass("small")
  template.addClass(label.timing.toLowerCase())
  template.data("obj", label)
  template.on "taphold", (event)-> 
    labels = _.map $(this).siblings(), (el)->
     return $(el).data('obj')
    $(this).parent().data('labels', labels)
    $(this).remove()

  inject.append(template)
  return template

pills.selected = (container)->
  pills = container.find(".pill.selected:not(.template)")
  return _.map pills, (p)-> $(p).data("obj")

pills.collect = ()->
  tags = pills.selected($(".create-panel .fieldset"))
  prev_tags = _.values $('.fieldset.log').data("labels")
  tags = _.flatten [prev_tags, tags]
  $('.fieldset.log').data("labels", tags)
  resolve_fieldsets(".create-panel")

window.getPills = (container)->
  pills = container.find(".pill:not(.template)")
  return _.map pills, (p)-> $(p).data("obj")

window.bind_collection_events = (items)->
  _.each items, (item)->
    if $(item).hasClass("collapsible") or $(item).hasClass("template")
      return
    else
      $(item).addClass("collapsible").click ()-> 
        $(this).toggleClass('collapsed')
        audio.resolve_canvas($(this))
      $(item).on 'click', (e)->
        if $(this).parent().hasClass("selection")
          $(this).toggleClass("selected")
      $(item).on 'swipeleft', (e)->
        console.log "SWIPE_LEFT"
        $(this).addClass('destroyable')
        $(".view").off("swiperight")
        $(".view").off("swipeleft")
      $(item).on 'swipeend', (e)->
        console.log "SWIPE_END"
        $(".view").on "swiperight", swiperight
        $(".view").on "swipeleft", swipeleft
      $(item).on 'swiperight', (e)->
        onsole.log "SWIPE_RIGHT"
        $(this).removeClass('destroyable')
        $(".view").off("swiperight")
        $(".view").off("swipeleft")
        
window.bind_search_events = (items)->
  _.each items, (item)->
    $(item).draggable
      cursor: "move"
      cursorAt: { bottom: -0, right: -0 }
      scroll: false
      start: (event, ui)->
        $(this).addClass("selected")
        selection = datamodels.get_selected_obj()
        
        labels = _.unique(_.flatten(_.map selection, (s)-> s.labels))
        data = _.flatten(_.map selection, (s)-> s.duration)
        data_sum = _.reduce data, ((memo, num) -> return memo + num ), 0
        data_sum = data_sum+""
        pretty_time = data_sum.toHHMMSS()
        header = $('<div>').html("Drag to classify.").addClass("header")
        desc = $('<div>').addClass("description")
          .append($("<span>").html(selection.length + " Record"))
          .append($("<span>").html(" - "))
          .append($("<span>").html(pretty_time))
        ui.helper.html([header, desc])
      helper: (event)->
        return $( "<div class='helper entries ui-widget-header'>Drag to a classification box.</div>" )
  window.bind_collection_events(items)


custom_input_mechanims = ()->
  $(".fieldset.chooseone").find(".button").click (event)->
    $(this).siblings(".button").removeClass('selected')
    $(this).addClass('selected')
    $(this).parent().find("[name='help']").html($(this).attr('help'))
    $(this).siblings("input").val($(this).attr('value'))
    if $(this).attr('value') == "esmlabels"
      $(this).parents('form').addClass("esm-form")
    else
      $(this).parents('form').removeClass("esm-form")




window.millis = ()->
  (new Date).getTime()/1000


window.resolve_fieldsets = (dom)->
  fieldsets = $(dom).find('.fieldset.labels')
  _.each fieldsets, (f)->
    inject = $(f)
    inject.children().remove()
    labels = inject.data("labels")
    _.each labels, (label)->
      pills.make(label, inject)
    
window.sampling_history = []
window.SAMPLING_WINDOW = 200
window.audio = {}
window.audio.resolve_canvas = ($item)->
  selector = $item.find("canvas")
  return if $(selector).hasClass('rendered') 

  $(selector)
    .attr('width', $(selector).parent().width()-30)
    .attr('height', "100px")
    .addClass("rendered")

  _.each $(selector), (canvas)->
    smoothie = new SmoothieChart()
    smoothie.streamTo(canvas)
    line1 = new TimeSeries

    smoothie.addTimeSeries line1, 
      strokeStyle:'rgb(0, 255, 0)'
      fillStyle:'rgba(0, 255, 0, 0.4)'
      lineWidth: 1

    data = $(canvas).attr('data-samples')

    if $(canvas).hasClass('stream')
      $(document).on "mic-read", (event, message)->
        _.each message.data, (d, i)->
          line1.append((new Date).getTime(), d)
        sampling_history = window.sampling_history
        h_n = sampling_history.unshift({n: message.data.length, t: message.time})
        
        
        if sampling_history.length > SAMPLING_WINDOW
          sampling_history = sampling_history.slice(0, SAMPLING_WINDOW)

        if sampling_history.length == SAMPLING_WINDOW
          sum = 0
          start = sampling_history[SAMPLING_WINDOW-1].t
          end = sampling_history[0].t
          sum = sampling_history.length * 16
          # _.each sampling_history, (x)->
          #   sum = sum + x.n
          sr = sum/((end - start)/1000)
          $(document).trigger "sampling_update", sr
        window.sampling_history = sampling_history
        

    else
      _.each data, (d, i)->
        line1.append((new Date).getTime() + i * 1000, d)  





window.start_socket = (clientname, host, port)->
  url = 'ws://'+ host+':' + port
  socket = new WebSocket(url)
  socket.name = clientname
  socket.version = "1.0"
  socket.debug = true
  socket.onopen = (event)->
    $(document).trigger("socket-connected")
    console.log "CONNECTED"
    message = 
      event: "greeting"
    socket.format_send(message)
    socket.format_send(COMMAND_MIC_OFF)   

  socket.format_send = (api)->
    if _.isUndefined(socket)
      alertify("Socket not connected")
    message = 
      name: socket.name
      version: socket.version
      api: api

    if socket.readyState == socket.OPEN
      console.log "Client >>", message
      return socket.send JSON.stringify message
    false

  socket.onclose = (event)->
    $(document).trigger("socket-disconnected")
    # ATTEMPT RECONNECTION EVERY 5000 ms
    _.delay (()-> start_socket(host, port)), 5000
  
  socket.onerror = (event)->
    if socket.debug
      console.log("Client << ", event)
    alertify.error("<b>Error</b><p>Could not contact socket server at "+url+"</p>")
  
  socket.onmessage = (event)->
    if socket.debug
      console.log("Client << ", event.data)
    stream = JSON.parse(event.data)
    $(document).trigger(stream.event, stream)
  return socket

String::toHHMMSS = ->
  sec_num = parseInt(this, 10)
  # don't forget the second param
  hours = Math.floor(sec_num / 3600)
  minutes = Math.floor((sec_num - (hours * 3600)) / 60)
  seconds = sec_num - (hours * 3600) - (minutes * 60)
  if hours < 10
    hours = '0' + hours
  if minutes < 10
    minutes = '0' + minutes
  if seconds < 10
    seconds = '0' + seconds
  hours + ':' + minutes + ':' + seconds