module Whatsapp
  class TemplateService
    BASE_URL = "https://graph.facebook.com/v18.0"

    def initialize(account)
      whatsapp_channel = account.inboxes.where(channel_type: 'Channel::Whatsapp')&.last&.channel
      @waba_id = whatsapp_channel.provider_config["business_account_id"] if whatsapp_channel
      @access_token = whatsapp_channel.provider_config["api_key"] if whatsapp_channel
    end

    def list_templates
      url = "#{BASE_URL}/#{@waba_id}/message_templates"
      get(url)
    end

    def create_template(payload)
      url = "#{BASE_URL}/#{@waba_id}/message_templates"
      post(url, payload)
    end

    private

    def headers
      {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/json'
      }
    end

    def get(url)
      response = HTTParty.get(url, headers: headers)
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "GET error: #{e.message}"
      { 'error' => e.message }
    end

    def post(url, payload)
      response = HTTParty.post(url, headers: headers, body: payload.to_json)
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "POST error: #{e.message}"
      { 'error' => e.message }
    end
  end
end
