require 'json'
require 'jwt'
require 'sinatra/base'
require 'date'

class JwtAuth

    def initialize app
      @app = app
    end
  
    def call env
      begin
        options = { algorithm: 'HS256', iss: 'DSSD' }
        bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
        payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options 
        env[:user] = payload['user']
  
        @app.call env
      rescue JWT::ExpiredSignature
        [403, { 'Content-Type' => 'text/plain' }, ['El token expiró.']]
      rescue JWT::InvalidIssuerError
        [403, { 'Content-Type' => 'text/plain' }, ['El token no tienen un emisor válido.']]
      rescue JWT::InvalidIatError
        [403, { 'Content-Type' => 'text/plain' }, ['El token no tiene un tiempo de emisión válido.']]
      rescue JWT::DecodeError
        [401, { 'Content-Type' => 'text/plain' }, ['Se tiene que enviar un token.']]
      end
    end
  
  end

class Api < Sinatra::Base

    use JwtAuth
    
    def initialize
      super
      @locations = ['Amsterdam', 'Paris', 'Barcelona', 'Bogotá', 'Lima', 'Londres', 'Montevideo', 'Kioto', 'Seúl', 'El Cairo', 'Dakar']
    end
    
    post '/search' do
      start_date = params[:start_date]
      days = params[:days]
      caso = params[:caso].to_i
      if start_date.nil? && days.nil?
        return 'No se envió la fecha a buscar y la cantidad de días'
      end
      if start_date.nil?
        return 'No se envió la fecha a buscar'
      end
      if days.nil?
        return 'No se envió la cantidad de días'
      end
      days = params[:days].to_i
      start_date = Date.strptime(start_date, '%d-%m-%Y')
      if days < 1
        return 'La cantidad de días debe ser un número positivo'
      end
      if start_date < Date.today
        return 'La fecha a buscar debe ser mayor al día de hoy'       
      end
      hash = {}
      ids = []
      caso
      locaciones = @locations.sample(6)
      case caso
      when 1 #Quiero una sola locación para esa fecha
        hash [rand(9999)] = @locations.sample
      when 2 #Quiero n locaciones, n > 1, para esa fecha
        cantidad = rand(2..5)
        for i in 0...cantidad do
          hash [rand(9999)] = locaciones[i]
        end
      else #Quiero que no haya locaciones para esa fecha y envié n locaciones, mas cercanas a esa fecha
        cantidad = rand 2..5
        days = rand 2..30
        for i in 1..cantidad 
          ids << rand(9999)
        end
        ids.sort!
        hash['fecha'] = start_date.next_day(days)
        for i in 0...cantidad do
          hash [ids[i].to_s] = locaciones[i]
        end
      end
      hash.to_json
    end
      
    post '/reserve' do
      id = params[:id]
      if id.nil?
        return 'No se envió el id de la reserva'
      end
      id = id.to_i
      if id < 1
        return 'No se puede realizar una reserva con ese id'
      end
      "Se realizó la reserva con identificador: #{id}"  
    end

    post '/cancel' do
      id = params[:id]
      if id.nil?
        return 'No se envió el id de la reserva a cancelar'
      end
      id = id.to_i
      if id < 1
        return 'No existe una reserva para ese id'
      end
      "Se canceló la reserva con identificador: #{id}"  
    end

    not_found do
      'Uso incorrecto de la API, ingresa en: URL para ver la documentación'
    end
  
  end
  
  class Public < Sinatra::Base
  
    def initialize
      super
  
      @logins = {
        "susana.garcia": 'bpm',
        test: 'test'
      }
    end

    post '/login' do
      username = params[:username]
      password = params[:password]
      if username.nil? || password.nil?
        'No se envió el usuario o la contraseña'  
      else  
        if @logins[username.to_sym] == password
          content_type :json
          { token: token(username) }.to_json
        else
          [401, { 'Content-Type' => 'text/plain' }, 'Usuario o contraseña no válidos.']
        end
      end
    end
  
    not_found do
      'Uso incorrecto de la API, ingresa en: URL para ver la documentación'
    end
  
    private

    def token username
      JWT.encode payload(username), ENV['JWT_SECRET'], 'HS256'
    end
    
    def payload username
      {
        exp: Time.now.to_i + 7500,
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        user: {
          username: username
        }
      }
    end
  
  end