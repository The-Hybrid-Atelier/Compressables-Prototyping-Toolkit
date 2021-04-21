class window.GestureCanvas
  @FAT_FINGER_OFFSET: 80
  @FONT: "Arial"
  @SCALE: 0.05 * 4
  @LIMITS_OFFSET: 40
  @GESTURE_TIME: 5
  @GESTURE_TIME_INCREMENT: 0.5
  constructor: (ops)->
    console.log "✓ Paperjs Functionality"
    this.name = "gesture"
    @_layout = "left-handed"
    @_input = "temporal"
    @a = null
    @b = null
    @c = null
    @d = null
    @e = null
    @setup(ops)
  command: ()->
    commands = paper.project.getItems
      name: "command"
    if commands.length == 0
      return 0
    else
      starting_sp = cb.setpoint
      commands = commands[0]
      if @_input == "instantaneous"
        
        return [[0, commands.setpoint]]
      else if @_input == "temporal"

        commands.t.push(commands.t[commands.t.length - 1] + 250)
        commands.setpoints.push(starting_sp)
        commands.t.unshift(-250)
        commands.setpoints.unshift(starting_sp)
        commands.t = _.map commands.t, (t)-> return t + 250 
        return _.zip(commands.t, commands.setpoints)

  setup: (ops)->
    scope = this
    $("label.temporal").html("Draw a "+GestureCanvas.GESTURE_TIME+" second wave.")
    canvas = ops.canvas[0]
    $(canvas)
      .attr('width', ops.canvas.parent().width())
      .attr('height', ops.canvas.parent().height())

    # $(canvas).css
      # width: ops.canvas.parent().width()
      # height: ops.canvas.parent().height()
    window.paper = new paper.PaperScope
    loadCustomLibraries()
    paper.setup canvas
    paper.view.zoom = 1
    @temporal = new paper.Tool
      name: "temporal"
      init: ()->
        scope = this
        console.log "temporal"
        paper.project.clear()
        

        @time_lines = _.range(0, GestureCanvas.GESTURE_TIME+GestureCanvas.GESTURE_TIME_INCREMENT, GestureCanvas.GESTURE_TIME_INCREMENT) #250 ms increments
        @time_lines = _.map @time_lines, (t, i)->
          p = t / GestureCanvas.GESTURE_TIME
          top = paper.view.bounds.topLeft.add(new paper.Point(GestureCanvas.LIMITS_OFFSET, 0))
          bottom = paper.view.bounds.bottomLeft.add(new paper.Point(GestureCanvas.LIMITS_OFFSET, 0))
          right = paper.view.bounds.topRight.add(new paper.Point(-1 * GestureCanvas.LIMITS_OFFSET, 0))
          range = right.subtract(top)
          range = range.length
          major = if i%4 == 0 then false else true
          return new paper.Path.Line
            name: "time_lines"
            t: t
            from: new paper.Point(GestureCanvas.LIMITS_OFFSET + (range * p), top.y + GestureCanvas.LIMITS_OFFSET)
            to: new paper.Point(GestureCanvas.LIMITS_OFFSET + (range * p), bottom.y - GestureCanvas.LIMITS_OFFSET)
            strokeColor: if major then new paper.Color(0.8) else new paper.Color(0.1)
            strokeWidth: 1
            dashArray: if major then [1, 1] else []
        @upper = new paper.Path.Line
          name: 'upper'
          from: paper.view.bounds.topLeft.add(new paper.Point(0, GestureCanvas.LIMITS_OFFSET))
          to: paper.view.bounds.topRight.add(new paper.Point(0, GestureCanvas.LIMITS_OFFSET))
          strokeColor: "green"
          strokeWidth: 1
        @mid = new paper.Path.Line
          name: 'mid'
          from: paper.view.bounds.leftCenter.add(new paper.Point(GestureCanvas.LIMITS_OFFSET, 0))
          to: paper.view.bounds.rightCenter.add(new paper.Point(-GestureCanvas.LIMITS_OFFSET, 0))
          strokeColor: "green"
          strokeWidth: 1
          dashArray: [1,1]

        @lower = new paper.Path.Line
          name: 'lower'
          from: paper.view.bounds.bottomLeft.add(new paper.Point(0, -GestureCanvas.LIMITS_OFFSET))
          to: paper.view.bounds.bottomRight.add(new paper.Point(0, -GestureCanvas.LIMITS_OFFSET))
          strokeColor: "green"
          strokeWidth: 1
        @posbg = new paper.Path.Rectangle
          from: @upper.bounds.topLeft.clone()
          to: @mid.bounds.bottomRight.clone().add(new paper.Point(GestureCanvas.LIMITS_OFFSET, 0))
          fillColor: "blue"
          opacity: 0.05
        @blow_label = new paper.PointText
          font: "Arial"
          fontSize: 50
          fillColor: "blue"
          content: 'BLOW'
          fontWeight: 'bold'
          justifiaction: 'center'
          opacity: 0.1
        @blow_label.set
          position: @posbg.bounds.center
        @negbg = new paper.Path.Rectangle
          from: @mid.bounds.topLeft.clone().add(new paper.Point(-GestureCanvas.LIMITS_OFFSET, 0))
          to: @lower.bounds.bottomRight.clone()
        @suck_label = new paper.PointText
          font: "Arial"
          fontSize: 50
          fillColor: "black"
          content: 'SUCK'
          fontWeight: 'bold'
          justifiaction: 'center'
          opacity: 0.05
        @suck_label.set
          position: @negbg.bounds.center

        @scrubber = @time_lines[0].clone()
        
        @scrubber.set
          name: "scrubber"
          strokeColor: "#00A8E1"
          strokeWidth: 2
          to: (t)->
            t = t / 1000 / GestureCanvas.GESTURE_TIME
            if t * scope.mid.length <= scope.mid.length
            	pt = scope.mid.getPointAt(t * scope.mid.length)
            	this.position.x = pt.x
            	paper.view.update()
          addPoint: (l)->
            p = cb.to_p(cb.pressure)
            p = if p > 1 then 1 else p
            p = if p < 0 then 0 else p
            p = 1 - p
            l.addSegment(this.getPointAt(this.length * p))
            l.smooth()
            paper.view.update()

        p = cb.to_p(cb.setpoint)
        left = new paper.Path.Line
          to: @upper.firstSegment.point
          from: @lower.firstSegment.point
        right = new paper.Path.Line
          to: @upper.lastSegment.point
          from: @lower.lastSegment.point

        @setline = new paper.Path.Line
          name: 'setline'
          from: left.getPointAt(left.length * (p))
          to: right.getPointAt(right.length * (p))
          strokeColor: "blue"
          strokeWidth: 3
          dashArray: [1,1]

        left.remove()
        right.remove()

        paper.view.update()
      bound_check_x: (x)->
        if x < @path.lastSegment.point.x
          return @path.lastSegment.point.x
        else
          return x
      bound_check_y: (y)->
        if y < @upper.firstSegment.point.y
          return @upper.firstSegment.point.y
        else if y > @lower.firstSegment.point.y
          return @lower.firstSegment.point.y
        else
          return y
      onMouseDown: (event)->
        @init()
        @path = new paper.Path
          name: "wave"
          strokeColor: "green"
          strokeWidth: 4
          segments: [event.point]
      onMouseDrag: (event)->
        pt = event.point
        pt.x = @bound_check_x(pt.x)
        pt.y = @bound_check_y(pt.y) 
        @path.addSegment(pt)
        # @path.simplify()
      onMouseUp: (event)->
        scope = this
        pt = event.point
        pt.x = @bound_check_x(pt.x)
        pt.y = @bound_check_y(pt.y)
        @path.addSegment(pt)
        last_pt = null
        segments = _.map @time_lines, (tl)->
            ixts = scope.path.getIntersections(tl)
            if ixts.length > 0
              ixt = ixts[ixts.length - 1]
              last_pt = ixt.point.clone()
              info = 
                segment: ixt.point
                p: 1 - (tl.getNearestLocation(ixt.point).offset / tl.length)
                t: tl.t
            else if last_pt
              last_pt.x = tl.firstSegment.point.x
              info =  
                segment: last_pt
                p: 1 - (tl.getNearestLocation(last_pt).offset / tl.length)
                t: tl.t
            else
              p = 1 - cb.to_p(cb.setpoint)
              info =  
                segment:  tl.getPointAt(p * tl.length)
                p: 1 - p
                t: tl.t
            return info

        segments = _.compact segments
        
      
        @path2 = new paper.Path
          name: "command"
          strokeColor: "#5CCA5B"
          strokeWidth: 4
          t: _.map segments, (v)-> v["t"] * 1000 #milliseconds
          p: _.pluck segments, "p"
          setpoints: _.map segments, (v)-> parseInt(cb.to_pressure(v["p"]))
          segments: _.pluck segments, "segment"

        @path.remove()



    @instantaneous = new paper.Tool
      name: "instantaneous"
      minDistance: 5
      init: ()->
        console.log "instantaneous"
        paper.project.clear()
        paper.view.update()
        
      onMouseDown: (event)->
        paper.project.clear()

        @scrubber = new paper.Path.Line
          name: "scrubber"
        @scrubber.to = (t)->
          # console.log ("INST")
          paper.view.update()
        @scrubber.addPoint = (l)->
          paper.view.update()

        @mdpt = event.point
        fat_finger_pt = event.point.clone()
        l = paper.project.view.bounds.topLeft.x
        r = paper.project.view.bounds.topRight.x
        @fat_direction = if l - event.point.x > event.point.x - r then 1 else -1
        fat_finger_pt.x += GestureCanvas.FAT_FINGER_OFFSET * @fat_direction
        @path = new paper.Path
          name: "command"
          segments: [fat_finger_pt, fat_finger_pt.clone()]
          strokeWidth: 4
          strokeColor: "#5CCA5B"
      onMouseDrag: (event)->
        if not event.point.isInside(paper.view.bounds.expand(-15))
          return
        @path.lastSegment.point.y = event.point.y
        # Cleanup
        if @head then @head.remove()
        if @label then @label.remove()
        # Arrowhead Construction
        head_pt = event.point.clone()
        head_pt.x =  @path.lastSegment.point.x
        direction =  if @path.lastSegment.point.getDirectedAngle(@path.firstSegment.point) > 0 then 1 else -1
        @head = new paper.Path
          segments: [head_pt.add(new paper.Point(-10, direction * 20)), head_pt, head_pt.add(new paper.Point(10, direction * 20))]
        @head.style = @path.style
        # Labeling
        dir_label = if direction > 0 then "+ " else ""
        distance = @path.length * GestureCanvas.SCALE
        label = "error"
        if cb
          distance = direction * distance
          cb.next_setpoint = distance
          @path.setpoint = cb.next_setpoint + cb.setpoint

        $("#send").click()

    paper.view.update()
  save: (loc, value)-> 
    value = paper.project.getItem({name: "command"})
    $("[action='save'][save_id='"+loc+"']").html("X").addClass("blue")
    this[loc] = value
  load: (loc)->
    command = paper.project.getItem({name: "command"})
    if this[loc]
      if command then command.remove()
      paper.project.activeLayer.addChild this[loc]
      paper.view.update()
  clear_save: (loc)->
    $("[action='save'][save_id='"+loc+"']").html(loc.toUpperCase()).removeClass("blue")
    this[loc] = null
  clear: ->
    paper.project.clear()
    paper.view.update()
    

  Object.defineProperties @prototype, 
    
    layout:
      get: -> @_layout
      set: (value)-> 
        if value == @_layout then return
        @_layout = value
        switch value 
          when "left-handed"
            $(".state").remove().appendTo($("#input"))
            $('#controller').removeClass("right-handed")
            $('#controller').addClass("left-handed")
            $('[action="hand-toggle"]').html("CHANGE TO RIGHT-HAND")
          when "right-handed"
            $(".state").remove().prependTo($("#input"))
            $('#controller').addClass("right-handed")
            $('#controller').removeClass("left-handed")
            $('[action="hand-toggle"]').html("CHANGE TO LEFT-HAND")
    input: 
      get: -> @_input
      set: (value)->
        if value == @_layout then return
        @_input = value
        
        $('#input').attr("mode", value)
        switch @_input
          when "temporal"
            cb.ss = cb.setpoint
            $("#stop").show()
            paper.tool = @temporal
            paper.tool.init()
            $('[action="input-toggle"]').html("SWITCH TO INSTANTANEOUS MODE")
          when "instantaneous"
            $("#stop").hide()
            paper.tool = @instantaneous
            paper.tool.init()
            $('[action="input-toggle"]').html("SWITCH TO TEMPORAL MODE")
        
