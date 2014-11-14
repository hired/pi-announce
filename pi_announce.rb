require 'sinatra'
require 'net/http'
require 'shellwords'

class PiAnnounce < Sinatra::Application

  configure do
    set :raise_errors, true
    set :show_exceptions, false
  end

  post '/announce' do
    request.body.rewind
    begin
      json = request.body.read
      request_payload = JSON.parse(json)
    rescue JSON::ParserError
      status 400
      return "Need to provide commands in body in JSON format"
    end

    request_payload = [ request_payload ] if request_payload.is_a? Hash

    unless request_payload.is_a? Array
      status 400
      return "Need to provide commands in body in JSON format"
    end
    request_payload.each do |instruction|
      case instruction['cmd']
      when 'play'
        play instruction['url']
      when 'speak'
        speak instruction['text']
      end
    end

    status 200
  end

private

  def speak(text)
    escaped_text = Shellwords.escape(text)
    system("./speech.sh #{escaped_text}")
  end

  def play(url)
    hash = Digest::MD5.hexdigest(url)
    dir = "#{File.dirname(__FILE__)}/sound_cache"
    FileUtils.mkdir_p(dir)
    filename = "#{dir}/#{hash}"

    if File.exists?("#{filename}.mp3")
      play_local("#{filename}.mp3")
    elsif File.exists?("#{filename}.wav")
      play_local("#{filename}.wav")
    else
      cachedFilename = cache_file(url, filename)
      play_local(cachedFilename) if cachedFilename
    end
  end

  def play_local(filename)
    case File.extname(filename)
    when '.mp3' then
      system("mpg123 -f 50000 -q \"#{filename}\"")
    when '.wav' then
      system("aplay \"#{filename}\"")
    end
  end

  def cache_file(url, file_base)
    uri = URI.parse(url)
    domain = uri.host
    path = uri.path

    Net::HTTP.start(domain) do |http|
      resp = http.get(path)
      type = resp['Content-Type']
      ext = case type
            when 'audio/mpeg', 'audio/mpeg3','audio/x-mpeg-3' then '.mp3'
            when 'audio/wav', 'audio/wave', 'audio/x-wav' then '.wav'
            when 'audio/midi', 'audio/x-midi', 'application/x-midi', 'audio/x-mid' then '.mid'
            end

      open("#{file_base}#{ext}", "wb") do |file|
        file.write(resp.body)
      end

      return "#{file_base}#{ext}"
    end

  end
end
