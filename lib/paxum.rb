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
    paxum_api = self.new(email, api_secret)
    paxum_api.pay(options)
  end

  def initialize(email, api_secret)
    @email, @api_secret = email, api_secret
  end

  def pay(options)
    pay_options = {
        to_email: options[:to],
        amount: options[:amount],
        currency: options[:currency],
        note: options[:note]
    }

    api_call('transferFunds', pay_options)
  end

  # Balance Inquiry
  # https://www.paxum.com/payment_docs/page.php?name=apiBalanceInquiry

  def balance(account_id)
    options = {account_id: account_id}
    response = api_call('balanceInquiry', options)

    response["Response"]["Accounts"]["Account"]["Balance"].to_f
  end

  def transaction_history(options)
    params = {
        account_id: options[:account_id],
        from_date: format_date(options[:from_date]),
        to_date: format_date(options[:to_date]),
        page_size: options[:page_size],
        page_number: options[:page_number]
    }

    response = api_call('transactionHistory', params)
    response["Response"]["Transactions"]["Transaction"]
  end

  def api_call(method, options)
    http = Net::HTTP.new(API_HOST, API_PORT)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.post(API_PATH, data_string(method, options), headers)
    check_response response
    Hash.from_xml response.body
  end

  private

  def data_string(method, options = {})
    data_hash = {
        method: method,
        fromEmail: @email
    }
    options.each do |k, v|
      data_hash[k.to_s.camelize(:lower).to_sym] = v
    end
    data_hash[:key] = count_key(*options.values)
    data_hash.reject{|key, value| value.nil? }.map{|key, value| "#{key}=#{value}"}.join('&')
  end

  def headers
    {'Content-Type' => 'application/x-www-form-urlencoded'}
  end

  def count_key(*options)
    str = [@api_secret, *options].join
    Digest::MD5.hexdigest(str)
  end

  def get_response_code(xml)
    hash = Hash.from_xml(xml)
    hash["Response"]["ResponseCode"]
  end

  def format_date(date)
    if date.respond_to? :strftime
      date.strftime('%Y-%m-%d')
    else
      date.to_s
    end
  end

  def check_response(result)
    code = get_response_code result
    raise PaxumException, RESPONSE_CODES[code] unless code == SUCCESS_CODE
  end

end

