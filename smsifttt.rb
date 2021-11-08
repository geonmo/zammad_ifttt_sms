class Channel::Driver::Sms::Smsifttt
  NAME = 'sms/smsifttt'.freeze

  def fetchable?(_channel)
    false
  end

  def send(options, attr, _notification = false) 
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"
    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending Coolsms to #{attr[:recipient]}"
    begin
      if Setting.get('developer_mode') != true
        uri = get_uri(options, attr)
        messages = {  
                      :value1   => attr[:recipient],
                      :value2   => options[:sender], 
                      :value3   => attr[:message],
                   }
              
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        
        req.body = messages.to_json
        res = http.request(req)
        response = JSON.parse(res.body)
        statusCode = response["status"]
        if !statusCode == 'COMPLETE' && !statusCode = 'SENDING'
          message = "Received non-OK response from gateway URL '#{uri}'"
          Rails.logger.error "#{message}:"
          raise message
        end
      end

      true
    rescue => e
      message = "Error while performing request to gateway URL '#{uri}'"
      Rails.logger.error message
      Rails.logger.error e
      raise message
    end
  end

  def self.definition
    {
      name:         'smsifttt',
      adapter:      'sms/smsifttt',
      notification: [
        { name: 'options::gateway', display: 'Gateway', tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'https://maker.ifttt.com',default:'https://maker.ifttt.com' },
        { name: 'options::eventname', display: 'Event Name', tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'ifttt_webhook_eventname' },
        { name: 'options::token', display: 'Sender', tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXXXXXX' },
      ]
    }
  end

  private

  def get_uri(options, attr)
    str = options[:gateway] + '/'+options::eventname+'/with/key/'+options::token
    uri = URI(str)
    return uri
  end

end
