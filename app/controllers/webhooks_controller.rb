class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    endpoint_secret = 'whsec_123'
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
        event = Stripe::Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    rescue JSON::ParserError => e
        # Invalid payload
        status 400
        return
    rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        status 400
        return
    end

    # Handle the event
    case event.type
    when 'checkout.session.completed'
      github_username = event.data.object.custom_fields.find { |obj| obj.key = 'githubusername' }.text.value
      github_client = Octokit::Client.new(access_token: 'github_pat_123')
      repo_path = 'yshmarov/invoiceapp'
      github_client.add_collaborator(repo_path, github_username)
    else
      puts "Unhandled event type: #{event.type}"
    end
  end
end