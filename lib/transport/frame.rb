
#:stopdoc:
# this file was autogenerated on Thu May 14 19:20:30 +0100 2009
#
# DO NOT EDIT! (edit ext/qparser.rb and config.yml instead, and run 'ruby qparser.rb')

module Qrack
  module Transport
    class Frame
      def self.types
        @types ||= {}
      end

      def self.Frame id
        (@_base_frames ||= {})[id] ||= Class.new(Frame) do
          class_eval %[
            def self.inherited klass
              klass.const_set(:ID, #{id})
              Frame.types[#{id}] = klass
            end
          ]
        end
      end

      class Method    < Frame( 1 ); end
      class Header    < Frame( 2 ); end
      class Body      < Frame( 3 ); end
      class OobMethod < Frame( 4 ); end
      class OobHeader < Frame( 5 ); end
      class OobBody   < Frame( 6 ); end
      class Trace     < Frame( 7 ); end
      class Heartbeat < Frame( 8 ); end

      FOOTER = 206
    end
  end
end

module Qrack
  module Transport
    class Frame
      def initialize payload = nil, channel = 0
        @channel, @payload = channel, payload
      end
      attr_accessor :channel, :payload

      def id
        self.class::ID
      end
  
      def to_binary
        buf = Transport::Buffer.new
        buf.write :octet, id
        buf.write :short, channel
        buf.write :longstr, payload
        buf.write :octet, Transport::Frame::FOOTER
        buf.rewind
        buf
      end

      def to_s
        to_binary.to_s
      end

      def == frame
        [ :id, :channel, :payload ].inject(true) do |eql, field|
          eql and __send__(field) == frame.__send__(field)
        end
      end
  
      class Method
        def initialize payload = nil, channel = 0
          super
          unless @payload.is_a? Protocol::Class::Method or @payload.nil?
            @payload = Protocol.parse(@payload)
          end
        end
      end

      class Header
        def initialize payload = nil, channel = 0
          super
          unless @payload.is_a? Protocol::Header or @payload.nil?
            @payload = Protocol::Header.new(@payload)
          end
        end
      end

      class Body; end

      def self.parse buf
        buf = Transport::Buffer.new(buf) unless buf.is_a? Transport::Buffer
        buf.extract do
          id, channel, payload, footer = buf.read(:octet, :short, :longstr, :octet)
          Transport::Frame.types[id].new(payload, channel) if footer == Transport::Frame::FOOTER
        end
      end
    end
  end
end
