require 'net/http'
require 'net/https'
require "paxum/exception"

class Paxum
  SUCCESS_CODE = "00"
  RESPONSE_CODES = {
    "03" => "invalid_merchant",
    "30" => "format_error",
    "51" => "not_enough_funds",
    "52" => "single_transaction_limit_amount_exceeded",
    "53" => "daily_transaction_limit_amount_exceeded",
    "54" => "monthly_transaction_limit_amount_exceeded",
    "55" => "incorrect_pin",
    "56" => "daily_transaction_limit_number_exceeded",
    "57" => "monthly_transaction_limit_number_exceeded",
    "58" => "transaction_not_permitted",
    "66" => "api_method_disabled",
    "IP" => "invalid_payee",
    "IA" => "invalid_account_id",
    "IT" => "invalid_transaction_id",
    "IM" => "invalid_method_name",
    "IS" => "invalid_subscription_id",
    "P5" => "currency_conversion_error",
    "83" => "cancel_subscription_failed",
    "88" => "file_upload_failed",
    "89" => "request_money_failed",
    "99" => "not_implemented_yet",
    "UA" => "unverified_account"
  }

  def self.transfer_funds(email, api_secret, options)
    paxum_api = self.new(email, api_secret, options)
    paxum_api.pay
  end

  def initialize(email, api_secret, options)
    @email, @api_secret, @options = email, api_secret, options
  end

  def pay
    http = Net::HTTP.new('www.paxum.com', 443)
    http.use_ssl = true
    path = '/payment/api/paymentAPI.php'
    result = http.post(path, data_string, headers)

    code = get_response_code(result.body)
    if code == SUCCESS_CODE
      true
    else
      raise PaxumException, RESPONSE_CODES[code]
    end
  end

  private

  def prepare_data_hash
    paxum_currency_code = @options[:currency]
    paxum_id_to = @options[:to]
    paxum_id_from = @options[:from]
    sum = @options[:amount]
    id = @options[:id]
    domain = @options[:domain]

    {
      'method' => 'transferFunds',
      'fromEmail' => paxum_id_from,
      'toEmail' => paxum_id_to,
      'amount' => sum,
      'currency' => paxum_currency_code,
      'note' => "#{id} #{domain}",
      'key' => count_key(@api_secret, paxum_id_to, sum, paxum_currency_code, "#{id} #{domain}")
    }
  end

  def data_string
    data_hash = prepare_data_hash
    "method=#{data_hash['method']}&note=#{data_hash['note']}&fromEmail=#{data_hash['fromEmail']}&toEmail=#{data_hash['toEmail']}&amount=#{data_hash['amount']}&currency=#{data_hash['currency']}&key=#{data_hash['key']}&sandbox=#{data_hash['sandbox']}&return=#{data_hash['return']}"
  end

  def headers
    {'Content-Type' => 'application/x-www-form-urlencoded'}
  end

  def count_key(*options)
    str = ""
    options.each { |arg| str << arg.to_s }
    Digest::MD5.hexdigest(str)
  end

  def get_response_code(xml)
    hash = Hash.from_xml(xml)
    hash["Response"]["ResponseCode"]
  end

end

