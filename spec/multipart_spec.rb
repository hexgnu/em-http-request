require 'spec/helper'
require 'spec/stallion'
require 'spec/stub_server'

describe EventMachine::HttpRequest do
  it 'should be able to submit both a file and body at the same time' do
    EventMachine.run {
      payload = {:file => File.open("/Users/matthewkirk/Desktop/familytree.txt", "r+"), :body => {"helloworld" => %w[fooba], "abazaba" => "asdf"}}
      expectation = {"file" => File.open("/Users/matthewkirk/Desktop/familytree.txt", "r+"), "helloworld" => {"0" => "fooba"}, "abazaba" => "asdf"}
      http = EventMachine::HttpRequest.new('http://localhost:4567/test_multipart').post(payload)
      http.callback { 
        response = eval(http.response)
        response.should == expectation
        EventMachine.stop
      }
      http.errback {
        raise "ection"
        EventMachine.stop
      }
    }
  end
end