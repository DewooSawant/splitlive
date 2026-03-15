class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_EMAIL", "dewoosawant007@gmail.com")
  layout "mailer"
end
