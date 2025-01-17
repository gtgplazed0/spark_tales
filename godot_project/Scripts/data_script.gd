extends Node
# Declare the HTTPRequest variable
var http_request : HTTPRequest
var user_id = 1
var sign_up_worked = 1
var sign_in_worked = 1 
func _ready():
	"""process_story("Story1", 1, "Jimmy's First Day Of School")
	process_story("Story2", 1, "Sara's Visit to the Doctor!")
	process_story("Story3", 1, "The School Fire Drill!")
	process_story("Story4", 1, "Recess Time!!")"""
		
func upload_user(username: String, salt: String, hashed_password: String):
	var url = "https://compsciia-production.up.railway.app/users"
	# Initialize the HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	# Set up the callback for when the request is completed
	http_request.connect("request_completed", Callable(self, "_on_upload_user_request_completed"))
	# URL to your API (ensure it's correct and your server is running)

	# Data to send in the request body (JSON format)
	var data = {
		"username": username,
		"salt": salt,
		"hashed_password": hashed_password
	}
	# Serialize the data into JSON format
	var json_data = JSON.stringify(data)  # Correctly serialize the data
	var headers = ["Content-Type: application/json"]  # Set the correct content type for JSON

	# Make the POST request to the server with the data
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("Error sending request: %s" % error)  # Log error if the request fails
		user_id = 1
		sign_up_worked = -1
	await http_request.request_completed
	return sign_up_worked
# Callback for when the request completes
func _on_upload_user_request_completed(_result, response_code, _headers, body):
	if response_code == 201:
		print("User data sent successfully!")  # Log success message
		# Convert the response body to a string before parsing
		var response_str = body.get_string_from_utf8()
		var json : JSON
		json = JSON.new()
		# Parse the string into JSON using the instance
		var error = json.parse(response_str)
		print(error)
		
		# Check for parsing error by comparing the error code to OK (which is 0 in Godot)
		if error == OK:  # OK is a constant that equals 0
			var parsed_string_json = JSON.parse_string(response_str)
			var inserted_id = parsed_string_json["insertedId"]
			print("Inserted ID: %d" % inserted_id)  # Log inserted ID
			user_id = inserted_id
			sign_up_worked = 1
		else:
			print("Error parsing response JSON: %d" % error)  # Log the error code
			sign_up_worked = -1
			user_id = 1
	elif response_code == 409:
		print("User Already Exists. Response code: %d" % response_code)  # Log failure with response code
		user_id = 1
		sign_up_worked = -2
	else:
		print("Error. Response code: %d" % response_code)	
		user_id = 1
		sign_up_worked = -1
# Function to handle login request
# Example Godot code to send login data to the backend
func login(username: String, password: String):
	# Initialize the HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	# Set up the callback for when the request is completed
	http_request.connect("request_completed", Callable(self, "_on_login_request_completed"))
	# URL to your API (ensure it's correct and your server is running)
	var url = "https://compsciia-production.up.railway.app/login"

	# Data to send in the request body (JSON format)
	var data = {
		"username": username,
		'password': password
	}
	# Serialize the data into JSON format
	var json_data = JSON.stringify(data)  # Correctly serialize the data
	var headers = ["Content-Type: application/json"]  # Set the correct content type for JSON

	# Make the POST request to the server with the data
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("Error sending request: %s" % error)  # Log error if the request fails
		sign_in_worked = -1
	await http_request.request_completed
	return sign_in_worked
# Callback for when the request completes
func _on_login_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		print("successful login")  # Log success message
		
		# Convert the response body to a string before parsing
		var response_str = body.get_string_from_utf8()
		
		# Create a new JSON instance to parse the response string
		var json = JSON.new()
		
		# Parse the string into JSON using the instance
		var error = json.parse(response_str)
		if error == OK:  # OK is a constant that equals 0
			var parsed_json = JSON.parse_string(response_str)  # Parsed JSON as a Dictionary
			# Check if "user_id" exists in the response
			if "user_id" in parsed_json:
				user_id = parsed_json["user_id"]
				print("user_id: %d" % user_id)  # Log user_id
				# Handle the user ID, e.g., storing it for later use
				sign_in_worked = 1
			else:
				print("user_id not found in response")
				sign_in_worked = -3
		else:
			print("Error parsing response JSON: %d" % error)  # Log the error code
			sign_in_worked = -1
	elif response_code == 401:
		print("error, username or password incorrect")
		sign_in_worked = -2
	else:
		print("Failed to send data. Response code: %d" % response_code)  # Log failure with response code
		sign_in_worked = -1
func upload_story(title: String, pages:Array, images:Array):
	var url = "https://compsciia-production.up.railway.app/add-story"
	# Prepare HTTPRequest
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_request_completed)
	#replace with multi image
	var form_data = {
		"user_id": user_id,
		"title": title,
		"pages": JSON.stringify(pages),
		"images": []
	}
	for image in images:
		#var image_bytes = FileAccess.get_file_as_bytes(image)
		var image_bytes = image
		form_data["images"].append(image_bytes)
	var boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
	var body = generate_multipart_data(form_data, boundary)
	var headers = [
		"Content-Type: multipart/form-data; boundary=" + boundary
	]
	http_request.request_raw(url, headers, HTTPClient.METHOD_POST, body)
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Request Succeded")
		print(str(body))
	else:
		print("Request Failed with response code: ", response_code)
