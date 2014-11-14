require 'bundler'
Bundler.require

require './pi_announce'
require 'rspec'
require 'rack/test'

describe 'Bot Announce' do
  include Rack::Test::Methods

  def app
    PiAnnounce
  end


  it 'returns success when post body is single hash' do
    app.any_instance.should_receive(:play).with('http://www.winhistory.de/more/winstart/mp3/win31.mp3')
    post '/announce', {cmd: 'play', url: 'http://www.winhistory.de/more/winstart/mp3/win31.mp3'}.to_json, { "CONTENT_TYPE" => "application/json" }
    last_response.status.should == 200
  end

  it 'returns success when post body is array of hashes' do
    app.any_instance.should_receive(:play).with('http://www.winhistory.de/more/winstart/mp3/win31.mp3')

    post '/announce', [{cmd: 'play', url: 'http://www.winhistory.de/more/winstart/mp3/win31.mp3'}].to_json, { "CONTENT_TYPE" => "application/json" }
    last_response.status.should == 200
  end

  it 'fails when no valid post body' do
    post '/announce'
    last_response.status.should == 400
  end


  describe '#play' do
    let(:sound_hash) { Digest::MD5.hexdigest(sound) }
    let(:app_instance) { app.new! }

    before do
      app_instance.stub(:system)
    end

    context 'when a mp3 file' do
      let(:sound) { 'http://www.winhistory.de/more/winstart/mp3/win31.mp3' }

      it 'caches it to sound_cache/' do
        app_instance.send(:play, sound)
        expect(File.exists?("#{File.dirname(__FILE__)}/sound_cache/#{sound_hash}.mp3")).to be_true
      end

      it 'plays it with mpg123' do
        expect(app_instance).to receive(:system).with("mpg123 -f 50000 -q \"#{File.dirname(__FILE__)}/sound_cache/#{sound_hash}.mp3\"")
        app_instance.send(:play, sound)
      end
    end

    context 'when a wav file' do
      let(:sound) { 'http://grossgang.com/wav/windows%20sounds/windows95/Utopia%20Open.wav' }

      it 'caches it to sound_cache/' do
        app_instance.send(:play, sound)
        expect(File.exists?("#{File.dirname(__FILE__)}/sound_cache/#{sound_hash}.wav")).to be_true
      end

      it 'plays it with aplay' do
        expect(app_instance).to receive(:system).with("aplay \"#{File.dirname(__FILE__)}/sound_cache/#{sound_hash}.wav\"")
        app_instance.send(:play, sound)
      end
    end
  end

  it 'plays sound from url' do

  end

end
