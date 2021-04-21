window.difference = (setA, setB)-> 
  _difference = new Set(setA)
  _.each Array.from(setB), (elem)->
  	_difference.delete(elem)
  return _difference

class window.StorableObject
	@save: (obj)->
		if obj.constructor.name == "Set" 	
			return {object: "Set", data: Array.from(obj)}
		else
			return obj
	@get: (val)->
		if val.object
			c = eval(val.object)
			obj = new c(val.data)
			return obj
		else
			return null

class window.JSONStorage
	constructor: (storageType)->
		@storage = window[storageType]
	get: (key)->
		val = JSON.parse(@storage.getItem(key))
		return if val.object then StorableObject.get(val) else val
	set: (key, value)->	
		console.log "set", key, value, typeof(value)
		value =  if (typeof(value) == "object") then StorableObject.save(value) 
		return @storage.setItem(key, JSON.stringify(value))
	has: (key)->
		not (@storage.getItem(key) == null)


### 
Keeps a persistant record of all events that have 
been observed on the communications channel. 

Has a filter to prevent logging of extraneous events.

Injects a UI handler to give user control of event 
logging preferences. 
* A checkbox to control the event filter
* A ticker to show latest events
* An entry in the code editor
---
###
class window.EventLogger
	constructor: ()->
		scope = this
		console.log "\tEvent Logger Included"
		@storage = new JSONStorage("sessionStorage")
		
		# Synching with session storage
		@last_event = {event: ""}
		@events_viewed = if @storage.has("events_viewed") then @storage.get("events_viewed") else new Set()
		@events_filter = if @storage.has("events_filter") then @storage.get("events_filter") else new Set()

		# *** USE scope AND NOT this/@ ***
		# Event binders

		window.addEventListener "beforeunload", ()->
			# Persistant storage
			scope.storage.set("events_viewed", scope.events_viewed)
			scope.storage.set("events_filter", scope.events_filter)
		$(document).on "ui-update", (e)-> scope.updateUI()
		$(document).on "ui-save", (e)-> scope.updateState()
		$(document).on "event", (e, msg)->
			if not msg.event
				return

			# Track state and update logic
			seen_before = scope.last_event.event == msg.event
			is_loggable= not scope.events_filter.has(msg.event)
			scope.events_viewed.add(msg.event)
			scope.last_event = msg

			if is_loggable
				# Prettify message
				sender = msg.sender
				event = msg.event
				tab = if seen_before then "\t" else ""
			
				p_msg = "\n"+tab+"\""+sender+"("+event+")\" >> "+JSON.stringify(msg)

				# Log to editor
				if editor
					editor.session.insert({row: 1, col:0}, p_msg)
				# Log to UI
				entry = $("<span class='event'>").html(event).hide()
				$(".event-logger").prepend(entry)
				entry.fadeIn(100)

		
	updateState: ()->
		console.log "\tUpdating state!"
		$('#event-options form').serializeArray()
		ok = new Set(_.pluck($('#event-options form').serializeArray(), 'name'))
		@events_filter = difference(@events_viewed, ok)

	updateUI: ()->
		$("#event-options form").html("")
		scope = this
		_.each Array.from(scope.events_viewed), (elem)->
			scope.makeCheckbox(elem, not scope.events_filter.has(elem))
		console.log("\tUI update!")
		return

	makeCheckbox: (event, checked)->
		template = $('<div class="field"><div class="ui checkbox"><input type="checkbox"><label>Event A</label></div></div>')
		template.find("input").attr('name', event)
		template.find("label").html(event)
		if checked
			template.find("input").prop("checked", checked)
			template.find(".checkbox").addClass("checked")
		template.appendTo("#event-options form")