func generate_multipart_data(data, boundary):
	var line = ""
	var body = PackedByteArray()
	for key in data.keys():
		var value = data[key]
		# For image data, we need to handle the file part specifically
		if key == "images":
			for item in value:
				var mime_type = get_extention(item)
				line = "--" + boundary + "\r\n"
				body.append_array(line.to_utf8_buffer())
				line = "Content-Disposition: form-data; name=\"" + key + "\"; filename=\"image." + mime_type + "\"\r\n"
				body.append_array(line.to_utf8_buffer())
				line = "Content-Type: image/" + mime_type + "\r\n\r\n"
				body.append_array(line.to_utf8_buffer())
				body.append_array(FileAccess.get_file_as_bytes(item))
				line = "\r\n"
				body.append_array(line.to_utf8_buffer())
		else:
			line = "--" + boundary + "\r\n"
			body.append_array(line.to_utf8_buffer())
			line = "Content-Disposition: form-data; name=\"" + key + "\"\r\n\r\n"
			body.append_array(line.to_utf8_buffer())
			line = str(value) + "\r\n"
			body.append_array(line.to_utf8_buffer())
	line = "--" + boundary + "--\r\n"
	body.append_array(line.to_utf8_buffer())
	return body
func process_story(story_folder: String, user_id: int, title: String):
	var pages
	var page_names = []
	var page_numbers = []
	var story_dir = "res://Scenes/Levels/"
	var story_path = story_dir + str(story_folder) + "/"
	var dir = DirAccess.open(story_path)
	if dir.dir_exists:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				pass
			else:
				page_names.append(file_name)
			file_name = dir.get_next()
		sort_pages(page_names)
	else:
		print("An error occurred when trying to access the path.")
	for page in page_names:
		var index = page.find(".tscn")
		if index != -1:
			var number_string = page.substr(index - 1, index)
			var number = int(number_string)
			page_numbers.append(number)
		else:
			print("The expected format 'P.tscn' not found in the string.")
	pages = create_pages_arr(page_names, page_numbers, story_path)
	var image_arr = create_image_arr(page_names, story_path)
	print(image_arr)
	upload_story(title, pages, image_arr)
func sort_pages(scenes_array: Array):
	var n = scenes_array.size()
	var page_numbers = []
	for item in scenes_array:
		var index_of_num = (item.find("P")) + 1
		page_numbers.append(item[index_of_num])
	for end in range(n, 1, -1):
		var max_position = 0 
		for i in range(1, end ):
			if page_numbers[i] > page_numbers[max_position]:
				max_position = i
		var temp_num = page_numbers[end - 1]
		var temp_scene = scenes_array[end - 1]
		page_numbers[end -1 ] = page_numbers[max_position]
		scenes_array[end - 1] = scenes_array[max_position]
		page_numbers[max_position] = temp_num
		scenes_array[max_position] = temp_scene
func create_pages_arr(page_names: Array, page_numbers: Array, story_folder_path):
	var pages = []
	for i in range(page_names.size()):
		var scene_name = page_names[i]
		var page_number = page_numbers[i]
		# Load the scene dynamically
		var scene = load_scene(story_folder_path + scene_name)
		if scene != null:
			# Get the text content from the scene's method
			var text_content = get_text_from_scene(scene)       
			if text_content != "":
				# Add the page as a dictionary to the pages array
				var page = {
					"page_number": str(page_number),
					"text_content": str(text_content)
					}
				pages.append(page)
	# Now you have the pages array populated
	print(pages)
	return pages
# Function to load a scene dynamically
func load_scene(scene_path: String) -> Node:
	var scene = load(scene_path)
	if scene:
		return scene.instantiate()  # Instantiate the scene if it's loaded successfully
	else:
		print("Error loading scene: ", scene_path)
		return null
# Function to get the text from the scene (Assuming each scene has a method `get_text_content`)
func get_text_from_scene(scene: Node) -> String:
	if scene.has_method("get_text_content"): # create methods here
		return scene.get_text_content()  # Call the method and return the text
	else:
		print("Scene doesn't have the get_text_content method!")
		return ""
func create_image_arr(page_names, story_folder_path):
	var image_arr = []
	for i in range(page_names.size()):
		var scene_name = page_names[i]
		# Load the scene dynamically
		var scene = load_scene(story_folder_path + scene_name)
		if scene != null:
			# Get the text content from the scene's method
			var image_content = get_image_from_scene(scene)       
			if image_content != null:
				image_arr.append(image_content)
	# Now you have the pages array populated
	return image_arr
func get_image_from_scene(scene: Node):
	if scene.has_method("get_image_content"):
		return scene.get_image_content()
	else:
		print("Scene doesnt have the get_image_content method.")
		return null
func get_extention(string_to_get: String):
	var extention = string_to_get.substr(string_to_get.find(".") + 1).to_lower()
	return extention
