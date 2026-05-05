local http = require("socket.http")
local ltn12 = require("ltn12")
local ffi = require("ffi")

local pinIngresado = ""
local mensaje = ""
local equipo_id = 1
local desbloqueado = false
local fontGrande
local fontChica

-- Para el autochequeo
local ultimoChequeo = 0
local intervaloChequeo = 5 -- segundos

local keyboardHook = nil
local keyboardHookCallback = nil

if ffi.os == "Windows" then
    ffi.cdef[[
        typedef void* HHOOK;
        typedef void* HINSTANCE;
        typedef unsigned long DWORD;
        typedef long LONG_PTR;
        typedef LONG_PTR LRESULT;
        typedef LRESULT (__stdcall *HOOKPROC)(int code, intptr_t wParam, intptr_t lParam);
        
        HHOOK SetWindowsHookExA(int idHook, HOOKPROC lpfn, HINSTANCE hMod, DWORD dwThreadId);
        bool UnhookWindowsHookEx(HHOOK hhk);
        LRESULT CallNextHookEx(HHOOK hhk, int nCode, intptr_t wParam, intptr_t lParam);
        short GetAsyncKeyState(int vKey);
        
        typedef struct {
            DWORD vkCode;
            DWORD scanCode;
            DWORD flags;
            DWORD time;
            intptr_t dwExtraInfo;
        } KBDLLHOOKSTRUCT;

        void* FindWindowA(const char* lpClassName, const char* lpWindowName);
        int PostMessageA(void* hWnd, unsigned int Msg, long wParam, long lParam);
    ]]
    
    local WH_KEYBOARD_LL = 13
    
    keyboardHookCallback = ffi.cast("HOOKPROC", function(nCode, wParam, lParam)
        if nCode >= 0 then
            local kbd = ffi.cast("KBDLLHOOKSTRUCT*", lParam)
            local vkCode = kbd.vkCode
            local flags = kbd.flags
            
            local altDown = bit.band(flags, 0x20) ~= 0
            
            -- Bloquear Win L/R (0x5B, 0x5C)
            if vkCode == 0x5B or vkCode == 0x5C then return 1 end
            -- Bloquear Alt+Tab (Alt + 0x09)
            if altDown and vkCode == 0x09 then return 1 end
            -- Bloquear Alt+Esc (Alt + 0x1B)
            if altDown and vkCode == 0x1B then return 1 end
            -- Bloquear Ctrl+Esc
            if vkCode == 0x1B and bit.band(ffi.C.GetAsyncKeyState(0x11), 0x8000) ~= 0 then return 1 end
        end
        return ffi.C.CallNextHookEx(keyboardHook, nCode, wParam, lParam)
    end)
end

function aplicarBloqueos()
    if ffi.os == "Windows" then
        local WH_KEYBOARD_LL = 13
        if not keyboardHook then
            keyboardHook = ffi.C.SetWindowsHookExA(WH_KEYBOARD_LL, keyboardHookCallback, nil, 0)
        end
        os.execute('REG ADD "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f >nul 2>&1')
        os.execute('REG ADD "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v DisableLockWorkstation /t REG_DWORD /d 1 /f >nul 2>&1')
        os.execute('REG ADD "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v DisableChangePassword /t REG_DWORD /d 1 /f >nul 2>&1')
        os.execute('REG ADD "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v DisableCAD /t REG_DWORD /d 1 /f >nul 2>&1')
    end
end

function quitarBloqueos()
    if ffi.os == "Windows" then
        if keyboardHook ~= nil then
            ffi.C.UnhookWindowsHookEx(keyboardHook)
            keyboardHook = nil
        end
        os.execute('REG ADD "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v DisableTaskMgr /t REG_DWORD /d 0 /f >nul 2>&1')
        os.execute('REG ADD "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v DisableLockWorkstation /t REG_DWORD /d 0 /f >nul 2>&1')
        os.execute('REG ADD "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v DisableChangePassword /t REG_DWORD /d 0 /f >nul 2>&1')
        os.execute('REG ADD "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v DisableCAD /t REG_DWORD /d 0 /f >nul 2>&1')
    end
end

function love.load()
    -- Intentar cargar equipo_id desde archivo local
    local f = io.open("equipo_id.txt", "r")
    if f then
        local info = f:read("*all")
        equipo_id = tonumber(info:match("%d+")) or 1
        f:close()
    end

    love.keyboard.setKeyRepeat(true)
    fontGrande = love.graphics.newFont(40)
    fontChica = love.graphics.newFont(20)
    love.graphics.setFont(fontGrande)

    aplicarBloqueos()
end

local WM_CLOSE = 0x0010

