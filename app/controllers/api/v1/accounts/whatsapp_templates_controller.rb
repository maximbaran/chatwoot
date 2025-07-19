module Api
  module V1
    module Accounts
      class WhatsappTemplatesController < Api::V1::Accounts::BaseController
        skip_before_action :authenticate_user!

        def index
          service = ::Whatsapp::TemplateService.new(Current.account)
          templates = service.list_templates
          render json: templates['data'] || []
        end

        def create
          service = ::Whatsapp::TemplateService.new(Current.account)
          result = service.create_template(template_payload)
          render json: result
        end

        private

        def template_payload
          params.require(:template).permit(:name, :language, :category, components: [:type, :format, :text, parameters: []])
        end
      end
    end
  end
end
