require 'net/http'
require 'net/https'
require "paxum/exception"

class Paxum
  API_PATH = '/payment/api/paymentAPI.php'
  API_HOST = 'www.paxum.com'
  API_PORT = '443'

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

  attr_accessor :options

  def initialize(email, api_secret, options = {})
    @email, @api_secret, @options = email, api_secret, options
  end

  def pay
    code = get_response_code(api_call_result('transferFunds').body)
    if code == SUCCESS_CODE
      true
    else
      raise PaxumException, RESPONSE_CODES[code]
    end
  end

  def balance(currency = 'usd')
    result = api_call_result('balanceInquiry').body

    code = get_response_code result
    raise PaxumException, RESPONSE_CODES[code] unless code == SUCCESS_CODE

    response_hash = Hash.from_xml result
    value = 0
    response_hash["Response"]["Accounts"]["Account"].each do |account|
      value = account["Balance"] if account["Currency"] == currency
    end
    value.to_f
  end

  private

  def api_call_result(method)
    http = Net::HTTP.new(API_HOST, API_PORT)
    http.use_ssl = true
    http.post(API_PATH, data_string(method), headers)
  end

  def data_string(method)
    data_hash = {
        method: method,
        fromEmail: @email,
        toEmail: options[:to],
        amount: options[:amount],
        currency: options[:currency],
        note: options[:note],
        key: count_key(*options.values)
    }
    data_hash.map{|key, value| "#{key}=#{value}"}.jpin('&')
  end

  def headers
    {'Content-Type' => 'application/x-www-form-urlencoded'}
  end

  def count_key(*options)
    str = @api_secret
    options.each { |arg| str << arg.to_s }
    Digest::MD5.hexdigest(str)
  end

  def get_response_code(xml)
    hash = Hash.from_xml(xml)
    hash["Response"]["ResponseCode"]
  end

end