function love.update(dt)
    if not desbloqueado then
        if ffi.os == "Windows" then
            -- Cerrar TaskManager si se abre
            local hwnd1 = ffi.C.FindWindowA("TaskManagerWindow", nil)
            if hwnd1 ~= nil then ffi.C.PostMessageA(hwnd1, WM_CLOSE, 0, 0) end
            local hwnd2 = ffi.C.FindWindowA(nil, "Administrador de tareas")
            if hwnd2 ~= nil then ffi.C.PostMessageA(hwnd2, WM_CLOSE, 0, 0) end
        end
    else
        -- Autochequeo: si estamos desbloqueados, ver si la sesion terminó en el servidor
        ultimoChequeo = ultimoChequeo + dt
        if ultimoChequeo >= intervaloChequeo then
            ultimoChequeo = 0
            chequearEstadoServidor()
        end
    end
end

function chequearEstadoServidor()
    local respbody = {}
    local res, code = http.request{
        url = "http://lucicasa.es:3000/api/equipos/" .. equipo_id,
        method = "GET",
        sink = ltn12.sink.table(respbody)
    }

    if code == 200 then
        local respStr = table.concat(respbody)
        local estado = respStr:match('"estado":%s*"([^"]+)"')
        if estado == "Libre" then
            -- ¡La sesión ha terminado! Volver a bloquear
            desbloqueado = false
            pinIngresado = ""
            mensaje = "Sesión finalizada remotamente. PC bloqueado."
            love.window.restore()
            love.window.maximize()
            aplicarBloqueos()
        end
    end
end

function love.textinput(texto)
    if not desbloqueado and #pinIngresado < 6 then
        if texto:match("%d") then
            pinIngresado = pinIngresado .. texto
        end
    end
end

function love.keypressed(key)
    if desbloqueado then return end
    
    if key == "backspace" then
        pinIngresado = string.sub(pinIngresado, 1, -2)
    elseif key == "return" then
        validarPin()
    end
end

function validarPin()
    if pinIngresado == "" then
        mensaje = "Teclea algo primero."
        return
    end

    mensaje = "Consultando base de datos..."
    
    local body = '{"pin":"' .. pinIngresado .. '"}'
    local respbody = {}
    local res, code = http.request{
        url = "http://lucicasa.es:3000/api/reservas/validar",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#body)
        },
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(respbody)
    }

    if code == 200 then
        desbloqueado = true
        mensaje = "PIN Aceptado. Sesión iniciada."
        
        local respStr = table.concat(respbody)
        local id_extraido = respStr:match('"equipo_id":%s*(%d+)')
        if id_extraido then
            equipo_id = tonumber(id_extraido)
        end

        quitarBloqueos()
        love.window.minimize()
    elseif code == 400 or code == 401 then
        mensaje = "PIN incorrecto o sistema anti-hackeos activado."
        pinIngresado = ""
    else
        mensaje = "La API del servidor no responde. Imposible entrar."
    end
end

function love.draw()
    if desbloqueado then
        love.graphics.clear(0, 0.4, 0)
        love.graphics.setFont(fontGrande)
        love.graphics.print("SESIÓN ACTIVA", 50, 50)
        love.graphics.setFont(fontChica)
        love.graphics.print("Este PC está liberado. Finaliza la sesión desde el móvil para bloquear.", 50, 110)
        return
    end

    local rw, rh = love.graphics.getDimensions()
    love.graphics.clear(0.08, 0.08, 0.12)
    
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.setFont(fontGrande)
    love.graphics.printf("PC BLOQUEADO (Equipo #" .. equipo_id .. ")", 0, rh/2 - 120, rw, "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontChica)
    love.graphics.printf("Ingresa tu PIN secreto para liberar esta tostadora:", 0, rh/2 - 20, rw, "center")
    
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontGrande)
    love.graphics.printf("> " .. pinIngresado .. " <", 0, rh/2 + 20, rw, "center")

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(fontChica)
    love.graphics.printf(mensaje, 0, rh/2 + 100, rw, "center")
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.printf("[ALT+F4 y salir de aqui esta rigurosamente bloqueado]", 0, rh - 50, rw, "center")
end

function love.quit()
    if not desbloqueado then
        mensaje = "¡Eh listillo! Ni lo intentes (Alt+F4 bloqueado)."
        return true
    end

    -- Notificar al backend que el equipo queda libre
    local body = '{"equipo_id":' .. equipo_id .. '}'
    http.request{
        url = "http://lucicasa.es:3000/api/reservas/liberar",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#body)
        },
        source = ltn12.source.string(body)
    }

    quitarBloqueos()
    return false
end
