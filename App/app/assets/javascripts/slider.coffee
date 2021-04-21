$ ->
  # Updates blue observed line on pressure slider
  $(document).on "read-pressure", (event, stream)->
    slider = $('slider.pressure')
    h = $(slider).height()
    border = 3 # from CSS
    y = stream.data[0]
    y_offset = (h * (y/100)) - border*2
    $(this).find("island.observed").height(y_offset)
    # Hit detection
    targetPressure = parseInt($('slider.pressure').siblings('input').val())
    tolerance = 100 * 0.10
    detectedPressure = y
    diffPressure = targetPressure - detectedPressure
    inBounds = Math.abs(diffPressure) < tolerance
    if difference > tolerance 
      $(document).trigger "overinflation", difference
    


     
  # Touch event handling for slider widgets
  $('slider').on "touchmove", (e)->
    # Calculate relative y position; 0-100; 10 step
    rect = e.currentTarget.getBoundingClientRect()
    yPos = e.originalEvent.touches[0].pageY
    y = (yPos - rect.y)/rect.height
    y = if y > 1 then 1 else y
    y = if y < 0 then 0 else y
    y = 1 - y
    y = parseInt(y * 10) * 10

    
    $(this).parent().find("input").val(y)
    $('slider').trigger("update")
  $('.ui-slider button').click (e)->
    v = $(this).attr('value')
    $(this).parent().find('input').val(0)
    $('slider').trigger("update")


  $('slider').on 'update', (e)->
    y = $(this).parent().find("input").val()
    h = $(this).height()
    border = 3 # from CSS
    y_offset = (h * (y/100)) - border*2
    buffer = 0.10 * h
    if $(this).hasClass('pressure')
      $(this).find("island.target").css("bottom", y_offset - (buffer/2))
      $(this).find("island.target").height(buffer)

    else
      $(this).find("island.target").height(y_offset)
      
  $('slider').trigger('update')
