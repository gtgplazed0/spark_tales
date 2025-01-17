extends Node

var rng = RandomNumberGenerator.new()

func generate_salt(length: int = 16) -> String:
	# Generate a random salt of specified length
	var salt = ""
	for i in range(length):
		salt += char(rng.randi_range(33, 126)) # Printable ASCII characters
	return salt

func hash_password(password: String, salt: String) -> String:
	# Initialize hashing context with SHA-256
	var hash_context = HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)

	# Convert the combined password and salt to a PackedByteArray
	var data = PackedByteArray((password + salt).to_utf8_buffer())
	
	# Feed the byte array into the hash
	hash_context.update(data)

	# Generate the hash and convert to hex string
	var hashed_password = hash_context.finish().hex_encode()
	return hashed_password

func create_hashed_password(password: String) -> Dictionary:
	# Generate salt
	var salt = generate_salt()

	# Hash the password with the salt
	var hashed_password = hash_password(password, salt)
	# Return a dictionary with salt and hashed password
	return {
		"salt": salt,
		"hash": hashed_password
	}

func verify_password(input_password: String, stored_salt: String, stored_hash: String) -> bool:
	# Hash the input password with the stored salt
	var input_hash = hash_password(input_password, stored_salt)
	# Check if the newly created hash matches the stored hash
	return input_hash == stored_hash
	
func is_number(character: String) -> bool:
	var code = character.unicode_at(0)
	return code >= 48 and code <= 57

func is_capital_letter(character: String) -> bool:
	var code = character.unicode_at(0)
	return code >= 65 and code <= 90
	
func valid_pass(password: String):
	var pass_has_num = false
	var pass_has_cap = false
	var _valid_pass_var = false
	if password.length() >= 8:
		for character in password:
			if is_number(character):
				pass_has_num = true
			elif is_capital_letter(character):
				pass_has_cap = true
		if pass_has_num and pass_has_cap:
			return true
		else:
			return false
	else:
		return false
