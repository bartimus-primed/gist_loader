import std/httpclient
import std/parseopt
import std/strformat
import std/uri

proc parse_instruction(command: string) =
  case command:
  of "homedir":
    echo("Getting user home directory")
  of "systemdir":
    echo("Getting system directory")
  of "spawn":
    echo("Spawning pneuma")
  else:
    echo("unknown command")

proc help() =
  echo(&"ERROR: --gist=USERNAME/GIST_ID needs to be a Valid HTTP/HTTPS gist endpoint")

proc get_instruction(location: string) =
  try:
    var client = newHttpClient()
    var res = getContent(client, location)
    echo(res)
    parse_instruction(res)
  except:
    help()

when isMainModule:
  var gist_location: string
  var default_gist = "https://gist.githubusercontent.com/bartimus-primed/4042ba41ec3a4b30633f0395874363f3/raw"
  var args = initOptParser("")
  while true:
    args.next()
    case args.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case args.key
      of "gist":
        if args.val != "":
          var endpoint = "https://gist.githubusercontent.com/"
          endpoint.add(args.val)
          endpoint.add("/raw")
          gist_location = endpoint
    of cmdArgument:
      help()
  if gist_location == "":
    gist_location = default_gist  
  echo(gist_location)
  get_instruction(gist_location)