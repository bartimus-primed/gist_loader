import std/httpclient
import std/parseopt
import std/strformat
import std/strutils
import std/uri

var chan: Channel[string]

proc parse_instruction(command: string, location: string, cmd_line: string) =
    case command:
    of "spawn":
        echo("Spawning binary")
        echo(&"downloading from this location {location}")
        echo(&"Spawning with this command line options {cmd_line}")
    else:
        echo("unknown command")

proc help() =
    echo(&"ERROR: --gist=USERNAME/GIST_ID needs to be a Valid HTTP/HTTPS gist endpoint")

var get_instruction = proc(location: string) =
    try:
        var client = newHttpClient()
        var res = getContent(client, location)
        var command = res.split(" ")
        parse_instruction(command[0], command[1], join(command[2..<command.len] , " "))
    except:
        help()

when isMainModule:
    var gist_location: string
    var sleep_time = 5
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
            of "sleep":
                if args.val != "":
                    sleep_time = args.val.parseInt()
        of cmdArgument:
            help()
    if gist_location == "":
        gist_location = default_gist
    get_instruction(gist_location)