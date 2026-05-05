-- Script para rellenar la base de datos de la nube con datos iniciales
-- Se ejecuta contra el API local (que conecta al MySQL en la nube)

local http = require('http')
local json = require('json')

local BASE = 'http://localhost:3000'

local function post(path, data, cb)
    local body = json.stringify(data)
    local req = http.request({
        host = 'localhost',
        port = 3000,
        path = path,
        method = 'POST',
        headers = {
            ['Content-Type'] = 'application/json',
            ['Content-Length'] = tostring(#body)
        }
    }, function(res)
        local parts = {}
        res:on('data', function(chunk) table.insert(parts, chunk) end)
        res:on('end', function()
            print('[POST ' .. path .. '] Status: ' .. res.statusCode .. ' -> ' .. table.concat(parts))
            if cb then cb() end
        end)
    end)
    req:finish(body)
end

local function put(path, data, cb)
    local body = json.stringify(data)
    local req = http.request({
        host = 'localhost',
        port = 3000,
        path = path,
        method = 'PUT',
        headers = {
            ['Content-Type'] = 'application/json',
            ['Content-Length'] = tostring(#body)
        }
    }, function(res)
        local parts = {}
        res:on('data', function(chunk) table.insert(parts, chunk) end)
        res:on('end', function()
            print('[PUT ' .. path .. '] Status: ' .. res.statusCode .. ' -> ' .. table.concat(parts))
            if cb then cb() end
        end)
    end)
    req:finish(body)
end

print('=== Sembrando base de datos ===')

-- 1. Configuracion del local
put('/api/configuracion', { nombre_local = 'El Ciber del Vicio', precio_hora = 3.5 }, function()

-- 2. Añadir clientes
post('/api/clientes', { nombre = 'Manolo el Prisas', email = 'manolo@pepe.com' }, function()
post('/api/clientes', { nombre = 'Doña Rogelia',     email = 'rogelia@gmail.com' }, function()

print('=== Semilla completada ===')
end)
end)

end)
