local Evento = require("Evento")
local HUD = {}
HUD.__index = HUD

function HUD:Nuevo()
    local o = setmetatable({}, HUD)
    o.mensaje_central = ""
    o.color_mensaje = {1, 1, 1}
    o.mostrar_mensaje = false
    
    o.mostrar_boss = false
    o.boss_hp = 0
    o.boss_max_hp = 100

    o.sala_limpia = false
    o.angulo_flecha = 0
    o.mostrar_flecha = false

    Evento.on("sala_limpia", function()
        o.mensaje_central = "¡SALA LIMPIADA! Avanza por la puerta"
        o.color_mensaje = {0, 1, 0}
        o.mostrar_mensaje = true
        o.sala_limpia = true
        o.mostrar_flecha = true
    end)
    Evento.on("derrota", function()
        o.mensaje_central = "GAME OVER - Presiona R para reiniciar"
        o.color_mensaje = {1, 0, 0}
        o.mostrar_mensaje = true
        o.mostrar_flecha = false
    end)
    Evento.on("victoria_juego", function()
        o.mensaje_central = "¡HAS VENCIDO A LA MUERTE! JUEGO COMPLETADO"
        o.color_mensaje = {1, 1, 0}
        o.mostrar_mensaje = true
        o.mostrar_flecha = false
    end)
    Evento.on("cambio_sala", function() 
        o.mostrar_mensaje = false; 
        o.mostrar_boss = false 
        o.sala_limpia = false
        o.mostrar_flecha = false
    end)
    Evento.on("reset_juego", function() 
        o.mostrar_mensaje = false; 
        o.mostrar_boss = false 
        o.sala_limpia = false
        o.mostrar_flecha = false
    end)
    Evento.on("boss_hp", function(hp, max) o.mostrar_boss = true; o.boss_hp = hp; o.boss_max_hp = max end)

    return o
end

function HUD:ActualizarAngulo(jugador, puerta_x, puerta_y, camara)
    if not self.mostrar_flecha or not jugador then return end
    
    -- Calculamos la diferencia entre el jugador y la puerta en el mundo
    local dx = puerta_x - jugador.x
    local dy = puerta_y - jugador.y
    
    -- Ángulo hacia la puerta
    self.angulo_flecha = math.atan2(dy, dx)
end

function HUD:Dibujar(jugador)
    love.graphics.setFont(FuenteChica)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Puntaje: " .. Juego.puntaje, 15, 15, love.graphics.getWidth(), "left")
    
    -- Vidas del Jugador
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.printf("Vidas: " .. (jugador and jugador.hp or 0) .. "/3", 15, 45, love.graphics.getWidth(), "left")
    
    if Juego.sala_actual >= 10 then love.graphics.setColor(1, 0, 0) end
    love.graphics.printf("Sala: " .. Juego.sala_actual .. "/10", 0, 15, love.graphics.getWidth() - 15, "right")
    love.graphics.setColor(1, 1, 1)

    -- Dibujar Flecha Guía Verde en el borde de la pantalla
    if self.mostrar_flecha and jugador then
        local screen_w = love.graphics.getWidth()
        local screen_h = love.graphics.getHeight()
        local cx, cy = screen_w / 2, screen_h / 2
        local radio = 150 -- Distancia desde el centro de la pantalla donde gira la flecha
        
        local fx = cx + math.cos(self.angulo_flecha) * radio
        local fy = cy + math.sin(self.angulo_flecha) * radio

        love.graphics.setColor(0, 1, 0) -- Verde brillante
        love.graphics.push()
        love.graphics.translate(fx, fy)
        love.graphics.rotate(self.angulo_flecha)
        
        -- Dibujamos un triángulo simple simulando una flecha
        love.graphics.polygon("fill", 15, 0, -10, 10, -10, -10)
        
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1)
    end

    -- Barra de Jefe centrada dinámicamente
    if self.mostrar_boss then
        local ancho_barra = 500
        local cx = love.graphics.getWidth() / 2
        local cy = love.graphics.getHeight()
        local hp_ratio = math.max(0, self.boss_hp / self.boss_max_hp)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", cx - ancho_barra/2, cy - 40, ancho_barra * hp_ratio, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", cx - ancho_barra/2, cy - 40, ancho_barra, 20)
        love.graphics.printf("LA PARCA", 0, cy - 70, love.graphics.getWidth(), "center")
    end

    if self.mostrar_mensaje then
        love.graphics.setFont(FuenteGrande)
        love.graphics.setColor(self.color_mensaje)
        love.graphics.printf(self.mensaje_central, 0, 150, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
    end
end

return HUD