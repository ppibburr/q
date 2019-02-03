Notify.init("My test app")

loop = MainLoop.new()

notification = Notify::Notification.new("Short summary", "A Long description", "dialog-information")

notification.add_action("action-name", "Quit") do |notification, action|
	puts "Bye!"

 	notification.close()

	loop.quit()
end

notification.show()
loop.run()
