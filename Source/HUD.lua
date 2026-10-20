local Evento = require("Evento")
local HUD = {}
HUD.__index = HUD

function HUD:Nuevo()
    local o = setmetatable({}, HUD)
    o.mensaje_central = ""
    o.color_mensaje = {1, 1, 1}
    o.mostrar_mensaje = false

    Evento.on("puntaje_actualizado", function() end) -- Solo avisa, el valor se lee de Juego.puntaje
    Evento.on("cambio_sala", function() o.mostrar_mensaje = false end)
    Evento.on("sala_limpia", function()
        o.mensaje_central = "¡SALA LIMPIADA! Avanza por la puerta"
        o.color_mensaje = {0, 1, 0}
        o.mostrar_mensaje = true
    end)
    Evento.on("derrota", function()
        o.mensaje_central = "GAME OVER - Presiona R para reiniciar"
        o.color_mensaje = {1, 0, 0}
        o.mostrar_mensaje = true
    end)
    Evento.on("reset_juego", function() o.mostrar_mensaje = false end)

    return o
end

function HUD:Dibujar()
    love.graphics.setFont(FuenteChica)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Puntaje: " .. Juego.puntaje, 15, 15, 770, "left")
    
    if Juego.sala_actual >= 10 then love.graphics.setColor(1, 0, 0) end
    love.graphics.printf("Sala: " .. Juego.sala_actual .. "/10", 0, 15, 785, "right")
    love.graphics.setColor(1, 1, 1)

    if self.mostrar_mensaje then
        love.graphics.setFont(FuenteGrande)
        love.graphics.setColor(self.color_mensaje)
        love.graphics.printf(self.mensaje_central, 0, 150, 800, "center")
        love.graphics.setColor(1, 1, 1)
    end
end

return HUD