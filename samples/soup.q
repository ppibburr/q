def main(args:string[])
  url     = args[1] != nil ? args[1] : "http://google.com"
  session = Soup::Session.new()
  msg     = Soup::Message.new("GET", url)
  
  session.send_message(msg)
  stdout.write(msg.response_body.data)
end
