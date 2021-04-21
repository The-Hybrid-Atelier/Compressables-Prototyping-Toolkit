require 'em-websocket'
require 'json'
require 'optparse'
require 'socket'

# DO NOT USE LOCALHOST, BIND TO LOCAL IP
options = {b: "0.0.0.0", p: 3001, v: false}

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-bIP", "--ip=IP", "Bind to IP address") do |v|
    options[:b] = v
  end
  opts.on("-pPORT", "--p=PORT", "Bind to specific port") do |v|
    options[:p] = v
  end
end.parse!


p options


module JSONWebsocket
  attr_accessor :name
  def jsend(msg, sender)
    header = {}
    header["sender"] = sender
    msg = header.merge(msg)
    self.send(msg.to_json)
    #print("Server >> ", msg, "\n")
  end
  def remote_ip
    if self.get_peername
      self.get_peername[2,6].unpack('nC4')[1..4].join('.')
    else
      return nil
    end
  end
end

module EventMachine
  module WebSocket
    class Connection < EventMachine::Connection
      include JSONWebsocket
    end
  end
end


EventMachine.run do
  @channel = EM::Channel.new
  
  # START JSON WEBSOCKET SERVER
  websockets = {}

  EM::WebSocket.start(:host => "0.0.0.0", :port => options[:p], :debug => false) do |ws|
    ws.onopen do |handshake|
      ws.name = ws.remote_ip()
      websockets[ws.signature] = ws
      
      data = {}
      data["sid"] = ws.signature
      data["ip"] = ws.name
      msg = {event: "connection_opened", data: data}
      ws.jsend(msg, "socket-server")
      print "#{websockets.length} Devices Connected\n"
      
      # MULTICAST ONLY JSON-FORMATTED MESSAGES
      ws.onmessage do |msg, data|
        if options[:verbose]
          print "Server << " + msg + "\n"
        end
        begin
          msg = JSON.parse(msg)

          if msg["event"] == "greeting"
            ws.name = msg["name"]
          end
          #if msg["event"] == "server-state"
          if msg.key?("api") and msg["api"]["command"] == "SERVER_STATE"
            msg = {}
            msg["data"] = websockets.map { |sid, ms| ms.name}
            ws.jsend(msg, "socket-server")
          else
            broadcast = websockets.reject { |k, v| [ws.signature].include? k }
            broadcast.each do |sid, ms|
              ms.jsend(msg, ws.name)
            end
          end
        rescue StandardError => bang
          print "Invalid JSON message received #{msg} : #{bang}.\n" 
        end    
      end

      ws.onclose do
        data = {}
        data["sid"] = ws.signature
        data["ip"] = ws.name
        msg = {event: "connection_closed", data: data}
        websockets.delete(ws.signature)
        print "#{websockets.length} Devices Connected\n"
        websockets.each do |sid, ms|
          ms.jsend(msg, "socket-server")
        end  
      end

    end
  end

  # ip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
  ip = "192.168.1.4"
  puts "Server: Started at ws://#{options[:b]}:#{options[:p]} --> #{ip}"
  print "#{websockets.length} Devices Connected\n"
end
