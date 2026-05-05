--[[====================================================================
             ¡Comentarios!
Este es el backend no sabia otro idioma de programacion asi que use lua,
Asi que tampoco hay mucha documentacion que otorgar como mucho la de Luvit que es lo que me permite compilar el script y hacer q funcione como pagina web
https://luvit.io/docs.html
--====================================================================]]

local http = require('http')
local fs = require('fs')
local json = require('json')
local mysql = require('./deps/mysql') -- Usamos nuestro helper local

-- =====================================================================
-- 0. CARGAR VARIABLES DE ENTORNO (.env)
-- =====================================================================
local function cargar_env()
    local contenido = fs.readFileSync('backend/.env')
    local env = {}
    if contenido then
        for linea in contenido:gmatch("[^\r\n]+") do
            if not linea:match("^#") then
                local llave, valor = linea:match("^([^=]+)=(.*)$")
                if llave then
                    env[llave:gsub("%s+", "")] = valor:gsub("%s+", "")
                end
            end
        end
    end
    return env
end

local env = cargar_env()
local PUERTO = tonumber(env.PORT) or 3000

-- Configuración de MySQL
local db_config = {
    host = env.DB_HOST or "localhost",
    user = env.DB_USER or "root",
    password = env.DB_PASS or "",
    database = env.DB_NAME or "cibercafe_db"
}

-- Crear cliente de base de datos
local db = mysql.createClient(db_config)

-- =====================================================================
-- 1. FUNCIONES PARA LA BASE DE DATOS
-- =====================================================================

-- Esta funcion lee información de la base de datos
local function leer_de_bd(consulta_sql, callback)
    db:query(consulta_sql, function(err, resultados)
        if err then
            print("Error SQL: " .. tostring(err))
            if callback then callback({}) end
            return
        end
        if callback then callback(resultados) end
    end)
end

-- Esta función es para buscar un dato en concreto
local function leer_un_solo_dato(consulta_sql, callback)
    leer_de_bd(consulta_sql, function(resultados)
        if callback then callback(resultados and resultados[1]) end
    end)
end

-- Esta función es para insertar, actualizar o borrar datos
local function escribir_en_bd(consulta_sql, callback)
    db:query(consulta_sql, function(err, info)
        if err then print("Error SQL (escribir): " .. tostring(err)) end
        if callback then callback(info) end
    end)
end

-- =====================================================================
-- 2. FUNCIONES DE AYUDA PARA LA WEB
-- =====================================================================

