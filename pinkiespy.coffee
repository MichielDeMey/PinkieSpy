###
	Pinkiespy written by Michiel De Mey (c)2012-2013
###

root = exports ? this

root.username = ""
root.first_time = true
root.socket = null

$ = jQuery

# DOCUMENT.READY #

$ ->
	this.first_time = true

	$("#btn_connect_big").click ->
		showLogin()

	try
		addComponents false

		PORT = 5000
		URL = "http://seppestas.be:5000"
		console.log "Connecting to " + URL
		root.socket = io.connect URL

		if socket?
			bindSocketActions()
			bindLogin()
			showLogin()
	catch e
		console.log "Could not connect to the server."
		console.log "Error: " + e.message
		showError e

# END OF DOCUMENT.READY #

# ADD COMPONENTS #

addComponents = (connected) ->
		components = $("#pinkiespy_components")

		if not connected
			# Add alerts
			components.append '<div id="alerts"></div>'
			# Add login modal
			components.append '
			<div id="modal_connect" class="modal hide fade" role="dialog" data-backdrop="static" data-keyboard="false">
				<div class="modal-header">
					<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
					<h3>Be social, join the others.</h3>
				</div>

				<div class="modal-body" style="background-image: url(http://michieldemey.be/images/pinkie_happy.png); background-repeat: no-repeat; background-position: 68% 8px;">
					<p>Heya, this is a social experience! <br> Connect with others from around the globe!</p>
					<label>What\'s your name?</label>
					<div id="cg_username" class="control-group">
						<div class="controls">
							<input id="txt_username" type="text" placeholder="Nickname, surname, ...">
							<span id="txt_username_info" style="display: none;" class="help-block">This username is already connected</span>
						</div>
					</div>
				</div>
				<div class="modal-footer">
					<button data-dismiss="modal" aria-hidden="true" class="btn">I\'m not a social person</button>
					<button id="btn_connect" type="button" class="btn btn-primary" data-loading-text="Connecting...">Connect</button>
				</div>
			</div>'
		else
			# Add client bars
			components.append '<div id="clients"></div>'
			# Add chat container
			components.append '<div id="chat_container" rel="popover" data-placement="top" data-original-title="Did you know?" data-content="Here you can chat with others!" style="display: none;" class="chat_minimal"> <div id="chat_titlebar"><p id="chat_titlebar_text">Click to open the chat.</p></div> <div id="chat_messages"> </div> <div id="chat_input" class="input-append" style="display: none;"> <input type="text" placeholder="Type your message..."> </div> </div>'

# END OF ADD COMPONENTS #

# LOGIN MODAL #

bindLogin = ->
	$("#txt_username").keyup (ev) ->
		if ev.which == 13
	   	clickLogin()

	$("#btn_connect").click ->
		$(this).button 'loading'
		clickLogin()

showLogin = -> 
	$('#cg_username').removeClass 'info'
	$('#txt_username_info').hide()

	$('#modal_connect').modal 'show'
	$('#txt_username').focus()

hideLogin = -> 
	$('#modal_connect').modal 'hide'
	$('#btn_connect').button 'reset'

# END OF LOGIN MODAL #

clickLogin = ->
	uname = $("#txt_username").val()
	uname_safe = uname.replace(/[^a-z0-9]/gi,'')

	try
		login uname_safe
	catch e
		showError e

showAlert = (message, importance) ->
	alert = $("<div class='fade in alert #{importance}'> #{message} </div>").prependTo $('#alerts')
	alert.bind 'closed', (event) => alert.remove()

	callback = -> alert.alert 'close'
	setTimeout callback, 7000

showError = (ex) ->
	alert = "<button type='button' class='close' data-dismiss='alert'>&#215;</button><h4 class='alert-heading'>Yikes! I messed up!</h4><p>It looks like I can\'t connect you with the others.</p><p>Error message: #{ex.message}</p>"
	showAlert alert, "alert-error"

showModalUser = (uname) ->
	$('#' + uname).popover 'show'
	callback = -> $('#' + uname).popover 'destroy'
	setTimeout callback, 7000
	root.first_time = false

login = (uname = "Anonymous" + Math.round (new Date()).getTime() / 1000 ) ->
	try
		console.log "Negotiating username.."
		root.username = uname

		socket.emit 'checkusername', root.username
	catch e
		showError e

login_complete = ->
	# Logged in!
	addComponents true

	# Request position updates.
	socket.emit 'updaterequest'

	$("#chat_titlebar").click -> 
		container = $("#chat_container")
		container.toggleClass "chat_full"
		container.toggleClass "chat_minimal"
		$("#chat_input").toggle()

		$(this).toggleClass "full"

		if $(this).hasClass "full"
			$("#chat_titlebar_text").text "Click to close the chat."
		else
			$("#chat_titlebar_text").text "Click to open the chat."

	$('#btn_connect_big').hide 'fast'
	hideLogin()

	showAlert '<strong>Hooray!</strong> You are now socially connected.', 'alert-success'
	chatcontainer = $("#chat_container")
	chatcontainer.show()

	$("#chat_input input").keyup (ev) ->
		if ev.which == 13
		   	msg = $(this).val().replace /<(?:.|\n)*?>/gm, ''
		   	if msg != ''
		   		sendChat msg
		   	$(this).val ''

	$(root).resize -> updateLocation()
	$(root).scroll -> updateLocation()

bindSocketActions = ->
	socket.on 'connect', ->
		console.log "Connected!"

	socket.on 'checkusername', (taken) ->
		if not taken
			console.log "Username is available, now logging in."

			user = 
				username: root.username,
				rootheight: root.innerHeight

			socket.emit 'adduser', JSON.stringify user

			login_complete()
		else
			console.log "Username is already connected. Please try again."
			$('#cg_username').addClass 'info'
			$('#txt_username_info').show()
			$('#btn_connect').button 'reset'

	socket.on 'updateusers', (data) ->
		console.log "Userlist changed: "

		users = $.parseJSON data
		console.log users

		$('#clients').empty()
		n = 0

		#For each client
		$.each users, (i, item) ->
		    if item.username != root.username
		    	$('#clients').append "<div rel='popover' data-original-title='Did you know?' data-content='Here you can track other people\'s reading progress!' id='#{item.username}' class='client' style='height: #{item.rootheight}px; border-color: #{item.color}; left: #{n*5}px;'><div class='namecard' style='background-color: #{item.color}'><span> #{item.username} </span></div></div>"

		    	#Show the modal only once
		    	if n == 0 and root.first_time == true
		    		showModalUser item.username

		    	n++

	socket.on 'updatelocation', (data) ->
		obj = $.parseJSON data
		console.log "New location update: " + obj.loc + " from " + obj.username
		
		name = "#" + obj.username
		$(name).css
			"top": obj.loc + "px", "height": obj.height + "px"

	socket.on 'updaterequest', ->
		console.log "Received update request, updating location"
		updateLocation()

	socket.on 'updatechat', (username, message, color) ->
		chatmessage = $("#chat_messages")
		chatmessage.append "<div class='chat_message'><div style='color:#{color}' class='chat_name'> #{username}:</div><div>#{message}</div></div>"
		chatmessage.scrollTop chatmessage[0].scrollHeight

updateLocation = ->
	tp = document.body.scrollTop

	locupdate = 
		username: root.username,
		loc: tp,
		height: root.innerHeight

	socket.emit 'updatelocation', JSON.stringify locupdate

sendChat = (message) ->
	console.log "Sending chat message: " + message
	socket.emit 'sendchat', message