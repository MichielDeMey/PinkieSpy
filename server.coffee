port = 8080
io = require('socket.io').listen port

io.configure 'production', ->
	io.enable 'browser client minification'  # send minified client
	io.enable 'browser client etag'          # apply etag caching logic based on version number
	io.enable 'browser client gzip'          # gzip the file
	io.set 'log level', 1

	io.set 'transports', [
	    'websocket'
	  , 'flashsocket'
	  , 'htmlfile'
	  , 'xhr-polling'
	  , 'jsonp-polling'
	  ]

console.log "*******************************************************"
console.log "Welcome to the Pinkiespy server."
console.log "Written in CoffeeScript\nMichiel De Mey (c)2012-2013"
console.log "*******************************************************"
console.log "Listening on port " + port

usernames = { }

io.sockets.on 'connection', (socket) ->

	socket.on 'sendcomment', (comment) ->
		if comment?
			console.log "New comment from #{socket.username}: #{comment.content}"

			user =
				username: socket.username,
				color: socket.color,
				provider: socket.provider,
				room: socket.room

			io.sockets.in(socket.room).emit 'updatecomment', user, comment

	socket.on 'sendimage', (image) ->
		if image? and image != ''
			console.log "New image from #{socket.username}: #{image}"
			msg_img = "<img class='chat_img_thumb' src='#{image}' alt='' />"

			user =
				username: socket.username,
				color: socket.color,
				provider: socket.provider,
				room: socket.room

			io.sockets.in(socket.room).emit 'updatechat', user, msg_img, socket.color

	socket.on 'sendchat', (message) ->
		msg = message.replace /<(?:.|\n)*?>/gm, ''
		if msg? and msg != ''
			console.log "New message from #{socket.username}: #{msg}"

			user =
				username: socket.username,
				color: socket.color,
				provider: socket.provider,
				room: socket.room

			io.sockets.in(socket.room).emit 'updatechat', user, msg, socket.color

	socket.on 'updatelocation', (data) ->
		console.log "Received location: " + data
		socket.broadcast.to(socket.room).emit 'updatelocation', data

	socket.on 'checkusername', (uname) ->
		console.log "Checking username: " + uname
		if uname of usernames
			socket.emit 'checkusername', true
		else
			socket.emit 'checkusername', false

	socket.on 'adduser', (u) ->
		console.log u
		user = JSON.parse u
		username = user.username

		socket.join(user.room)
		console.log "#{username} joined the #{user.room} room"

		# Sometimes, a generated color has 1 digit short.
		clr = '#'+Math.floor(Math.random()*16777215).toString(16)
		if clr.length == 6
			console.log "Color error, let me fix that for you."
			clr = clr + 0

		user =
			username: username,
			windowheight: user.windowheight,
			color: clr,
			provider: user.provider,
			room: user.room

		console.log "New client connected: " + username

		# we store the username in the socket session for this client
		socket.username = username
		# we store the color in the socket session for this client
		socket.color = clr
		# we store the provider in the socket session for this client
		socket.provider = user.provider
		# we store the room in the socket session for this client
		socket.room = user.room

		# add the client's username to the global list
		usernames[username] = user

		user_server =
			username: "Server",
			color: "#000",
			provider: "server"

		# echo to client they've connected
		socket.emit 'updatechat', user_server, 'You are now connected. Have fun!', "#000"
		# echo globally (all clients) that a person has connected
		socket.broadcast.to(socket.room).emit 'updatechat', user_server, username + ' has connected', "#000"
		# update the list of users in chat, client-side
		io.sockets.in(socket.room).emit 'updateusers', JSON.stringify usernames

	socket.on 'disconnect', ->
		if socket.username?
			# remove the username from global usernames list
			delete usernames[socket.username]

			user_server =
				username: "Server",
				color: "#000",
				provider: "server"

			# update list of users in chat, client-side
			io.sockets.in(socket.room).emit 'updateusers', JSON.stringify usernames
			# echo globally that this client has left
			socket.broadcast.to(socket.room).emit 'updatechat', user_server, socket.username + ' has disconnected', "#000"