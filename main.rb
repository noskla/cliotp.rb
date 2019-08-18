#!/usr/bin/env ruby
# cliotp is a console cross-platform, user-friendly OTP client/tool
# used to manage secret keys and generate security codes quickly and effectively.
# https://github.com/noskla/cliotp.rb
# This piece of software is licensed under the MIT License.

require 'rotp'     			# https://github.com/mdp/rotp
require 'json'     			# https://github.com/flori/json
require 'inifile'  			
require 'readline' 			
require 'encrypted_strings' # https://github.com/pluginaweek/encrypted_strings
require 'io/console'


# In case you need to override this part.
$CFG_INI_PATH = "./cfg.ini"

# This variable is used to store password
# for the current program session instead of typing it in every time.
$passphrase = ""


def get_from_entries_file (entry_name)
	
	#
	# Requires:
	#		Name		    Format       Description
	#		 'entry_name'   : string     : Unique identificator of an entry containing secret key.
	#
	# Returns array containing:
	#		Name			Format		 Description
	#		 'status'       : boolean    : True if success, otherwise False
	#        'status_mesg'  : string     : Human-readable description of status
	#		 'secret-key'   : string     : Secret key specified under the entry_name ID
	#
	
	File.open($config_file["Main"]["entries_file_path"], "r") do |json_file|
	
		entries = JSON.parse(json_file.read())
		json_file.close()
		
		if not entries.include? entry_name
			
			return {
				"status" => false,
				"status-msg" => "Entry does not exist.",
				"secret-key" => ""
			}
			
		else
		
			begin
				secret_key = entries[entry_name].decrypt(
					:symmetric, :algorithm => "des-ecb", :password => $passphrase
				)
			rescue OpenSSL::Cipher::CipherError
				return {
					"status" => false,
					"status-msg" => "Wrong decryption passphrase.",
					"secret-key" => ""
				}
			end
		
			return {
				"status" => true,
				"status-msg" => "Success.",
				"secret-key" => secret_key
			}
		
		end
	
	end
	
end


def generate_code (entry_name)

	#
	# Requires:
	#		Name		    Format       Description
	#		 'entry_name'   : string     : Unique identificator of an entry containing secret key.
	#
	# Returns array containing:
	#		Name			Format		 Description
	#		 'status'       : boolean    : True if success, otherwise False
	#        'status_mesg'  : string     : Human-readable description of status
	#		 'otp-code'     : string     : Code user can use to verify against secret key.
	#

	return 'test'

end


def add_entry (entry_name, secret_key)

	#
	# Requires:
	#		Name		    Format       Description
	#		 'entry_name'   : string     : Unique identificator of an entry containing secret key.
	#        'secret_key'   : string     : Raw secret key
	#
	# Returns array containing:
	#		Name			Format		 Description
	#		 'status'       : boolean    : True if success, otherwise False
	#        'status_mesg'  : string     : Human-readable description of status
	#

	File.open($config_file["Main"]["entries_file_path"], "a+") do |json_file|
		
		entries = JSON.parse(json_file.read())
		
		if entries.include? entry_name
			json_file.close
			return {"status" => false, "status-msg" => "This entry already exists. Use 'rem' to remove it."}
		end
		
		json_file.truncate(0)
		
		secret_key = secret_key.encrypt(:symmetric, :algorithm => "des-ecb", :password => $passphrase)
		
		entries[entry_name] = secret_key
		json_file.puts(JSON.generate(entries))
		json_file.close
		
	end

	return {'status' => true, 'status-msg' => 'Success.'}

end

# -- -- >> -- -- >> END OF MAIN FUNCTIONS.

def out (message, state)

	#
	# Requires:
	#		Name		    Format       Description
	#		 'message'      : string     : Message to be printed out.
	#		 'state'		: integer    : 0 - Error, 1 - OK, 2 - Warning
	#
	# Returns nothing.
	#
	
	use_bash_colors = $config_file["Main"]["use_bash_colors"]
	
	colors = {
		"reset" => "\e[0m",
		"bold"  => "\e[1m",
		"ok"    => "\e[32m",
		"err"   => "\e[31m",
		"warn"  => "\e[36m"
	}
	
	if not use_bash_colors
	
		puts "==> " + message
	
	else
	
		case state
			
			when 0
				arrow = colors['bold'] + colors['err'] + '==> ' + colors['reset']
				
			when 1
				arrow = colors['bold'] + colors['ok'] + '==> ' + colors['reset']
				
			when 2
				arrow = colors['bold'] + colors['warn'] + '==> ' + colors['reset']
				
			else
				arrow = '==> '
				
		end
		
		puts arrow + message
	
	end

end


# Check if main.rb is being ran directly from file.
# (Ruby equivalent of Python's __name__ == "__main__")
if __FILE__ == $0
	
	puts "", "\t:: cliotp ::", ""
	
	# Load configuration file.
	$config_file = IniFile.load($CFG_INI_PATH)
	
	puts "Please give passphrase used to encrypt/decrypt your entries.",
	"For your security the input is hidden."
	
	print "Encryption passphrase ::> "
	$passphrase = STDIN.noecho(&:gets).chomp; puts
	
	# Print out documentation
	if $config_file["Main"]["use_bash_colors"]
		
		puts "", "Command combinations:"
		puts "\t\e[1m\e[36madd\e[0m <entry-name> <secret-key>"
		puts "\t\e[1m\e[36mgen\e[0m <entry-name>"
		puts "\t\e[1m\e[36mlst\e[0m"
		puts "\t\e[1m\e[36mswitch-colors\e[0m\t# (Linux only)"
		puts "\t\e[1m\e[36mrem\e[0m <entry-name>"
		puts "\t\e[1m\e[36mexit\e[0m", ""
		
	else
	
		puts "", "Command combinations:"
		puts "\tadd <entry-name> <secret-key>"
		puts "\tadd <entry-name> <secret-key>"
		puts "\tgen <entry-name>"
		puts "\tlst"
		puts "\tswitch-colors\t# (Linux only)"
		puts "\trem <entry-name>"
		puts "\texit", ""
	
	end

	# Loop until given_arg starts with "exit"
	while given_arg = Readline.readline(":: ", true)
		
		if given_arg.downcase.start_with?("exit", "quit")
			
			out("Bye bye~!", 1)
			break
			
		end
		
		arguments = given_arg.split(" ")
		
		case arguments.first.downcase
			
			when "add"
				
				entry_name = arguments[1]
				secret_key = arguments[2]
				
				entry_name.nil? ? out("Missing argument.", 0) : nil
				secret_key.nil? ? out("Missing argument.", 0) : nil
				
				response = add_entry(entry_name, secret_key)
				response["status"]? out("Added!", 1) : out(response["status-msg"], 0)
				
			when "gen"
				
				entry_name = arguments[1]
				entry_name.nil? ? out("Missing argument.", 0) : nil
				
				secret_key = get_from_entries_file(entry_name)
				p secret_key
			
			when "lst"
			
			
			when "switch-colors"
			
				$config_file["Main"]["use_bash_colors"] = !$config_file["Main"]["use_bash_colors"]
				$config_file.write()
				out("OK!", 1)
			
			when "rem"
			
			
			else
				out("Unknown command.", 0)
			
		end
		
	end
	
end

