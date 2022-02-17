Thread.current[:mqtt_client] = MQTT::Client.connect(
  host: Rails.application.credentials.mqtt[:host], 
  port: Rails.application.credentials.mqtt[:port], 
  username: Rails.application.credentials.mqtt[:user],
  password: Rails.application.credentials.mqtt[:password],
)