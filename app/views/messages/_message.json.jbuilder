json.extract! message, :id, :channel, :user, :message, :raw, :created_at, :updated_at
json.url message_url(message, format: :json)