-- Función para enviarle información a la página en formato JSON
local function enviar_json(respuesta, codigo_estado, datos)
    local texto_json = json.stringify(datos)
    respuesta:writeHead(codigo_estado, {
        ["Content-Type"] = "application/json; charset=utf-8",
        ["Access-Control-Allow-Origin"] = "*",
        ["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS",
        ["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    })
    respuesta:finish(texto_json)
end

-- Funcion para dar archivos de la carpeta (html, css, mp3...) al navegador
local function enviar_archivo(respuesta, ruta_archivo)
    local ruta_real = "./" .. ruta_archivo
    
    fs.readFile(ruta_real, function(error, contenido)
        if error then
            respuesta:writeHead(404)
            respuesta:finish("404: Archivo no encontrado")
        else
            -- Si el archivo acaba en css, le decimos que es estilo CSS
            if ruta_archivo:match("%.css$") then
                respuesta:setHeader("Content-Type", "text/css")
            end
            respuesta:writeHead(200)
            respuesta:finish(contenido)
        end
    end)
end

-- =====================================================================
-- 3. RUTAS DE LA API
-- =====================================================================

local function procesar_peticion_api(peticion, respuesta, cuerpo_texto)
    local url = peticion.url
    local metodo = peticion.method

    -- Para enviar errores JSON mejor organizado
    local function enviar_error(mensaje)
        return enviar_json(respuesta, 400, { message = mensaje })
    end

    -- ==== LOGIN ====
    if url == "/api/auth/login" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        if not bien then return enviar_error("Datos malos") end
        
        local sql = "SELECT * FROM usuarios WHERE email = '" .. datos.email .. "' AND password = '" .. datos.password .. "'"
        leer_un_solo_dato(sql, function(usuario)
            if usuario then
                enviar_json(respuesta, 200, { message = "Logeado", user = usuario })
            else
                enviar_json(respuesta, 401, { message = "Email o contraseña mal" })
            end
        end)

    -- ==== REGISTRO ====
    elseif url == "/api/auth/register" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        if not bien then return enviar_error("Datos malos") end
        
        local sql_comprobar = "SELECT id FROM usuarios WHERE email = '" .. datos.email .. "'"
        leer_un_solo_dato(sql_comprobar, function(ya_existe)
            if ya_existe then
                enviar_json(respuesta, 409, { message = "Ese email ya está usado" })
            else
                local sql_insertar = string.format(
                    "INSERT INTO usuarios (nombre, email, telefono, password, fecha_nacimiento) VALUES ('%s', '%s', '%s', '%s', '%s')",
                    datos.name or "", datos.email, datos.phone or "", datos.password, datos.birthdate or "2000-01-01"
                )
                escribir_en_bd(sql_insertar, function()
                    enviar_json(respuesta, 200, { message = "Usuario registrado" })
                end)
            end
        end)

    -- ==== RECUPERAR CONTRASEÑA (SIMULADO) ====
    elseif url == "/api/auth/recover" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        -- Simplemente comprobamos si el telefono existe
        local sql = "SELECT id FROM usuarios WHERE telefono = '" .. (datos.phone or "") .. "'"
        leer_un_solo_dato(sql, function(usuario)
            if usuario then
                enviar_json(respuesta, 200, { message = "Código enviado (simulado)" })
            else
                enviar_error("Teléfono no encontrado")
            end
        end)

    -- ==== RESETEAR CONTRASEÑA ====
    elseif url == "/api/auth/reset" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        local sql = "UPDATE usuarios SET password = '" .. datos.password .. "' WHERE telefono = '" .. (datos.phone or "") .. "'"
        escribir_en_bd(sql, function()
            enviar_json(respuesta, 200, { message = "Contraseña actualizada" })
        end)

    -- ==== PERFIL ====
    elseif url:match("/api/perfil/([^/]+)") and metodo == "GET" then
        local email = url:match("/api/perfil/([^/]+)")
        leer_un_solo_dato("SELECT id, nombre, email, telefono, puntos, fecha_nacimiento FROM usuarios WHERE email = '" .. email .. "'", function(usuario)
            if usuario then
                enviar_json(respuesta, 200, { user = usuario })
            else
                enviar_error("Usuario no encontrado")
            end
        end)

    -- ==== EQUIPOS (LISTAR) ====
    elseif url == "/api/equipos" and metodo == "GET" then
        local sql_consulta = [[
            SELECT equipos.*, (SELECT precio_hora FROM configuracion LIMIT 1) as precio_base,
            CASE 
                WHEN estado = 'Ocupado' AND hora_inicio IS NOT NULL 
                THEN (TIMESTAMPDIFF(SECOND, hora_inicio, NOW()) / 3600) * (SELECT precio_hora FROM configuracion LIMIT 1)
                ELSE 0 
            END as cobro_actual 
            FROM equipos
        ]]
        leer_de_bd(sql_consulta, function(equipos)
            enviar_json(respuesta, 200, { equipos = equipos })
        end)

    -- ==== EQUIPOS (CAMBIAR ESTADO) ====
    elseif url:match("/api/equipos/%d+/toggle") and metodo == "PUT" then
        local id_equipo = url:match("/api/equipos/(%d+)/toggle")
        
        leer_un_solo_dato("SELECT * FROM equipos WHERE id = " .. id_equipo, function(equipo)
            if equipo then
                local nuevo_estado
                local query
                if equipo.estado == "Libre" then 
                    nuevo_estado = "Ocupado"
                    query = "UPDATE equipos SET estado = 'Ocupado', hora_inicio = NOW() WHERE id = " .. id_equipo
                elseif equipo.estado == "Ocupado" then 
                    nuevo_estado = "Reservado"
                    query = "UPDATE equipos SET estado = 'Reservado', hora_inicio = NULL WHERE id = " .. id_equipo
                else
                    nuevo_estado = "Libre"
                    query = "UPDATE equipos SET estado = 'Libre', hora_inicio = NULL WHERE id = " .. id_equipo
                end
                
                escribir_en_bd(query, function()
                    enviar_json(respuesta, 200, { nuevo_estado = nuevo_estado, message = "Cambiado a " .. nuevo_estado })
                end)
            else
                enviar_json(respuesta, 404, { message = "No existe ese PC" })
            end
        end)

    -- ==== EQUIPOS (OBTENER UNO) ====
    elseif url:match("/api/equipos/(%d+)$") and metodo == "GET" then
        local id_equipo = url:match("/api/equipos/(%d+)$")
        leer_un_solo_dato("SELECT * FROM equipos WHERE id = " .. id_equipo, function(equipo)
            if equipo then
                enviar_json(respuesta, 200, { equipo = equipo })
            else
                enviar_json(respuesta, 404, { message = "No existe ese PC" })
            end
        end)

    -- ==== CLIENTES (LISTAR PARA PANEL) ====
    elseif url == "/api/clientes" and metodo == "GET" then
        leer_de_bd("SELECT * FROM usuarios WHERE rol = 'cliente'", function(clientes)
            enviar_json(respuesta, 200, { clientes = clientes })
        end)

    -- ==== CLIENTES (AÑADIR DESDE PANEL) ====
    elseif url == "/api/clientes" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        leer_un_solo_dato("SELECT id FROM usuarios WHERE email = '" .. datos.email .. "'", function(comprobar)
            if comprobar then
                enviar_error("El correo ya existe")
            else
                escribir_en_bd("INSERT INTO usuarios (nombre, email, password, rol) VALUES ('" .. datos.nombre .. "', '" .. datos.email .. "', '123', 'cliente')", function()
                    enviar_json(respuesta, 200, { message = "Cliente creado" })
                end)
            end
        end)

    -- ==== CLIENTES (AÑADIR PUNTOS) ====
    elseif url:match("/api/clientes/%d+/puntos") and metodo == "PUT" then
        local id_usuario = url:match("/api/clientes/(%d+)/puntos")
        local bien, datos = pcall(json.parse, cuerpo_texto)
        leer_un_solo_dato("SELECT puntos FROM usuarios WHERE id = " .. id_usuario, function(usuario)
            if usuario then
                local puntos_nuevos = usuario.puntos + (datos.puntos or 0)
                escribir_en_bd("UPDATE usuarios SET puntos = " .. puntos_nuevos .. " WHERE id = " .. id_usuario, function()
                    enviar_json(respuesta, 200, { puntos = puntos_nuevos, message = "Puntos actualizados" })
                end)
            else
                enviar_error("Usuario no encontrado")
            end
        end)

    -- ==== CLIENTES (ELIMINAR) ====
    elseif url:match("/api/clientes/%d+") and metodo == "DELETE" then
        local id_usuario = url:match("/api/clientes/(%d+)")
        escribir_en_bd("DELETE FROM usuarios WHERE id = " .. id_usuario, function()
            enviar_json(respuesta, 200, { message = "Usuario eliminado" })
        end)

    -- ==== EQUIPOS LIBRES (PARA APP) ====
    elseif url == "/api/equipos/libres" and metodo == "GET" then
        leer_de_bd("SELECT id, nombre FROM equipos WHERE estado = 'Libre'", function(equipos)
            enviar_json(respuesta, 200, { equipos = equipos })
        end)

    -- ==== RESERVAS (CREAR) ====
    elseif url == "/api/reservas" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        if not bien or not datos then return enviar_error("Datos JSON inválidos") end
        
        local id_equipo = datos.equipo_id
        local id_usuario = datos.usuario_id or 1
        local fecha_reserva = datos.date or os.date("%Y-%m-%d")
        local hora_reserva = datos.time or os.date("%H:%M:%S")
        
        print(string.format("Intentando reserva: User %s, PC %s, Fecha %s, Hora %s", id_usuario, id_equipo, fecha_reserva, hora_reserva))
        
        leer_un_solo_dato("SELECT estado FROM equipos WHERE id = " .. id_equipo, function(equipo)
            if not equipo then
                print("Error: El PC " .. id_equipo .. " no existe")
                return enviar_error("El equipo no existe")
            end
            
            print("Estado actual del PC " .. id_equipo .. ": " .. equipo.estado)
            
            -- Comprobar si ya hay una reserva activa de ESTE USUARIO (no puede tener más de una activa a la vez)
            local sql_check = string.format(
                "SELECT id FROM reservas WHERE usuario_id = %d AND activa = 1",
                id_usuario
            )
            leer_un_solo_dato(sql_check, function(reserva_existente)
                if reserva_existente then
                    return enviar_error("Ya tienes una reserva activa. Cancélala o espera a que se complete antes de hacer otra.")
                end
                
                -- Comprobar si el equipo ya tiene una reserva activa para esa misma fecha/hora
                local sql_conflicto = string.format(
                    "SELECT id FROM reservas WHERE equipo_id = %d AND fecha = '%s' AND hora = '%s' AND activa = 1",
                    id_equipo, fecha_reserva, hora_reserva
                )
                leer_un_solo_dato(sql_conflicto, function(conflicto)
                    if conflicto then
                        return enviar_error("Ese PC ya tiene una reserva para esa fecha y hora")
                    end
                    
                    local pin = math.random(1000, 9999) 
                    local query = string.format(
                        "INSERT INTO reservas (usuario_id, equipo_id, pin, fecha, hora, activa) VALUES (%d, %d, '%s', '%s', '%s', 1)",
                        id_usuario, id_equipo, pin, fecha_reserva, hora_reserva
                    )
                    escribir_en_bd(query, function()
                        print("Reserva insertada en BD para PC " .. id_equipo)
                        -- Solo cambiar a Reservado si el equipo está Libre
                        if equipo.estado == "Libre" then
                            print("Cambiando estado de PC " .. id_equipo .. " a Reservado...")
                            escribir_en_bd("UPDATE equipos SET estado = 'Reservado' WHERE id = " .. id_equipo, function()
                                enviar_json(respuesta, 200, { pin = pin, message = "Reserva hecha! Tu PIN es " .. pin })
                            end)
                        else
                            print("PC " .. id_equipo .. " no estaba Libre (estado: " .. equipo.estado .. "), no se cambia a Reservado")
                            enviar_json(respuesta, 200, { pin = pin, message = "Reserva hecha! Tu PIN es " .. pin })
                        end
                    end)
                end)
            end)
        end)

    -- ==== RESERVAS (CANCELAR) ====
    elseif url:match("/api/reservas/(%d+)") and metodo == "DELETE" then
        local id_reserva = url:match("/api/reservas/(%d+)")
        leer_un_solo_dato("SELECT equipo_id, activa FROM reservas WHERE id = " .. id_reserva, function(reserva)
            if reserva then
                -- Marcar la reserva como inactiva (no borrar, para historial)
                escribir_en_bd("UPDATE reservas SET activa = 0 WHERE id = " .. id_reserva, function()
                    -- Solo liberar el equipo si no tiene otras reservas activas
                    local sql_otras = "SELECT id FROM reservas WHERE equipo_id = " .. reserva.equipo_id .. " AND activa = 1 AND id != " .. id_reserva
                    leer_un_solo_dato(sql_otras, function(otra)
                        if not otra then
                            escribir_en_bd("UPDATE equipos SET estado = 'Libre', hora_inicio = NULL WHERE id = " .. reserva.equipo_id .. " AND estado = 'Reservado'", function()
                                enviar_json(respuesta, 200, { message = "Reserva cancelada" })
                            end)
                        else
                            enviar_json(respuesta, 200, { message = "Reserva cancelada" })
                        end
                    end)
                end)
            else
                enviar_error("Reserva no encontrada")
            end
        end)

    -- ==== MIS RESERVAS (APP) ====
    elseif url:match("/api/mis%-reservas/([^/]+)") and metodo == "GET" then
        local email = url:match("/api/mis%-reservas/([^/]+)")
        local sql = [[
            SELECT reservas.*, equipos.nombre as equipo_nombre 
            FROM reservas 
            INNER JOIN usuarios ON reservas.usuario_id = usuarios.id 
            INNER JOIN equipos ON reservas.equipo_id = equipos.id 
            WHERE usuarios.email = ']] .. email .. [['
            ORDER BY created_at DESC
        ]]
        leer_de_bd(sql, function(reservas)
            enviar_json(respuesta, 200, { reservas = reservas })
        end)

    -- ==== VALIDAR RESERVA (CLIENTE PC) ====
    elseif url == "/api/reservas/validar" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        local sql = "SELECT * FROM reservas WHERE pin = '" .. (datos.pin or "") .. "' AND activa = 1"
        leer_un_solo_dato(sql, function(reserva)
            if reserva then
                escribir_en_bd("UPDATE equipos SET estado = 'Ocupado', hora_inicio = NOW() WHERE id = " .. reserva.equipo_id, function()
                    escribir_en_bd("UPDATE reservas SET activa = 0, usada = 1 WHERE id = " .. reserva.id, function()
                        enviar_json(respuesta, 200, {
                            message = "Acceso concedido",
                            equipo_id = reserva.equipo_id,
                            reserva_id = reserva.id
                        })
                    end)
                end)
            else
                enviar_json(respuesta, 401, { message = "PIN inválido" })
            end
        end)

    -- ==== LIBERAR EQUIPO (CLIENTE PC al cerrar) ====
    elseif url == "/api/reservas/liberar" and metodo == "POST" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        local id_equipo = datos.equipo_id
        if not id_equipo then
            return enviar_error("Falta equipo_id")
        end
        escribir_en_bd("UPDATE equipos SET estado = 'Libre', hora_inicio = NULL WHERE id = " .. id_equipo, function()
            enviar_json(respuesta, 200, { message = "Equipo liberado" })
        end)

    -- ==== STATS PANEL ====
    elseif url == "/api/stats" and metodo == "GET" then
        leer_un_solo_dato("SELECT COUNT(*) as cuenta FROM equipos", function(res1)
            leer_un_solo_dato("SELECT COUNT(*) as cuenta FROM equipos WHERE estado = 'Libre'", function(res2)
                leer_un_solo_dato("SELECT COUNT(*) as cuenta FROM equipos WHERE estado = 'Ocupado'", function(res3)
                    leer_un_solo_dato("SELECT COUNT(*) as cuenta FROM equipos WHERE estado = 'Reservado'", function(res4)
                        leer_un_solo_dato("SELECT COUNT(*) as cuenta FROM usuarios WHERE rol = 'cliente'", function(res5)
                            leer_un_solo_dato("SELECT * FROM configuracion LIMIT 1", function(res6)
                                enviar_json(respuesta, 200, {
                                    equipos = {
                                        total = res1 and res1.cuenta or 0,
                                        libres = res2 and res2.cuenta or 0,
                                        ocupados = res3 and res3.cuenta or 0,
                                        reservados = res4 and res4.cuenta or 0
                                    },
                                    clientes = { total = res5 and res5.cuenta or 0 },
                                    configuracion = res6
                                })
                            end)
                        end)
                    end)
                end)
            end)
        end)

    -- ==== CONFIGURACION ====
    elseif url == "/api/configuracion" and metodo == "GET" then
        leer_un_solo_dato("SELECT * FROM configuracion LIMIT 1", function(config)
            enviar_json(respuesta, 200, { configuracion = config })
        end)
    elseif url == "/api/configuracion" and metodo == "PUT" then
        local bien, datos = pcall(json.parse, cuerpo_texto)
        escribir_en_bd("UPDATE configuracion SET nombre_local = '" .. datos.nombre_local .. "', precio_hora = " .. datos.precio_hora, function()
            enviar_json(respuesta, 200, { message = "Configuración guardada" })
        end)

    else
        enviar_json(respuesta, 404, { message = "Ruta no encontrada" })
    end
end

-- =====================================================================
-- 4. BUCLE PRINCIPAL DEL SERVIDOR
-- =====================================================================

local servidor = http.createServer(function(peticion, respuesta)
    pcall(function()
        -- CORS
        if peticion.method == "OPTIONS" then
            respuesta:writeHead(204, {
                ["Access-Control-Allow-Origin"] = "*",
                ["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS",
                ["Access-Control-Allow-Headers"] = "Content-Type, Authorization",
                ["Access-Control-Max-Age"] = "86400",
                ["Content-Length"] = "0"
            })
            respuesta:finish("")
            return
        end

        print("Petición: " .. peticion.method .. " " .. peticion.url)

        if peticion.url:sub(1, 4) == "/api" then
            local partes = {}
            peticion:on("data", function(pedazo) table.insert(partes, pedazo) end)
            peticion:on("end",  function()
                local cuerpo = table.concat(partes)
                procesar_peticion_api(peticion, respuesta, cuerpo)
            end)
        else
            local archivo_pedido = peticion.url:match("^([^%?]+)")
            if archivo_pedido == "/" then archivo_pedido = "/index.html" end
            if archivo_pedido:sub(1, 1) == "/" then archivo_pedido = archivo_pedido:sub(2) end
            enviar_archivo(respuesta, archivo_pedido)
        end
    end)
end)

servidor:listen(PUERTO)

print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
print("  Servidor CiberVicio encendido! ")
print("  Puerto: " .. PUERTO)
print("  MySQL conectado a: " .. db_config.database)
print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
