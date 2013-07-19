module ActiveMerchant #:nodoc:
  module Shipping #:nodoc:

    class AddressValidationResponse < Response

      attr_accessor :candidates
      attr_writer :status_code, :valid_address

      class << self

        # Loads hash into an AddressValidationResponse object
        #
        # returns AddressValidationResponse
        def load_response response_hash
          status_code = response_hash['AddressValidationResponse']['Response']['ResponseStatusCode']
          avr = AddressValidationResponse.new status_code == '1', "" # TODO message
          avr.valid_address = response_hash['AddressValidationResponse'].has_key?('ValidAddressIndicator')
          if response_hash['AddressValidationResponse'].has_key?('AmbiguousAddressIndicator')
            candidates = []
            response_candidates = response_hash['AddressValidationResponse']['AddressKeyFormat']
            if response_candidates.kind_of? Hash # there is only one suggestion
              candidates << load_location(response_candidates)
            else # there are multiple suggestions
              response_candidates.each do |candidate|
                candidates << load_location(candidate)
              end
            end
            avr.candidates = candidates
          end
          avr
        end
        
        def load_location candidate_hash
          location = {
            country: candidate_hash['CountryCode'],
            zip: candidate_hash['PostcodePrimaryLow'],
            state: candidate_hash['PoliticalDivision1'],
            city: candidate_hash['PoliticalDivision2']
          }
          addr_line = candidate_hash['AddressLine']
          addresses = addr_line.kind_of?(Array) ? addr_line.each_index.inject({}) do |addrs, i|
            addrs[:"address#{i+1}"] = addr_line[i]
            addrs
          end : { address1: addr_line }
          Location.new(location.merge(addresses))
        end
        private :load_location
      end

      def initialize(success, message, params={}, options={})
        super
        @candidates = []
      end

      def has_valid_address?
        @valid_address
      end

      def eql? obj
        self.state == obj.state
      end
      alias_method :==, :eql?

      def to_s
        "#{success?} and #{has_valid_address?}\n#{candidates}"
      end

    protected
      def state
        [success?, has_valid_address?, candidates.map(&:to_hash)]
      end
    end
  end
end
