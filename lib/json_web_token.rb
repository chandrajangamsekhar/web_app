require 'jwt'
    class JsonWebToken
      
      # Decodes the JWT with the signed secret
      def self.decode(token)
        JWT.decode(token, $api_key_base)
      end

      # Validates the payload hash for expiration and meta claims
      def self.valid_payload(payload)
        if expired(payload) || payload['iss'] != meta[:iss] || payload['aud'] != meta[:aud]
          return false
        else
          return true
        end
      end

      # Default options to be encoded in the token
      def self.meta
        {
          exp: 7.days.from_now.to_i,
          iss: $issuer_name,
          aud: $client
        }
      end
      
      # Validates if the token is expired by exp parameter
      def self.expired(payload)
        Time.at(payload['exp']) < Time.now
      end

      def self.encryptPayload(payload)
        crypt = ActiveSupport::MessageEncryptor.new(hex_to_bin($crypto_key))
        return crypt.encrypt_and_sign(payload)
      end

      def self.decryptPayload(payload)
        crypt = ActiveSupport::MessageEncryptor.new(hex_to_bin($crypto_key))
        return crypt.decrypt_and_verify(payload)
      end

      def self.hex_to_bin(s)
        s.scan(/../).map { |x| x.hex.chr }.join
      end

    end